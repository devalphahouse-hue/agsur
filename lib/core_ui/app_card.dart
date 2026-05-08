import 'package:flutter/material.dart';

/// Wrapper sobre Material/Container com:
/// - Border sutil (0x14FFFFFF)
/// - Elevação interna por sombra
/// - Hover com leve glow brand
/// - Press com scale 0.99
class AppCard extends StatefulWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 16,
    this.background,
    this.border,
    this.constraints,
    this.glow = false,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final Color? background;
  final BoxBorder? border;
  final BoxConstraints? constraints;
  final bool glow;

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  bool _hover = false;
  bool _press = false;

  @override
  Widget build(BuildContext context) {
    final hasTap = widget.onTap != null;
    final shadowAlpha = _hover ? 0.55 : 0.35;
    final glowAlpha = _hover && widget.glow ? 0.18 : 0.08;

    final card = AnimatedScale(
      scale: _press ? 0.99 : 1,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: widget.padding,
        constraints: widget.constraints,
        decoration: BoxDecoration(
          color: widget.background ?? const Color(0xFF404040),
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: widget.border ??
              Border.all(
                color: _hover
                    ? const Color(0x33C2D51C)
                    : const Color(0x14FFFFFF),
                width: 1,
              ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: shadowAlpha),
              blurRadius: _hover ? 24 : 14,
              offset: Offset(0, _hover ? 8 : 4),
            ),
            if (widget.glow)
              BoxShadow(
                color: const Color(0xFFC2D51C).withValues(alpha: glowAlpha),
                blurRadius: 24,
                spreadRadius: -2,
              ),
          ],
        ),
        child: widget.child,
      ),
    );

    if (!hasTap) return card;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() {
        _hover = false;
        _press = false;
      }),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _press = true),
        onTapCancel: () => setState(() => _press = false),
        onTapUp: (_) => setState(() => _press = false),
        onTap: widget.onTap,
        child: card,
      ),
    );
  }
}
