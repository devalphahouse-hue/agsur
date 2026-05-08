import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_animations.dart';
import 'app_page_header.dart';
import 'app_shell.dart';

/// Scaffold padrão de telas de listagem.
/// O menu lateral vem do [AppShell] (ShellRoute) — esta tela apenas
/// devolve o conteúdo da coluna direita.
/// Em mobile (< [kSidebarBreakpoint]) mostra um botão hambúrguer que
/// abre o Drawer global do AppShell.
class AppListScaffold extends StatelessWidget {
  const AppListScaffold({
    super.key,
    required this.eyebrow,
    required this.title,
    this.description,
    this.actions = const [],
    this.search,
    required this.body,
  });

  final String eyebrow;
  final String title;
  final String? description;
  final List<Widget> actions;
  final Widget? search;
  final Widget body;

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
                  AppPageHeader(
                    eyebrow: eyebrow,
                    title: title,
                    description: description,
                    actions: actions,
                  ),
                  if (search != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(28, 0, 28, 12),
                      child: search!,
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(28, 4, 28, 0),
                    child: body,
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
    ).appFade();
  }
}
