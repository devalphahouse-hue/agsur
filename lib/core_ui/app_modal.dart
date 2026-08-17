import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Wrapper de modal padrão do redesign.
/// - Caixa central com sombra e blur sutil
/// - Header com ícone tematizado + título + descrição + close
/// - Conteúdo rolável dentro de constraints (maxHeight 90% da viewport)
/// - Footer fixo opcional (geralmente os botões de ação)
class AppModal extends StatelessWidget {
  const AppModal({
    super.key,
    required this.icon,
    required this.title,
    this.description,
    required this.child,
    this.footer,
    this.maxWidth = 720,
    this.iconTone = AppModalTone.brand,
  });

  final IconData icon;
  final String title;
  final String? description;
  final Widget child;
  final Widget? footer;
  final double maxWidth;
  final AppModalTone iconTone;

  Color get _iconBg => switch (iconTone) {
        AppModalTone.brand => const Color(0x33C2D51C),
        AppModalTone.danger => const Color(0x33FF5963),
        AppModalTone.success => const Color(0x33249689),
      };

  Color get _iconFg => switch (iconTone) {
        AppModalTone.brand => const Color(0xFFC2D51C),
        AppModalTone.danger => const Color(0xFFFF7B82),
        AppModalTone.success => const Color(0xFF4FBFA9),
      };

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    // Altura do teclado. No web/desktop é sempre 0, então isto é no-op lá.
    // No celular, sem descontar: `size.height` é a tela INTEIRA, o modal é
    // dimensionado como se o teclado não existisse e os campos de baixo ficam
    // atrás dele, sem rolagem que alcance. Vale para os 28 usos de AppModal.
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final visibleHeight = size.height - keyboard;

    return Center(
      child: Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: 24 + keyboard,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: maxWidth,
            maxHeight: visibleHeight * 0.9,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.06),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.6),
                  blurRadius: 40,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Header(
                  icon: icon,
                  iconBg: _iconBg,
                  iconFg: _iconFg,
                  title: title,
                  description: description,
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                    child: child,
                  ),
                ),
                if (footer != null)
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 14, 24, 20),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: Colors.white.withValues(alpha: 0.06),
                        ),
                      ),
                    ),
                    child: footer!,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum AppModalTone { brand, danger, success }

class _Header extends StatefulWidget {
  const _Header({
    required this.icon,
    required this.iconBg,
    required this.iconFg,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconFg;
  final String title;
  final String? description;

  @override
  State<_Header> createState() => _HeaderState();
}

class _HeaderState extends State<_Header> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 22, 16, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: widget.iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(widget.icon, color: widget.iconFg, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.title,
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.2,
                  ),
                ),
                if (widget.description != null &&
                    widget.description!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    widget.description!,
                    style: GoogleFonts.roboto(
                      fontSize: 12.5,
                      color: const Color(0xAAFFFFFF),
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (_) => setState(() => _hover = true),
            onExit: (_) => setState(() => _hover = false),
            child: GestureDetector(
              onTap: () => Navigator.of(context).maybePop(),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _hover
                      ? const Color(0x22FF5963)
                      : Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: _hover
                      ? const Color(0xFFFF7B82)
                      : const Color(0xCCFFFFFF),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
