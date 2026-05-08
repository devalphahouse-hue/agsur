import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_animations.dart';
import 'app_shell.dart';

/// Scaffold padrão de telas de detalhes/edição (uma só linha).
/// O menu lateral vem do [AppShell]. Esta tela renderiza o conteúdo
/// da coluna direita com header próprio (back button + título + ações).
class AppDetailsScaffold extends StatelessWidget {
  const AppDetailsScaffold({
    super.key,
    required this.title,
    this.subtitle,
    this.onBack,
    this.actions = const [],
    required this.body,
    this.maxBodyWidth,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onBack;
  final List<Widget> actions;
  final Widget body;
  final double? maxBodyWidth;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= kSidebarBreakpoint;
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!wide)
            _MiniTopBar(
              onOpenDrawer: openAppShellDrawer,
              title: title,
            ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Header(
                    title: title,
                    subtitle: subtitle,
                    onBack: onBack,
                    actions: actions,
                  ).appFade(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                    child: maxBodyWidth != null
                        ? Center(
                            child: ConstrainedBox(
                              constraints:
                                  BoxConstraints(maxWidth: maxBodyWidth!),
                              child: body,
                            ),
                          )
                        : body,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.subtitle,
    required this.onBack,
    required this.actions,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onBack;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _BackBtn(onTap: onBack ?? () => Navigator.of(context).maybePop()),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.4,
                  ),
                ),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: GoogleFonts.roboto(
                      fontSize: 13,
                      color: const Color(0xAAFFFFFF),
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (actions.isNotEmpty) ...[
            const SizedBox(width: 14),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < actions.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  actions[i],
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

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
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _hover
                ? const Color(0x22C2D51C)
                : Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _hover
                  ? const Color(0x55C2D51C)
                  : Colors.white.withValues(alpha: 0.06),
            ),
          ),
          child: Icon(
            Icons.arrow_back_rounded,
            size: 18,
            color: _hover ? const Color(0xFFC2D51C) : Colors.white,
          ),
        ),
      ),
    );
  }
}

class _MiniTopBar extends StatefulWidget {
  const _MiniTopBar({required this.onOpenDrawer, required this.title});
  final VoidCallback onOpenDrawer;
  final String title;

  @override
  State<_MiniTopBar> createState() => _MiniTopBarState();
}

class _MiniTopBarState extends State<_MiniTopBar> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
      ),
      child: Row(
        children: [
          MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (_) => setState(() => _hover = true),
            onExit: (_) => setState(() => _hover = false),
            child: GestureDetector(
              onTap: widget.onOpenDrawer,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _hover
                      ? const Color(0x22C2D51C)
                      : Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _hover
                        ? const Color(0x55C2D51C)
                        : Colors.white.withValues(alpha: 0.06),
                  ),
                ),
                child: Icon(
                  Icons.menu_rounded,
                  size: 16,
                  color: _hover ? const Color(0xFFC2D51C) : Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            widget.title,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xCCFFFFFF),
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
