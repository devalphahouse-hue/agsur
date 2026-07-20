import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/backend/paged_query.dart';
import 'app_card.dart';
import 'app_responsive.dart';

/// Rodapé de paginação: "11–20 de 57", seletor de itens por página e
/// navegação anterior/próxima.
///
/// Os dados vêm de [PagedResult], que é preenchido pelo backend
/// (`range` + `count=exact`) — nada aqui pagina em memória.
class AppPagination extends StatelessWidget {
  const AppPagination({
    super.key,
    required this.result,
    required this.onPageChanged,
    required this.onPerPageChanged,
  });

  final PagedResult result;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onPerPageChanged;

  @override
  Widget build(BuildContext context) {
    if (result.total == 0) return const SizedBox.shrink();

    final resumo = Text(
      '${result.firstIndex}–${result.lastIndex} de ${result.total}',
      style: GoogleFonts.inter(
        fontSize: 12.5,
        color: const Color(0xB3FFFFFF),
      ),
    );

    final porPagina = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Por página',
          style: GoogleFonts.inter(
            fontSize: 12.5,
            color: const Color(0x8AFFFFFF),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: const Color(0x14FFFFFF),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: result.perPage,
              isDense: true,
              dropdownColor: const Color(0xFF3A3A3A),
              borderRadius: BorderRadius.circular(10),
              icon: const Icon(Icons.keyboard_arrow_down_rounded,
                  size: 18, color: Color(0x99FFFFFF)),
              style: GoogleFonts.inter(fontSize: 12.5, color: Colors.white),
              items: [
                for (final n in kPerPageOptions)
                  DropdownMenuItem(value: n, child: Text('$n')),
              ],
              onChanged: (v) {
                if (v != null && v != result.perPage) onPerPageChanged(v);
              },
            ),
          ),
        ),
      ],
    );

    final navegacao = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _NavBtn(
          icon: Icons.chevron_left_rounded,
          tooltip: 'Página anterior',
          enabled: result.hasPrev,
          onTap: () => onPageChanged(result.page - 1),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            '${result.page} / ${result.pageCount}',
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
        _NavBtn(
          icon: Icons.chevron_right_rounded,
          tooltip: 'Próxima página',
          enabled: result.hasNext,
          onTap: () => onPageChanged(result.page + 1),
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: context.isStacked
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  resumo,
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [porPagina, navegacao],
                  ),
                ],
              )
            : Row(
                children: [
                  resumo,
                  const Spacer(),
                  porPagina,
                  const SizedBox(width: 18),
                  navegacao,
                ],
              ),
      ),
    );
  }
}

class _NavBtn extends StatelessWidget {
  const _NavBtn({
    required this.icon,
    required this.tooltip,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: enabled ? const Color(0x14FFFFFF) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: enabled ? onTap : null,
          child: SizedBox(
            width: 32,
            height: 30,
            child: Icon(
              icon,
              size: 20,
              color: enabled ? Colors.white : const Color(0x3DFFFFFF),
            ),
          ),
        ),
      ),
    );
  }
}
