import 'package:flutter/material.dart';

/// Pequeno botão de ícone usado em rows de tabela.
/// Default 28x28, hover muda cor de fundo + cor do ícone.
class AppRowAction extends StatefulWidget {
  const AppRowAction({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.danger = false,
    this.size = 28,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool danger;
  final double size;

  @override
  State<AppRowAction> createState() => _AppRowActionState();
}

class _AppRowActionState extends State<AppRowAction> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final color = _hover
        ? (widget.danger
            ? const Color(0xFFFF5963)
            : const Color(0xFFC2D51C))
        : const Color(0x99FFFFFF);
    final bg = _hover
        ? (widget.danger
            ? const Color(0x22FF5963)
            : const Color(0x22C2D51C))
        : Colors.transparent;

    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: widget.onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(widget.icon, size: 16, color: color),
          ),
        ),
      ),
    );
  }
}
