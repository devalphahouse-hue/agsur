import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_animations.dart';
import 'app_responsive.dart';

/// Header padrão de páginas: eyebrow + título + descrição + ações à direita.
class AppPageHeader extends StatelessWidget {
  const AppPageHeader({
    super.key,
    required this.title,
    this.eyebrow,
    this.description,
    this.actions = const [],
  });

  final String? eyebrow;
  final String title;
  final String? description;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final stacked = context.isStacked;

    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (eyebrow != null && eyebrow!.isNotEmpty)
          Text(
            eyebrow!.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 2.4,
              color: const Color(0xFFC2D51C),
            ),
          ),
        if (eyebrow != null && eyebrow!.isNotEmpty) const SizedBox(height: 6),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: stacked ? 22 : 26,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: -0.4,
            height: 1.15,
          ),
        ),
        if (description != null && description!.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            description!,
            style: GoogleFonts.roboto(
              fontSize: 13,
              color: const Color(0xCCFFFFFF),
              height: 1.4,
            ),
          ),
        ],
      ],
    );

    // Mobile / tablet retrato: empilha. As ações vão abaixo do título numa
    // linha com rolagem horizontal, para que um filtro/botão largo nunca
    // esprema o título (uma letra por linha) nem estoure a tela.
    if (stacked) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            titleBlock,
            if (actions.isNotEmpty) ...[
              const SizedBox(height: 14),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < actions.length; i++) ...[
                      if (i > 0) const SizedBox(width: 8),
                      actions[i],
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ).appFade();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(child: titleBlock),
          if (actions.isNotEmpty) ...[
            const SizedBox(width: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              children: actions,
            ),
          ],
        ],
      ),
    ).appFade();
  }
}
