import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_card.dart';
import 'app_storage.dart';

/// Card de pessoa reutilizado nas listagens (Clientes, Pilotos, Oficinas,
/// Vendedores, Colaboradores). Layout: avatar + identidade + metas + ações.
class AppPersonCard extends StatelessWidget {
  const AppPersonCard({
    super.key,
    required this.name,
    this.subtitle,
    this.metas = const [],
    this.avatarUrl,
    this.avatarIcon = Icons.person_outline_rounded,
    this.avatarColor = const Color(0xFFC2D51C),
    required this.isActive,
    this.onTap,
    this.trailing = const [],
  });

  final String name;

  /// Linha logo abaixo do nome — ex.: cargo, email.
  final String? subtitle;

  /// Lista de pares (ícone + texto) — ex.: empresa, telefone.
  final List<AppPersonMeta> metas;

  final String? avatarUrl;
  final IconData avatarIcon;
  final Color avatarColor;
  final bool isActive;
  final VoidCallback? onTap;

  /// Widgets à direita (geralmente Switch + AppRowAction).
  final List<Widget> trailing;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _Avatar(
            url: avatarUrl,
            icon: avatarIcon,
            color: avatarColor,
            isActive: isActive,
            initial: _initial(name),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.1,
                  ),
                ),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.roboto(
                      fontSize: 12,
                      color: const Color(0xCCFFFFFF),
                    ),
                  ),
                ],
                if (metas.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 14,
                    runSpacing: 4,
                    children: [
                      for (final m in metas)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(m.icon,
                                size: 12, color: const Color(0x99FFFFFF)),
                            const SizedBox(width: 4),
                            Text(
                              m.text,
                              style: GoogleFonts.roboto(
                                fontSize: 11.5,
                                color: const Color(0x99FFFFFF),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (trailing.isNotEmpty) ...[
            const SizedBox(width: 14),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int i = 0; i < trailing.length; i++) ...[
                  trailing[i],
                  if (i != trailing.length - 1) const SizedBox(width: 6),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  static String _initial(String name) {
    final t = name.trim();
    if (t.isEmpty) return '?';
    return t[0].toUpperCase();
  }
}

class AppPersonMeta {
  const AppPersonMeta(this.icon, this.text);
  final IconData icon;
  final String text;
}

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.url,
    required this.icon,
    required this.color,
    required this.isActive,
    required this.initial,
  });

  final String? url;
  final IconData icon;
  final Color color;
  final bool isActive;
  final String initial;

  @override
  Widget build(BuildContext context) {
    final hasUrl = url != null && url!.isNotEmpty;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.18),
            border: Border.all(
              color: color.withValues(alpha: 0.45),
              width: 1.2,
            ),
          ),
          child: hasUrl
              ? ClipOval(
                  child: SignedNetworkImage(
                    url!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        _Initial(letter: initial, color: color),
                  ),
                )
              : _Initial(letter: initial, color: color),
        ),
        Positioned(
          bottom: -1,
          right: -1,
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: isActive
                  ? const Color(0xFF4FBFA9)
                  : const Color(0x99FF5963),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF404040), width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

class _Initial extends StatelessWidget {
  const _Initial({required this.letter, required this.color});
  final String letter;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        letter,
        style: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
