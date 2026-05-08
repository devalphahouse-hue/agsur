import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_animations.dart';

/// Hero header rico para telas de detalhe.
/// Stack: gradiente sutil verde-limão + avatar/ícone grande + título +
/// metadados + chips/badges. Opcionalmente recebe uma linha de KPIs
/// que aparece colada no rodapé do hero.
///
/// Convenção de uso:
/// ```dart
/// AppDetailHero(
///   avatarText: 'JS',
///   title: 'João Silva',
///   subtitle: 'joao@email.com · (11) 99999-9999',
///   badge: AppStatusBadge(label: 'Ativo', tone: AppStatusTone.success),
///   chips: [HeroChip(icon: Icons.shield, label: 'Admin')],
///   stats: [
///     HeroStat(label: 'Aeronaves', value: '3'),
///     HeroStat(label: 'Contratos', value: '12'),
///   ],
/// )
/// ```
class AppDetailHero extends StatelessWidget {
  const AppDetailHero({
    super.key,
    this.avatarText,
    this.avatarIcon,
    this.avatarImageUrl,
    this.avatarColor,
    required this.title,
    this.subtitle,
    this.eyebrow,
    this.badge,
    this.chips = const [],
    this.stats = const [],
    this.actions = const [],
  });

  /// Texto curto (iniciais) para o avatar — usado quando não há imagem.
  final String? avatarText;

  /// Ícone para o avatar — usado quando não há imagem nem texto.
  final IconData? avatarIcon;

  /// URL da imagem de avatar.
  final String? avatarImageUrl;

  /// Tom do avatar (acento de fundo). Default: verde-limão Agsur.
  final Color? avatarColor;

  /// Pequeno rótulo acima do título (ex.: 'OFICINA · São Paulo').
  final String? eyebrow;

  /// Título principal — nome do recurso.
  final String title;

  /// Linha auxiliar abaixo do título — metadados curtos separados por '·'.
  final String? subtitle;

  /// Badge de status à direita do título.
  final Widget? badge;

  /// Chips informativos abaixo do bloco principal (até 4 ficam bonitos).
  final List<HeroChip> chips;

  /// Linha de KPIs que aparece colada no rodapé (até 3-4 ficam bonitos).
  final List<HeroStat> stats;

  /// Ações alinhadas à direita (botões, IconButtons).
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final tone = avatarColor ?? const Color(0xFFC2D51C);

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 14),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              tone.withValues(alpha: 0.14),
              tone.withValues(alpha: 0.04),
              const Color(0xFF404040).withValues(alpha: 0.0),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: tone.withValues(alpha: 0.20),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: tone.withValues(alpha: 0.08),
              blurRadius: 28,
              spreadRadius: -8,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.40),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Glow decorativo
              Positioned(
                right: -60,
                top: -60,
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        tone.withValues(alpha: 0.18),
                        tone.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _Avatar(
                          text: avatarText,
                          icon: avatarIcon,
                          imageUrl: avatarImageUrl,
                          tone: tone,
                        ).appFade(),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (eyebrow != null && eyebrow!.isNotEmpty) ...[
                                Text(
                                  eyebrow!.toUpperCase(),
                                  style: GoogleFonts.inter(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.4,
                                    color: tone.withValues(alpha: 0.95),
                                  ),
                                ),
                                const SizedBox(height: 4),
                              ],
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Text(
                                      title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                        letterSpacing: -0.5,
                                        height: 1.2,
                                      ),
                                    ),
                                  ),
                                  if (badge != null) ...[
                                    const SizedBox(width: 12),
                                    badge!,
                                  ],
                                ],
                              ),
                              if (subtitle != null &&
                                  subtitle!.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  subtitle!,
                                  style: GoogleFonts.roboto(
                                    fontSize: 13,
                                    color: const Color(0xCCFFFFFF),
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (actions.isNotEmpty) ...[
                          const SizedBox(width: 14),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              for (var i = 0; i < actions.length; i++) ...[
                                if (i > 0) const SizedBox(width: 8),
                                actions[i],
                              ],
                            ],
                          ),
                        ],
                      ],
                    ),
                    if (chips.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [for (final c in chips) c],
                      ),
                    ],
                    if (stats.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.20),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.06),
                          ),
                        ),
                        child: Row(
                          children: [
                            for (var i = 0; i < stats.length; i++) ...[
                              if (i > 0)
                                Container(
                                  width: 1,
                                  height: 36,
                                  color: Colors.white.withValues(alpha: 0.06),
                                ),
                              Expanded(child: stats[i]),
                            ],
                          ],
                        ),
                      ).appFade(delay: const Duration(milliseconds: 80)),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.text,
    required this.icon,
    required this.imageUrl,
    required this.tone,
  });

  final String? text;
  final IconData? icon;
  final String? imageUrl;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;

    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [tone.withValues(alpha: 0.40), tone.withValues(alpha: 0.12)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tone.withValues(alpha: 0.55), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: tone.withValues(alpha: 0.18),
            blurRadius: 18,
            spreadRadius: -2,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: hasImage
          ? ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                imageUrl!,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _fallback(),
              ),
            )
          : _fallback(),
    );
  }

  Widget _fallback() {
    if (text != null && text!.isNotEmpty) {
      return Text(
        text!.length > 2 ? text!.substring(0, 2).toUpperCase() : text!.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          letterSpacing: -0.4,
        ),
      );
    }
    return Icon(
      icon ?? Icons.person_rounded,
      color: Colors.white,
      size: 28,
    );
  }
}

class HeroChip extends StatelessWidget {
  const HeroChip({super.key, required this.icon, required this.label, this.tone});

  final IconData icon;
  final String label;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final t = tone ?? const Color(0xFFC2D51C);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: t.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: t.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: t),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.94),
            ),
          ),
        ],
      ),
    );
  }
}

class HeroStat extends StatelessWidget {
  const HeroStat({super.key, required this.label, required this.value, this.icon});

  final String label;
  final String value;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: const Color(0xFFC2D51C)),
            const SizedBox(width: 8),
          ],
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label.toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                  color: const Color(0x88FFFFFF),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Card de seção com cabeçalho fixo (ícone + título + ações) e corpo livre.
/// Usar como container das partes do detalhe (Dados pessoais, Endereço, etc).
class AppSectionCard extends StatelessWidget {
  const AppSectionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.child,
    this.subtitle,
    this.actions = const [],
    this.padding = const EdgeInsets.fromLTRB(20, 18, 20, 18),
    this.margin = const EdgeInsets.only(bottom: 14),
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: const Color(0xFF404040),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x14FFFFFF)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.30),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 14, 12),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0x33C2D51C),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    size: 16,
                    color: const Color(0xFFC2D51C),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.1,
                        ),
                      ),
                      if (subtitle != null && subtitle!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: GoogleFonts.roboto(
                            fontSize: 11.5,
                            color: const Color(0x99FFFFFF),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (actions.isNotEmpty) ...[
                  const SizedBox(width: 12),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < actions.length; i++) ...[
                        if (i > 0) const SizedBox(width: 6),
                        actions[i],
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            color: Colors.white.withValues(alpha: 0.05),
          ),
          Padding(padding: padding, child: child),
        ],
      ),
    );
  }
}

/// Linha "key/value" para usar dentro de [AppSectionCard].
/// Por padrão renderiza "Label · Valor" em layout coluna pra ficar legível.
class AppDetailRow extends StatelessWidget {
  const AppDetailRow({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.copyable = false,
    this.dense = false,
  });

  final String label;
  final String value;
  final IconData? icon;
  final bool copyable;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: dense ? 6 : 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: const Color(0x88FFFFFF)),
            const SizedBox(width: 10),
          ],
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0x88FFFFFF),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value.isEmpty ? '—' : value,
              style: GoogleFonts.roboto(
                fontSize: 13,
                color: value.isEmpty
                    ? const Color(0x66FFFFFF)
                    : Colors.white,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Grid de 2 colunas para [AppDetailRow] em telas wide; vira coluna única
/// abaixo de 720px.
class AppDetailGrid extends StatelessWidget {
  const AppDetailGrid({super.key, required this.rows, this.columns = 2});

  final List<Widget> rows;
  final int columns;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final useColumns = c.maxWidth >= 720 ? columns : 1;
        if (useColumns == 1) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: rows,
          );
        }
        // Distribui rows em colunas igualmente
        final perCol = (rows.length / useColumns).ceil();
        final cols = <List<Widget>>[];
        for (var i = 0; i < useColumns; i++) {
          final start = i * perCol;
          final end = (start + perCol).clamp(0, rows.length);
          cols.add(rows.sublist(start, end));
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < cols.length; i++) ...[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: cols[i],
                ),
              ),
              if (i < cols.length - 1) const SizedBox(width: 28),
            ],
          ],
        );
      },
    );
  }
}
