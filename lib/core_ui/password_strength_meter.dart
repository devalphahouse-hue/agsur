import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/security/password_utils.dart';

/// Medidor de força de senha — mostra os níveis (barras + rótulo) e os
/// requisitos atendidos enquanto o usuário digita. Posicione logo abaixo do
/// campo de senha, passando o texto atual do controller. Some quando vazio.
class PasswordStrengthMeter extends StatelessWidget {
  const PasswordStrengthMeter({super.key, required this.password});

  final String password;

  static const Color _weak = Color(0xFFFF7B82);
  static const Color _medium = Color(0xFFE6B450);
  static const Color _strong = Color(0xFFC2D51C);

  Color _colorFor(String label) {
    switch (label) {
      case 'Forte':
        return _strong;
      case 'Média':
        return _medium;
      default:
        return _weak;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) return const SizedBox.shrink();
    final s = evaluatePasswordStrength(password);
    final color = _colorFor(s.label);
    final filled = s.score.clamp(0, 4);

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              for (var i = 0; i < 4; i++) ...[
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    height: 4,
                    decoration: BoxDecoration(
                      color: i < filled ? color : const Color(0x22FFFFFF),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                if (i < 3) const SizedBox(width: 4),
              ],
              const SizedBox(width: 10),
              Text(
                s.label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _Requirement(ok: s.meetsMinLength, text: 'Mínimo de 8 caracteres'),
          const SizedBox(height: 2),
          _Requirement(ok: s.meetsLetterAndNumber, text: 'Letras e números'),
        ],
      ),
    );
  }
}

class _Requirement extends StatelessWidget {
  const _Requirement({required this.ok, required this.text});

  final bool ok;
  final String text;

  @override
  Widget build(BuildContext context) {
    final color = ok ? const Color(0xFFC2D51C) : const Color(0x80FFFFFF);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          ok ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
          size: 13,
          color: color,
        ),
        const SizedBox(width: 5),
        Text(
          text,
          style: GoogleFonts.roboto(fontSize: 11, color: color),
        ),
      ],
    );
  }
}
