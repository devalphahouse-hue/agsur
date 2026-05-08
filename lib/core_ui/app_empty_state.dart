import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Estado vazio padrão: ícone grande circular + título + descrição + ação opcional.
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.description,
    this.action,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String? description;
  final Widget? action;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final iconSize = compact ? 32.0 : 40.0;
    final containerSize = compact ? 64.0 : 80.0;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: compact ? 32 : 56),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: containerSize,
              height: containerSize,
              decoration: BoxDecoration(
                color: const Color(0x14FFFFFF),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0x22FFFFFF),
                  width: 1,
                ),
              ),
              child: Icon(icon, size: iconSize, color: const Color(0xFFC2D51C)),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            if (description != null) ...[
              const SizedBox(height: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: Text(
                  description!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.roboto(
                    fontSize: 12.5,
                    color: const Color(0xAAFFFFFF),
                    height: 1.4,
                  ),
                ),
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 16),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
