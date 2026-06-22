import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '/backend/supabase/supabase.dart';
import '/core_ui/core_ui.dart';

/// Fluxo de MFA (TOTP) do painel — cadastro e step-up no login.
///
/// Lockout-safe: o step-up só é exigido de quem JÁ tem um fator verificado
/// (`nextLevel == aal2`). Enquanto ninguém cadastra, o login não muda. A
/// obrigatoriedade dura (deslogar Admin Master sem MFA) continua atrás da flag
/// `--dart-define=ENFORCE_MFA_ADMIN_MASTER=true`; este fluxo é o que permite
/// chegar a `aal2` de fato.

GoTrueMFAApi get _mfa => SupaFlow.client.auth.mfa;

/// Abre o diálogo de cadastro/gestão de MFA (TOTP). Use a partir do perfil.
Future<void> showMfaSetupDialog(BuildContext context) {
  return showDialog(
    context: context,
    barrierColor: const Color(0x9A000000),
    builder: (ctx) => Dialog(
      elevation: 0,
      insetPadding: EdgeInsets.zero,
      backgroundColor: Colors.transparent,
      child: const _MfaSetupDialog(),
    ),
  );
}

/// Chamado no login após confirmar o perfil. Se o usuário tem um fator TOTP
/// verificado e a sessão está em aal1, exige o código para subir a aal2.
/// Retorna `true` se está OK para prosseguir (aal2 atingido OU sem fator),
/// `false` se o usuário cancelou/falhou (o chamador deve deslogar).
Future<bool> stepUpMfaIfNeeded(BuildContext context) async {
  AuthMFAGetAuthenticatorAssuranceLevelResponse aal;
  try {
    aal = await _mfa.getAuthenticatorAssuranceLevel();
  } catch (_) {
    // Não foi possível avaliar — não bloqueia o login (lockout-safe).
    return true;
  }
  final needsStepUp = aal.currentLevel == AuthenticatorAssuranceLevels.aal1 &&
      aal.nextLevel == AuthenticatorAssuranceLevels.aal2;
  if (!needsStepUp) return true;

  Factor? totp;
  try {
    final factors = await _mfa.listFactors();
    totp = factors.totp.firstOrNull;
  } catch (_) {}
  if (totp == null) return true; // nada a desafiar

  if (!context.mounted) return false;
  final ok = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    barrierColor: const Color(0x9A000000),
    builder: (ctx) => Dialog(
      elevation: 0,
      insetPadding: EdgeInsets.zero,
      backgroundColor: Colors.transparent,
      child: _MfaChallengeDialog(factorId: totp!.id),
    ),
  );
  return ok == true;
}

// ───────────────────────── cadastro ─────────────────────────

class _MfaSetupDialog extends StatefulWidget {
  const _MfaSetupDialog();

  @override
  State<_MfaSetupDialog> createState() => _MfaSetupDialogState();
}

class _MfaSetupDialogState extends State<_MfaSetupDialog> {
  bool _loading = true;
  bool _busy = false;
  String? _error;

  // Estado: já tem fator verificado?
  Factor? _verified;

  // Enrollment em andamento.
  String? _factorId;
  String? _secret;
  String? _uri;
  final _codeCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final factors = await _mfa.listFactors();
      _verified = factors.totp
          .where((f) => f.status == FactorStatus.verified)
          .firstOrNull;
    } catch (e) {
      _error = 'Não foi possível carregar o status do MFA.';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _startEnroll() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      // Limpa fatores não-verificados pendentes (evita acúmulo em re-tentativas).
      final existing = await _mfa.listFactors();
      for (final f in existing.totp
          .where((f) => f.status == FactorStatus.unverified)) {
        try {
          await _mfa.unenroll(f.id);
        } catch (_) {}
      }
      final res = await _mfa.enroll(factorType: FactorType.totp);
      _factorId = res.id;
      _secret = res.totp.secret;
      _uri = res.totp.uri;
    } catch (e) {
      _error = 'Falha ao gerar a chave de MFA. Tente novamente.';
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _verify() async {
    final code = _codeCtrl.text.trim();
    final id = _factorId;
    if (id == null) return;
    if (code.length != 6) {
      setState(() => _error = 'Digite o código de 6 dígitos do app autenticador.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final ch = await _mfa.challenge(factorId: id);
      await _mfa.verify(factorId: id, challengeId: ch.id, code: code);
      if (!mounted) return;
      _factorId = null;
      _secret = null;
      _uri = null;
      _codeCtrl.clear();
      await _refresh();
    } catch (e) {
      setState(() => _error = 'Código inválido ou expirado. Tente de novo.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _remove() async {
    final id = _verified?.id;
    if (id == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _mfa.unenroll(id);
      await _refresh();
    } catch (e) {
      setState(() => _error = 'Não foi possível remover o MFA.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppModal(
      icon: Icons.shield_outlined,
      title: 'Autenticação em dois fatores (MFA)',
      description:
          'Use um app autenticador (Google Authenticator, Authy, 1Password) para proteger o acesso.',
      maxWidth: 520,
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          AppSecondaryButton(
            label: 'Fechar',
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ],
      ),
      child: _loading
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.4, color: Color(0xFFC2D51C)),
                ),
              ),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_verified != null)
                  _verifiedView()
                else if (_factorId == null)
                  _startView()
                else
                  _enrollView(),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!,
                      style: const TextStyle(
                          color: Color(0xFFFF7B82), fontSize: 12.5)),
                ],
              ],
            ),
    );
  }

  Widget _verifiedView() => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: const [
              Icon(Icons.verified_user_rounded,
                  color: Color(0xFFC2D51C), size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text('MFA ativo nesta conta.',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AppSecondaryButton(
            label: _busy ? 'Removendo…' : 'Remover MFA',
            icon: Icons.delete_outline_rounded,
            onPressed: _busy ? null : _remove,
          ),
        ],
      );

  Widget _startView() => AppPrimaryButton(
        label: _busy ? 'Gerando…' : 'Configurar MFA',
        icon: Icons.qr_code_2_rounded,
        busy: _busy,
        onPressed: _busy ? null : _startEnroll,
      );

  Widget _enrollView() => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '1) Adicione esta chave no seu app autenticador (entrada manual):',
            style: TextStyle(color: Color(0xCCFFFFFF), fontSize: 13),
          ),
          const SizedBox(height: 8),
          _CopyBox(label: 'Chave (secret)', value: _secret ?? ''),
          if ((_uri ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            _CopyBox(label: 'URI otpauth', value: _uri!),
          ],
          const SizedBox(height: 16),
          const Text(
            '2) Digite o código de 6 dígitos gerado pelo app:',
            style: TextStyle(color: Color(0xCCFFFFFF), fontSize: 13),
          ),
          const SizedBox(height: 8),
          AppFormField(
            controller: _codeCtrl,
            label: 'Código',
            placeholder: '000000',
            icon: Icons.password_rounded,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
          ),
          const SizedBox(height: 16),
          AppPrimaryButton(
            label: _busy ? 'Verificando…' : 'Verificar e ativar',
            icon: Icons.check_rounded,
            busy: _busy,
            onPressed: _busy ? null : _verify,
          ),
        ],
      );
}

// ───────────────────────── step-up (login) ─────────────────────────

class _MfaChallengeDialog extends StatefulWidget {
  const _MfaChallengeDialog({required this.factorId});
  final String factorId;

  @override
  State<_MfaChallengeDialog> createState() => _MfaChallengeDialogState();
}

class _MfaChallengeDialogState extends State<_MfaChallengeDialog> {
  final _codeCtrl = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final code = _codeCtrl.text.trim();
    if (code.length != 6) {
      setState(() => _error = 'Digite o código de 6 dígitos.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final ch = await _mfa.challenge(factorId: widget.factorId);
      await _mfa.verify(
          factorId: widget.factorId, challengeId: ch.id, code: code);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      setState(() {
        _busy = false;
        _error = 'Código inválido ou expirado.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppModal(
      icon: Icons.lock_clock_outlined,
      title: 'Verificação em dois fatores',
      description: 'Digite o código de 6 dígitos do seu app autenticador.',
      maxWidth: 440,
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          AppSecondaryButton(
            label: 'Cancelar',
            onPressed: _busy ? null : () => Navigator.of(context).pop(false),
          ),
          const SizedBox(width: 10),
          AppPrimaryButton(
            label: 'Confirmar',
            icon: Icons.check_rounded,
            busy: _busy,
            onPressed: _busy ? null : _verify,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppFormField(
            controller: _codeCtrl,
            label: 'Código',
            placeholder: '000000',
            icon: Icons.password_rounded,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!,
                style:
                    const TextStyle(color: Color(0xFFFF7B82), fontSize: 12.5)),
          ],
        ],
      ),
    );
  }
}

// ───────────────────────── util ─────────────────────────

class _CopyBox extends StatelessWidget {
  const _CopyBox({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0x14FFFFFF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0x33FFFFFF)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: Color(0x99FFFFFF), fontSize: 10.5)),
                const SizedBox(height: 2),
                SelectableText(
                  value,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy_rounded,
                size: 16, color: Color(0xFFC2D51C)),
            tooltip: 'Copiar',
            onPressed: () =>
                Clipboard.setData(ClipboardData(text: value)),
          ),
        ],
      ),
    );
  }
}
