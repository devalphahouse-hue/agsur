import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum AppStatusTone { neutral, brand, success, warning, danger, teal }

class AppStatusBadge extends StatelessWidget {
  const AppStatusBadge({
    super.key,
    required this.label,
    this.icon,
    this.tone = AppStatusTone.neutral,
    this.dense = false,
  });

  final String label;
  final IconData? icon;
  final AppStatusTone tone;
  final bool dense;

  Color get _bg => switch (tone) {
        AppStatusTone.neutral => const Color(0x22FFFFFF),
        AppStatusTone.brand => const Color(0x33C2D51C),
        AppStatusTone.success => const Color(0x33249689),
        AppStatusTone.warning => const Color(0x33F9CF58),
        AppStatusTone.danger => const Color(0x33FF5963),
        AppStatusTone.teal => const Color(0x3339D2C0),
      };

  Color get _fg => switch (tone) {
        AppStatusTone.neutral => const Color(0xCCFFFFFF),
        AppStatusTone.brand => const Color(0xFFD4E657),
        AppStatusTone.success => const Color(0xFF4FBFA9),
        AppStatusTone.warning => const Color(0xFFF9CF58),
        AppStatusTone.danger => const Color(0xFFFF7B82),
        AppStatusTone.teal => const Color(0xFF4FE0D0),
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 8 : 10,
        vertical: dense ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: dense ? 11 : 12, color: _fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: dense ? 10 : 11,
              fontWeight: FontWeight.w600,
              color: _fg,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
