import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Botão primário gradient verde-limão. Aceita estado busy.
class AppPrimaryButton extends StatefulWidget {
  const AppPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.busy = false,
    this.expanded = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool busy;
  final bool expanded;

  @override
  State<AppPrimaryButton> createState() => _AppPrimaryButtonState();
}

class _AppPrimaryButtonState extends State<AppPrimaryButton> {
  bool _hover = false;
  bool _press = false;

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onPressed == null || widget.busy;

    final btn = AnimatedScale(
      scale: _press ? 0.98 : 1,
      duration: const Duration(milliseconds: 120),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: disabled
                ? const [Color(0x55C2D51C), Color(0x55AEC117)]
                : const [Color(0xFFC2D51C), Color(0xFFAEC117)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(11),
          boxShadow: disabled
              ? null
              : [
                  BoxShadow(
                    color: const Color(0xFFC2D51C)
                        .withValues(alpha: _hover ? 0.5 : 0.3),
                    blurRadius: _hover ? 22 : 14,
                    spreadRadius: -2,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: widget.expanded ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
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
            if (widget.busy || widget.icon != null) const SizedBox(width: 8),
            Text(
              widget.label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF313131),
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );

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
        onTapDown: disabled ? null : (_) => setState(() => _press = true),
        onTapCancel: () => setState(() => _press = false),
        onTapUp: disabled ? null : (_) => setState(() => _press = false),
        onTap: disabled ? null : widget.onPressed,
        child: btn,
      ),
    );
  }
}

/// Botão secundário (fundo discreto + borda). Usado em "Cancelar" etc.
class AppSecondaryButton extends StatefulWidget {
  const AppSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.danger = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool danger;

  @override
  State<AppSecondaryButton> createState() => _AppSecondaryButtonState();
}

class _AppSecondaryButtonState extends State<AppSecondaryButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final accent = widget.danger
        ? const Color(0xFFFF7B82)
        : const Color(0xCCFFFFFF);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            color: _hover
                ? (widget.danger
                    ? const Color(0x22FF5963)
                    : const Color(0x14FFFFFF))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              color: _hover
                  ? accent.withValues(alpha: 0.8)
                  : Colors.white.withValues(alpha: 0.14),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 14, color: accent),
                const SizedBox(width: 6),
              ],
              Text(
                widget.label,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: accent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
