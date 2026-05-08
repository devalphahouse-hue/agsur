import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthChangeEvent, AuthException, AuthState, UserAttributes;

import '/auth/supabase_auth/auth_util.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'reset_password_model.dart';

export 'reset_password_model.dart';

enum _ResetMode { request, sent, recovery, recoverySuccess }

class ResetPasswordWidget extends StatefulWidget {
  const ResetPasswordWidget({super.key});

  static String routeName = 'reset_password';
  static String routePath = '/resetPassword';

  @override
  State<ResetPasswordWidget> createState() => _ResetPasswordWidgetState();
}

class _ResetPasswordWidgetState extends State<ResetPasswordWidget> {
  late ResetPasswordModel _model;
  final _formKey = GlobalKey<FormState>();
  final _recoveryFormKey = GlobalKey<FormState>();
  final _newPwdCtrl = TextEditingController();
  final _confirmPwdCtrl = TextEditingController();
  final _newPwdFocus = FocusNode();
  final _confirmPwdFocus = FocusNode();
  bool _busy = false;
  String? _error;
  _ResetMode _mode = _ResetMode.request;
  bool _showNew = false;
  bool _showConfirm = false;
  StreamSubscription<AuthState>? _authSub;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ResetPasswordModel());
    _model.tFEmailTextController ??= TextEditingController();
    _model.tFEmailFocusNode ??= FocusNode();

    // Web: o link do email vem com #access_token=...&type=recovery. Mesmo que
    // o supabase_flutter já tenha consumido o hash antes deste widget montar
    // (e o evento passwordRecovery do stream já tenha passado), o fragmento
    // ainda costuma estar na URL — usamos como fallback robusto.
    final fragment = Uri.base.fragment;
    if (fragment.contains('type=recovery')) {
      _mode = _ResetMode.recovery;
    }
    _authSub = SupaFlow.client.auth.onAuthStateChange.listen((data) {
      if (!mounted) return;
      if (data.event == AuthChangeEvent.passwordRecovery) {
        setState(() => _mode = _ResetMode.recovery);
      }
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _newPwdCtrl.dispose();
    _confirmPwdCtrl.dispose();
    _newPwdFocus.dispose();
    _confirmPwdFocus.dispose();
    _model.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    if (_formKey.currentState?.validate() != true) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await authManager.resetPassword(
        email: _model.tFEmailTextController!.text.trim(),
        context: context,
        redirectTo:
            'https://painel-agsur.vercel.app/resetPassword',
      );
      if (!mounted) return;
      setState(() {
        _busy = false;
        _mode = _ResetMode.sent;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Não foi possível enviar o e-mail. Tente novamente.';
      });
    }
  }

  Future<void> _submitNewPassword() async {
    if (_busy) return;
    if (_recoveryFormKey.currentState?.validate() != true) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await SupaFlow.client.auth.updateUser(
        UserAttributes(password: _newPwdCtrl.text),
      );
      if (!mounted) return;
      // Encerra a sessão de recovery pra forçar login com a senha nova.
      await SupaFlow.client.auth.signOut();
      if (!mounted) return;
      setState(() {
        _busy = false;
        _mode = _ResetMode.recoverySuccess;
      });
    } on AuthException catch (e) {
      if (!mounted) return;
      final msg = e.message.toLowerCase();
      setState(() {
        _busy = false;
        _error = msg.contains('same')
            ? 'A nova senha não pode ser igual à atual.'
            : msg.contains('weak') || msg.contains('short')
                ? 'Senha fraca — use ao menos 8 caracteres com letras e números.'
                : 'Não foi possível atualizar a senha. Tente novamente.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Ocorreu um erro, tente novamente.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context).size;
    final isWide = mq.width >= 980;
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF1F1F1F),
        body: Stack(
          children: [
            const _AuroraBackground(),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: ConstrainedBox(
                      constraints:
                          BoxConstraints(maxWidth: isWide ? 1080 : 480),
                      child: isWide
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Expanded(child: _BrandPanel()),
                                const SizedBox(width: 48),
                                Expanded(child: _buildPanel()),
                              ],
                            )
                          : Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const _BrandPanel(compact: true),
                                const SizedBox(height: 24),
                                _buildPanel(),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  '© ${DateTime.now().year}  ·  Agsur · Aerotg · Painel administrativo',
                  style: GoogleFonts.roboto(
                    fontSize: 11,
                    color: const Color(0x77FFFFFF),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPanel() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x22FFFFFF), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.55),
            blurRadius: 36,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 320),
        child: switch (_mode) {
          _ResetMode.request => KeyedSubtree(
              key: const ValueKey('request'), child: _buildForm()),
          _ResetMode.sent => KeyedSubtree(
              key: const ValueKey('sent'), child: _buildSuccess()),
          _ResetMode.recovery => KeyedSubtree(
              key: const ValueKey('recovery'), child: _buildRecovery()),
          _ResetMode.recoverySuccess => KeyedSubtree(
              key: const ValueKey('recoverySuccess'),
              child: _buildRecoverySuccess()),
        },
      ),
    );
  }

  Widget _buildRecovery() {
    return Form(
      key: _recoveryFormKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0x22C2D51C),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0x55C2D51C)),
              ),
              child: const Icon(
                Icons.lock_reset_rounded,
                color: Color(0xFFC2D51C),
                size: 28,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Defina sua nova senha',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Escolha uma senha forte com no mínimo 8 caracteres.',
            textAlign: TextAlign.center,
            style: GoogleFonts.roboto(
              fontSize: 13,
              color: const Color(0x99FFFFFF),
            ),
          ),
          const SizedBox(height: 22),
          _AppFormField(
            controller: _newPwdCtrl,
            focusNode: _newPwdFocus,
            label: 'Nova senha',
            hint: 'Mínimo 8 caracteres',
            icon: Icons.lock_outline_rounded,
            obscure: !_showNew,
            enabled: !_busy,
            autofillHints: const [AutofillHints.newPassword],
            trailing: _PwdEye(
              visible: _showNew,
              onToggle: () => setState(() => _showNew = !_showNew),
            ),
            validator: (v) {
              final value = v ?? '';
              if (value.isEmpty) return 'Informe a nova senha';
              if (value.length < 8) return 'Mínimo 8 caracteres';
              return null;
            },
            onSubmit: (_) => _confirmPwdFocus.requestFocus(),
          ).animate().fadeIn(delay: 80.ms).moveY(begin: 6, end: 0),
          const SizedBox(height: 14),
          _AppFormField(
            controller: _confirmPwdCtrl,
            focusNode: _confirmPwdFocus,
            label: 'Confirmar senha',
            hint: 'Repita a senha',
            icon: Icons.lock_outline_rounded,
            obscure: !_showConfirm,
            enabled: !_busy,
            autofillHints: const [AutofillHints.newPassword],
            trailing: _PwdEye(
              visible: _showConfirm,
              onToggle: () => setState(() => _showConfirm = !_showConfirm),
            ),
            validator: (v) {
              final value = v ?? '';
              if (value.isEmpty) return 'Confirme a nova senha';
              if (value != _newPwdCtrl.text) return 'As senhas não conferem';
              return null;
            },
            onSubmit: (_) => _submitNewPassword(),
          ).animate().fadeIn(delay: 160.ms).moveY(begin: 6, end: 0),
          if (_error != null) ...[
            const SizedBox(height: 12),
            _ErrorBanner(message: _error!),
          ],
          const SizedBox(height: 18),
          _AppPrimaryButton(
            label: _busy ? 'Salvando...' : 'Salvar nova senha',
            busy: _busy,
            icon: Icons.check_rounded,
            onPressed: _submitNewPassword,
          ).animate().fadeIn(delay: 240.ms).moveY(begin: 6, end: 0),
        ],
      ),
    );
  }

  Widget _buildRecoverySuccess() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0x33249689),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0x884FBFA9)),
            ),
            child: const Icon(
              Icons.check_circle_outline_rounded,
              color: Color(0xFF4FBFA9),
              size: 30,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Senha alterada!',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Sua senha foi atualizada com sucesso. Agora é só fazer login com ela.',
          textAlign: TextAlign.center,
          style: GoogleFonts.roboto(
            fontSize: 13,
            color: const Color(0xCCFFFFFF),
            height: 1.45,
          ),
        ),
        const SizedBox(height: 22),
        _AppPrimaryButton(
          label: 'Ir para o login',
          icon: Icons.arrow_forward_rounded,
          onPressed: () => context.go('/login'),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _BackBtn(onTap: () => context.safePop()),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recuperar acesso',
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Enviaremos um link para redefinir sua senha.',
                      style: GoogleFonts.roboto(
                        fontSize: 13,
                        color: const Color(0x99FFFFFF),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _AppFormField(
            controller: _model.tFEmailTextController!,
            focusNode: _model.tFEmailFocusNode!,
            label: 'E-mail',
            hint: 'voce@agsur.com.br',
            icon: Icons.alternate_email_rounded,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            enabled: !_busy,
            validator: (v) {
              final value = (v ?? '').trim();
              if (value.isEmpty) return 'Informe o e-mail';
              if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)) {
                return 'E-mail inválido';
              }
              return null;
            },
            onSubmit: (_) => _submit(),
          ).animate().fadeIn(delay: 120.ms).moveY(begin: 6, end: 0),
          if (_error != null) ...[
            const SizedBox(height: 12),
            _ErrorBanner(message: _error!),
          ],
          const SizedBox(height: 16),
          _AppPrimaryButton(
            label: _busy ? 'Enviando...' : 'Enviar link',
            busy: _busy,
            icon: Icons.mark_email_read_outlined,
            onPressed: _submit,
          ).animate().fadeIn(delay: 200.ms).moveY(begin: 6, end: 0),
          const SizedBox(height: 14),
          Center(
            child: Text(
              'Verifique também a pasta de spam após receber o e-mail.',
              textAlign: TextAlign.center,
              style: GoogleFonts.roboto(
                fontSize: 11.5,
                color: const Color(0x99FFFFFF),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccess() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0x33249689),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0x884FBFA9)),
            ),
            child: const Icon(
              Icons.mark_email_read_outlined,
              color: Color(0xFF4FBFA9),
              size: 30,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'E-mail enviado!',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Acabamos de enviar um link de redefinição para ${_model.tFEmailTextController!.text.trim()}. Caso não encontre, confira sua caixa de spam.',
          textAlign: TextAlign.center,
          style: GoogleFonts.roboto(
            fontSize: 13,
            color: const Color(0xCCFFFFFF),
            height: 1.45,
          ),
        ),
        const SizedBox(height: 22),
        _AppPrimaryButton(
          label: 'Voltar para o login',
          icon: Icons.arrow_back_rounded,
          onPressed: () => context.safePop(),
        ),
      ],
    );
  }
}

// ─────────────────── BACK BUTTON ───────────────────
class _BackBtn extends StatefulWidget {
  const _BackBtn({required this.onTap});
  final VoidCallback onTap;

  @override
  State<_BackBtn> createState() => _BackBtnState();
}

class _BackBtnState extends State<_BackBtn> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: _hover
                ? const Color(0x22C2D51C)
                : Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              color: _hover
                  ? const Color(0x55C2D51C)
                  : Colors.white.withValues(alpha: 0.06),
            ),
          ),
          child: Icon(
            Icons.arrow_back_rounded,
            size: 17,
            color: _hover ? const Color(0xFFC2D51C) : Colors.white,
          ),
        ),
      ),
    );
  }
}

// ─────────────────── BRAND PANEL ───────────────────
class _BrandPanel extends StatelessWidget {
  const _BrandPanel({this.compact = false});
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment:
          compact ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            color: const Color(0xFF1B1B1B),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0x33C2D51C)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFC2D51C).withValues(alpha: 0.15),
                blurRadius: 22,
                spreadRadius: -4,
              ),
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: Image.asset(
            'assets/images/Logo_AEROTG_NEGATIVO_V.png',
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 22),
        Text(
          'Recuperação de senha',
          textAlign: compact ? TextAlign.center : TextAlign.start,
          style: GoogleFonts.inter(
            fontSize: compact ? 22 : 28,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            height: 1.15,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Sem stress: enviamos um link seguro para o seu e-mail e você redefine sua senha em segundos.',
          textAlign: compact ? TextAlign.center : TextAlign.start,
          style: GoogleFonts.roboto(
            fontSize: 13.5,
            color: const Color(0xAAFFFFFF),
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

// ─────────────────── AURORA BG ───────────────────
class _AuroraBackground extends StatelessWidget {
  const _AuroraBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1F1F1F), Color(0xFF161616)],
              ),
            ),
          ),
        ),
        Positioned(
          top: -120,
          left: -120,
          child: Container(
            width: 360,
            height: 360,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFFC2D51C).withValues(alpha: 0.22),
                  const Color(0xFFC2D51C).withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -100,
          right: -80,
          child: Container(
            width: 320,
            height: 320,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF249689).withValues(alpha: 0.18),
                  const Color(0xFF249689).withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────── FORM FIELD ───────────────────
class _AppFormField extends StatefulWidget {
  const _AppFormField({
    required this.controller,
    required this.focusNode,
    required this.label,
    required this.icon,
    this.hint,
    this.obscure = false,
    this.keyboardType,
    this.autofillHints,
    this.enabled = true,
    this.trailing,
    this.validator,
    this.onSubmit,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final String? hint;
  final IconData icon;
  final bool obscure;
  final TextInputType? keyboardType;
  final Iterable<String>? autofillHints;
  final bool enabled;
  final Widget? trailing;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onSubmit;

  @override
  State<_AppFormField> createState() => _AppFormFieldState();
}

class _AppFormFieldState extends State<_AppFormField> {
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocus);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocus);
    super.dispose();
  }

  void _onFocus() {
    if (mounted) setState(() => _focused = widget.focusNode.hasFocus);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6, left: 4),
          child: Text(
            widget.label,
            style: GoogleFonts.inter(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: const Color(0xCCFFFFFF),
              letterSpacing: 0.3,
            ),
          ),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: const Color(0x14FFFFFF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _focused
                  ? const Color(0xFFC2D51C).withValues(alpha: 0.65)
                  : const Color(0x22FFFFFF),
              width: 1.5,
            ),
            boxShadow: _focused
                ? [
                    BoxShadow(
                      color: const Color(0xFFC2D51C).withValues(alpha: 0.18),
                      blurRadius: 14,
                      spreadRadius: -2,
                    ),
                  ]
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Icon(widget.icon, size: 18, color: const Color(0xCCFFFFFF)),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: widget.controller,
                    focusNode: widget.focusNode,
                    obscureText: widget.obscure,
                    keyboardType: widget.keyboardType,
                    autofillHints: widget.autofillHints,
                    enabled: widget.enabled,
                    onFieldSubmitted: widget.onSubmit,
                    style: GoogleFonts.roboto(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: widget.hint,
                      hintStyle: GoogleFonts.roboto(
                        color: const Color(0x55FFFFFF),
                        fontSize: 14,
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 14),
                    ),
                    validator: widget.validator,
                  ),
                ),
                if (widget.trailing != null) widget.trailing!,
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────── PRIMARY BUTTON ───────────────────
class _AppPrimaryButton extends StatefulWidget {
  const _AppPrimaryButton({
    required this.label,
    required this.onPressed,
    this.busy = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool busy;
  final IconData? icon;

  @override
  State<_AppPrimaryButton> createState() => _AppPrimaryButtonState();
}

class _AppPrimaryButtonState extends State<_AppPrimaryButton> {
  bool _hover = false;
  bool _press = false;

  @override
  Widget build(BuildContext context) {
    final disabled = widget.busy || widget.onPressed == null;
    return MouseRegion(
      cursor: disabled ? SystemMouseCursors.basic : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() {
        _hover = false;
        _press = false;
      }),
      child: GestureDetector(
        onTapDown: (_) => disabled ? null : setState(() => _press = true),
        onTapCancel: () => setState(() => _press = false),
        onTapUp: (_) => setState(() => _press = false),
        onTap: disabled ? null : widget.onPressed,
        child: AnimatedScale(
          scale: _press ? 0.98 : 1,
          duration: const Duration(milliseconds: 120),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: disabled
                    ? const [Color(0xFF6C7A0E), Color(0xFF4F5908)]
                    : _hover
                        ? const [Color(0xFFD3E823), Color(0xFFBCCD1A)]
                        : const [Color(0xFFC2D51C), Color(0xFFAEC117)],
              ),
              boxShadow: disabled
                  ? null
                  : [
                      BoxShadow(
                        color: const Color(0xFFC2D51C)
                            .withValues(alpha: _hover ? 0.5 : 0.3),
                        blurRadius: _hover ? 24 : 16,
                        spreadRadius: -2,
                        offset: const Offset(0, 6),
                      ),
                    ],
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.busy)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.8,
                      color: Color(0xFF313131),
                    ),
                  )
                else if (widget.icon != null)
                  Icon(widget.icon, size: 16, color: const Color(0xFF313131)),
                if (widget.busy || widget.icon != null)
                  const SizedBox(width: 8),
                Text(
                  widget.label,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF313131),
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────── ERROR BANNER ───────────────────
class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0x33FF5963),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0x88FF5963)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 16, color: Color(0xFFFF7B82)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.roboto(
                fontSize: 12.5,
                color: const Color(0xFFFF7B82),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────── PASSWORD EYE ───────────────────
class _PwdEye extends StatelessWidget {
  const _PwdEye({required this.visible, required this.onToggle});
  final bool visible;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onToggle,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Icon(
            visible
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            size: 18,
            color: const Color(0xCCFFFFFF),
          ),
        ),
      ),
    );
  }
}
