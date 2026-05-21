import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '/auth/supabase_auth/auth_util.dart';
import '/backend/supabase/supabase.dart';
import '/core_ui/core_ui.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import '/security/jwt_utils.dart';
import 'login_model.dart';

export 'login_model.dart';

class LoginWidget extends StatefulWidget {
  const LoginWidget({super.key});

  static String routeName = 'Login';
  static String routePath = '/login';

  @override
  State<LoginWidget> createState() => _LoginWidgetState();
}

/// MFA obrigatório para Admin Master. Default OFF até todos os Admin Masters
/// cadastrarem TOTP no Studio (Auth → Multi-Factor). Quando estiverem
/// cadastrados, build com:
///   --dart-define=ENFORCE_MFA_ADMIN_MASTER=true
///
/// Em paralelo, ativar o hook server-side `custom_access_token_hook` no Studio
/// (Auth → Hooks). Aí mesmo sem essa flag, o JWT já volta rejeitado.
const bool _kEnforceMfaAdminMaster =
    bool.fromEnvironment('ENFORCE_MFA_ADMIN_MASTER', defaultValue: false);

class _LoginWidgetState extends State<LoginWidget> {
  late LoginModel _model;
  final _formKey = GlobalKey<FormState>();
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => LoginModel());
    _model.tFEmailTextController ??= TextEditingController();
    _model.tFEmailFocusNode ??= FocusNode();
    _model.tFSenhaTextController ??= TextEditingController();
    _model.tFSenhaFocusNode ??= FocusNode();
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  // Perfis exclusivos do painel administrativo. Mantém em sincronia
  // com a RPC check_app_access no Supabase.
  static const _panelAllowed = {'Admin Master', 'Admin', 'Vendedor', 'Admin2'};

  Future<void> _submit() async {
    if (_submitting) return;
    if (_formKey.currentState?.validate() != true) return;

    setState(() {
      _submitting = true;
      _error = null;
    });

    final email = _model.tFEmailTextController!.text.trim();
    final password = _model.tFSenhaTextController!.text;

    try {
      // Pré-checagem via RPC SECURITY DEFINER — antes do signIn,
      // evita criar sessão para perfis bloqueados (Cliente/Piloto/Oficina).
      // Falha-fechado: erro de rede/RPC trata como bloqueio.
      String? preCheckProfile;
      try {
        final result = await SupaFlow.client.rpc(
          'check_app_access',
          params: {'p_email': email},
        );
        preCheckProfile = result is String ? result : null;
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _submitting = false;
          _error = 'Não foi possível validar o acesso. Tente novamente.';
        });
        return;
      }

      if (preCheckProfile == null) {
        // Email não cadastrado: mensagem genérica para evitar enumeração.
        if (!mounted) return;
        setState(() {
          _submitting = false;
          _error = 'E-mail ou senha incorretos.';
        });
        return;
      }

      if (!_panelAllowed.contains(preCheckProfile)) {
        if (!mounted) return;
        setState(() {
          _submitting = false;
          _error =
              'Esta conta é exclusiva do aplicativo Agsur. Use o app para entrar.';
        });
        return;
      }

      // Perfil permitido — agora faz o login.
      GoRouter.of(context).prepareAuthEvent();
      final user =
          await authManager.signInWithEmail(context, email, password);
      if (!mounted) return;
      if (user == null) {
        setState(() {
          _submitting = false;
          _error = 'E-mail ou senha incorretos.';
        });
        return;
      }

      // Defesa em camadas: confirma o perfil também via sessão autenticada
      // (cobre o caso de a RPC ter retornado dado obsoleto).
      _model.userResponse = await UsersTable().queryRows(
        queryFn: (q) => q.eqOrNull('id', currentUserUid),
      );
      if (!mounted) return;

      final profile = _model.userResponse?.firstOrNull?.profileType;
      if (profile == null || !_panelAllowed.contains(profile)) {
        await authManager.signOut();
        GoRouter.of(context).clearRedirectLocation();
        if (!mounted) return;
        setState(() {
          _submitting = false;
          _error =
              'Esta conta é exclusiva do aplicativo Agsur. Use o app para entrar.';
        });
        return;
      }

      // Defesa em camadas: Admin Master sem MFA é deslogado.
      // Gate desativado por padrão (lockout-safe). Ativar com
      // --dart-define=ENFORCE_MFA_ADMIN_MASTER=true depois de garantir que
      // todos os Admin Masters cadastraram TOTP no Studio.
      if (_kEnforceMfaAdminMaster && profile == 'Admin Master') {
        final token = SupaFlow.client.auth.currentSession?.accessToken;
        final aal = token != null ? decodeJwtAal(token) : 'aal1';
        if (aal != 'aal2') {
          await authManager.signOut();
          GoRouter.of(context).clearRedirectLocation();
          if (!mounted) return;
          setState(() {
            _submitting = false;
            _error =
                'Admin Master requer autenticação em dois fatores. Habilite MFA na sua conta antes de entrar.';
          });
          return;
        }
      }

      context.goNamedAuth(
        HomePageWidget.routeName,
        context.mounted,
        extra: <String, dynamic>{
          '__transition_info__': TransitionInfo(
            hasTransition: true,
            transitionType: PageTransitionType.fade,
            duration: const Duration(milliseconds: 400),
          ),
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = 'Falha no login. Tente novamente em instantes.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context).size;
    final isWide = mq.width >= 980;

    return Scaffold(
      backgroundColor: const Color(0xFF1F1F1F),
      body: Stack(
        children: [
          // Background com aurora
          const _AuroraBackground(),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: isWide ? 1080 : 480),
                    child: isWide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: const [
                              Expanded(child: _BrandPanel()),
                              SizedBox(width: 48),
                              Expanded(child: _LoginPanelHook()),
                            ],
                          )
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              _BrandPanel(compact: true),
                              SizedBox(height: 24),
                              _LoginPanelHook(),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ),

          // Footer
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
    );
  }
}

class _LoginPanelHook extends StatelessWidget {
  const _LoginPanelHook();

  @override
  Widget build(BuildContext context) {
    final state = context.findAncestorStateOfType<_LoginWidgetState>();
    if (state == null) return const SizedBox.shrink();
    return _LoginPanel(state: state);
  }
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel({this.compact = false});
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment:
          compact ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        // Logo
        Container(
          width: compact ? 92 : 110,
          height: compact ? 92 : 110,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0x22FFFFFF), width: 1),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFC2D51C).withValues(alpha: 0.18),
                blurRadius: 36,
                spreadRadius: -4,
              ),
            ],
          ),
          child: const AppAssetImage(
            'assets/images/Logo_AEROTG_NEGATIVO_V.png',
            fit: BoxFit.contain,
          ),
        )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .scaleXY(
              begin: 1,
              end: 1.04,
              duration: const Duration(milliseconds: 2400),
              curve: Curves.easeInOut,
            ),
        const SizedBox(height: 28),
        Text(
          compact ? 'Agsur · Painel' : 'Bem-vindo ao painel\nAgsur',
          textAlign: compact ? TextAlign.center : TextAlign.start,
          style: GoogleFonts.inter(
            fontSize: compact ? 22 : 38,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -0.6,
            height: 1.1,
          ),
        ).animate().fadeIn(delay: 120.ms, duration: 500.ms).moveY(
              begin: 8,
              end: 0,
              delay: 120.ms,
              curve: Curves.easeOutCubic,
            ),
        const SizedBox(height: 12),
        Text(
          compact
              ? 'Acesso administrativo ao back-office.'
              : 'Gerencie leads, propostas, contratos, oficinas e a esteira de importação em um só lugar.',
          textAlign: compact ? TextAlign.center : TextAlign.start,
          style: GoogleFonts.roboto(
            fontSize: 14,
            color: const Color(0xCCFFFFFF),
            height: 1.5,
          ),
        ).animate().fadeIn(delay: 220.ms, duration: 500.ms),
      ],
    );
  }
}

class _LoginPanel extends StatefulWidget {
  const _LoginPanel({required this.state});
  final _LoginWidgetState state;

  @override
  State<_LoginPanel> createState() => _LoginPanelState();
}

class _LoginPanelState extends State<_LoginPanel> {
  bool _showPassword = false;

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
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
      child: Form(
        key: state._formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Entrar',
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Use sua conta administrativa para acessar.',
              style: GoogleFonts.roboto(
                fontSize: 13,
                color: const Color(0x99FFFFFF),
              ),
            ),
            const SizedBox(height: 24),

            _AppFormField(
              controller: state._model.tFEmailTextController!,
              focusNode: state._model.tFEmailFocusNode!,
              label: 'E-mail',
              hint: 'voce@agsur.com.br',
              icon: Icons.alternate_email_rounded,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              enabled: !state._submitting,
              validator: (v) {
                final value = (v ?? '').trim();
                if (value.isEmpty) return 'Informe o e-mail';
                if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)) {
                  return 'E-mail inválido';
                }
                return null;
              },
              onSubmit: (_) =>
                  state._model.tFSenhaFocusNode?.requestFocus(),
            ).animate().fadeIn(delay: 120.ms).moveY(begin: 6, end: 0),

            const SizedBox(height: 14),

            _AppFormField(
              controller: state._model.tFSenhaTextController!,
              focusNode: state._model.tFSenhaFocusNode!,
              label: 'Senha',
              hint: '••••••••',
              icon: Icons.lock_outline_rounded,
              obscure: !_showPassword,
              autofillHints: const [AutofillHints.password],
              enabled: !state._submitting,
              trailing: IconButton(
                splashRadius: 20,
                tooltip: _showPassword ? 'Ocultar senha' : 'Mostrar senha',
                onPressed: () =>
                    setState(() => _showPassword = !_showPassword),
                icon: Icon(
                  _showPassword
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                  color: const Color(0x99FFFFFF),
                  size: 18,
                ),
              ),
              validator: (v) {
                if ((v ?? '').isEmpty) return 'Informe a senha';
                return null;
              },
              onSubmit: (_) => state._submit(),
            ).animate().fadeIn(delay: 200.ms).moveY(begin: 6, end: 0),

            const SizedBox(height: 8),

            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: state._submitting
                    ? null
                    : () =>
                        context.pushNamed(ResetPasswordWidget.routeName),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFC2D51C),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: Text(
                  'Esqueci minha senha',
                  style: GoogleFonts.roboto(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

            if (state._error != null) ...[
              const SizedBox(height: 4),
              _ErrorBanner(message: state._error!),
            ],

            const SizedBox(height: 16),

            _AppPrimaryButton(
              label: state._submitting ? 'Entrando...' : 'Entrar',
              busy: state._submitting,
              onPressed: state._submit,
              icon: Icons.login_rounded,
            ).animate().fadeIn(delay: 280.ms).moveY(begin: 6, end: 0),

            const SizedBox(height: 14),
            Text(
              'Acesso restrito a Admin, Vendedor ou Funcionário.',
              textAlign: TextAlign.center,
              style: GoogleFonts.roboto(
                fontSize: 11,
                color: const Color(0x77FFFFFF),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
    this.validator,
    this.onSubmit,
    this.trailing,
    this.enabled = true,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final String? hint;
  final IconData icon;
  final bool obscure;
  final TextInputType? keyboardType;
  final Iterable<String>? autofillHints;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onSubmit;
  final Widget? trailing;
  final bool enabled;

  @override
  State<_AppFormField> createState() => _AppFormFieldState();
}

class _AppFormFieldState extends State<_AppFormField> {
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_listener);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_listener);
    super.dispose();
  }

  void _listener() {
    if (mounted) setState(() => _focused = widget.focusNode.hasFocus);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.4,
            color: _focused
                ? const Color(0xFFC2D51C)
                : const Color(0x99FFFFFF),
          ),
        ),
        const SizedBox(height: 6),
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
                      color:
                          const Color(0xFFC2D51C).withValues(alpha: 0.18),
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
                    inputFormatters: const [],
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
      cursor: disabled
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() {
        _hover = false;
        _press = false;
      }),
      child: GestureDetector(
        onTapDown: (_) =>
            disabled ? null : setState(() => _press = true),
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
                        ? const [Color(0xFFD3E63D), Color(0xFFB6C815)]
                        : const [Color(0xFFC2D51C), Color(0xFFA1B015)],
              ),
              boxShadow: disabled
                  ? null
                  : [
                      BoxShadow(
                        color: const Color(0xFFC2D51C)
                            .withValues(alpha: _hover ? 0.45 : 0.25),
                        blurRadius: _hover ? 22 : 14,
                        spreadRadius: -2,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.busy)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Color(0xFF1F1F1F)),
                      ),
                    )
                  else if (widget.icon != null) ...[
                    Icon(widget.icon, size: 18, color: const Color(0xFF1F1F1F)),
                  ],
                  if (widget.busy || widget.icon != null)
                    const SizedBox(width: 10),
                  Text(
                    widget.label,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1F1F1F),
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: const Color(0x33FF5963),
        borderRadius: BorderRadius.circular(10),
        border:
            Border.all(color: const Color(0x55FF5963).withValues(alpha: 1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: Color(0xFFFF7B82), size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.roboto(
                fontSize: 12.5,
                color: const Color(0xFFFF9DA3),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    ).animate(target: 1).shake(
          hz: 5,
          duration: 360.ms,
          rotation: 0,
          offset: const Offset(2, 0),
        );
  }
}

class _AuroraBackground extends StatelessWidget {
  const _AuroraBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(-0.7, -0.8),
              radius: 0.9,
              colors: [Color(0x33C2D51C), Color(0x001F1F1F)],
            ),
          ),
        )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .moveX(begin: -20, end: 20, duration: 6.seconds, curve: Curves.easeInOut)
            .moveY(begin: -20, end: 20, duration: 6.seconds, curve: Curves.easeInOut),
        Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0.8, 0.9),
              radius: 0.9,
              colors: [Color(0x2239D2C0), Color(0x001F1F1F)],
            ),
          ),
        )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .moveX(begin: 20, end: -20, duration: 7.seconds, curve: Curves.easeInOut)
            .moveY(begin: 20, end: -20, duration: 7.seconds, curve: Curves.easeInOut),
        // Grid sutil
        Opacity(
          opacity: 0.04,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.white, Colors.transparent],
              ),
              backgroundBlendMode: BlendMode.overlay,
            ),
          ),
        ),
      ],
    );
  }
}
