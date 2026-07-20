import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_card.dart';
import 'app_responsive.dart';

/// Espaço entre colunas. Sem ele os rótulos do cabeçalho encostam e colam
/// ("VALORSTATUS") quando duas colunas estreitas ficam lado a lado.
const double kCellGap = 12;

/// Uma coluna da [AppDataTable].
///
/// `flex` divide a largura disponível (como `Expanded`); use `width` para
/// colunas de tamanho fixo (status, ações). Só um dos dois.
class AppDataColumn<T> {
  const AppDataColumn({
    required this.label,
    required this.cell,
    this.flex = 1,
    this.width,
    this.align = Alignment.centerLeft,
  });

  final String label;
  final Widget Function(T item) cell;
  final int flex;
  final double? width;
  final Alignment align;
}

/// Tabela do painel com colunas, seleção múltipla e ação em lote.
///
/// Responsividade: abaixo de [kStackBreakpoint] a tabela rola na horizontal
/// dentro do próprio container (largura mínima [minWidth]) — a página nunca
/// rola lateralmente. O cabeçalho rola junto com o corpo, então as colunas
/// continuam alinhadas.
///
/// Seleção: quando [onSelectionChanged] é passado, aparece a coluna de
/// checkbox e a barra de ação em lote. Sem ela, a tabela é só leitura.
class AppDataTable<T> extends StatelessWidget {
  const AppDataTable({
    super.key,
    required this.items,
    required this.columns,
    required this.rowId,
    this.onRowTap,
    this.selectedIds,
    this.onSelectionChanged,
    this.bulkActionLabel = 'Excluir selecionados',
    this.onBulkAction,
    this.minWidth = 720,
    this.isSelectable,
  });

  final List<T> items;
  final List<AppDataColumn<T>> columns;
  final String Function(T item) rowId;
  final void Function(T item)? onRowTap;

  final Set<String>? selectedIds;
  final void Function(Set<String> ids)? onSelectionChanged;
  final String bulkActionLabel;
  final Future<void> Function(Set<String> ids)? onBulkAction;

  final double minWidth;

  /// Linhas que não podem ser selecionadas (checkbox desabilitado). Use para
  /// proteger registros cuja exclusão teria efeito colateral.
  final bool Function(T item)? isSelectable;

  bool get _selectionEnabled => onSelectionChanged != null;

  Set<String> get _selected => selectedIds ?? const {};

  List<T> get _selectableItems =>
      isSelectable == null ? items : items.where(isSelectable!).toList();

  bool get _allSelected =>
      _selectableItems.isNotEmpty &&
      _selectableItems.every((i) => _selected.contains(rowId(i)));

  void _toggleAll() {
    final next = Set<String>.from(_selected);
    if (_allSelected) {
      for (final i in _selectableItems) {
        next.remove(rowId(i));
      }
    } else {
      for (final i in _selectableItems) {
        next.add(rowId(i));
      }
    }
    onSelectionChanged!(next);
  }

  void _toggleOne(T item) {
    final id = rowId(item);
    final next = Set<String>.from(_selected);
    next.contains(id) ? next.remove(id) : next.add(id);
    onSelectionChanged!(next);
  }

  @override
  Widget build(BuildContext context) {
    final table = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _header(context),
        for (int i = 0; i < items.length; i++) _row(context, items[i], i),
      ],
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_selectionEnabled && _selected.isNotEmpty) _bulkBar(context),
        AppCard(
          padding: EdgeInsets.zero,
          child: context.isStacked
              ? SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: minWidth),
                    child: SizedBox(width: minWidth, child: table),
                  ),
                )
              : table,
        ),
      ],
    );
  }

  Widget _bulkBar(BuildContext context) {
    final n = _selected.length;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(Icons.check_circle_outline_rounded,
                size: 18, color: const Color(0xFFC2D51C)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                n == 1 ? '1 item selecionado' : '$n itens selecionados',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            TextButton(
              onPressed: () => onSelectionChanged!(<String>{}),
              child: Text(
                'Limpar',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  color: const Color(0xCCFFFFFF),
                ),
              ),
            ),
            const SizedBox(width: 4),
            if (onBulkAction != null)
              TextButton.icon(
                onPressed: () => onBulkAction!(Set<String>.from(_selected)),
                icon: const Icon(Icons.delete_outline_rounded,
                    size: 17, color: Color(0xFFFF7B82)),
                label: Text(
                  bulkActionLabel,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFFF7B82),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0x1AFFFFFF))),
      ),
      child: Row(
        children: [
          if (_selectionEnabled) ...[
            SizedBox(
              width: 28,
              child: Checkbox(
                value: _allSelected,
                tristate: false,
                onChanged: _selectableItems.isEmpty ? null : (_) => _toggleAll(),
                side: const BorderSide(color: Color(0x66FFFFFF), width: 1.4),
                activeColor: const Color(0xFFC2D51C),
                checkColor: const Color(0xFF313131),
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            const SizedBox(width: 8),
          ],
          for (int i = 0; i < columns.length; i++) ...[
            if (i > 0) const SizedBox(width: kCellGap),
            _headerCell(columns[i]),
          ],
        ],
      ),
    );
  }

  Widget _headerCell(AppDataColumn<T> c) {
    final text = Align(
      alignment: c.align,
      child: Text(
        c.label.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          color: const Color(0x8AFFFFFF),
        ),
      ),
    );
    return c.width != null
        ? SizedBox(width: c.width, child: text)
        : Expanded(flex: c.flex, child: text);
  }

  Widget _row(BuildContext context, T item, int index) {
    final id = rowId(item);
    final selected = _selected.contains(id);
    final selectable = isSelectable?.call(item) ?? true;

    return _HoverRow(
      selected: selected,
      onTap: onRowTap == null ? null : () => onRowTap!(item),
      isLast: index == items.length - 1,
      child: Row(
        children: [
          if (_selectionEnabled) ...[
            SizedBox(
              width: 28,
              child: Checkbox(
                value: selected,
                onChanged: selectable ? (_) => _toggleOne(item) : null,
                side: BorderSide(
                  color: selectable
                      ? const Color(0x66FFFFFF)
                      : const Color(0x22FFFFFF),
                  width: 1.4,
                ),
                activeColor: const Color(0xFFC2D51C),
                checkColor: const Color(0xFF313131),
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            const SizedBox(width: 8),
          ],
          for (int i = 0; i < columns.length; i++) ...[
            if (i > 0) const SizedBox(width: kCellGap),
            if (columns[i].width != null)
              SizedBox(
                width: columns[i].width,
                child: Align(
                  alignment: columns[i].align,
                  child: columns[i].cell(item),
                ),
              )
            else
              Expanded(
                flex: columns[i].flex,
                child: Align(
                  alignment: columns[i].align,
                  child: columns[i].cell(item),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _HoverRow extends StatefulWidget {
  const _HoverRow({
    required this.child,
    required this.selected,
    required this.isLast,
    this.onTap,
  });

  final Widget child;
  final bool selected;
  final bool isLast;
  final VoidCallback? onTap;

  @override
  State<_HoverRow> createState() => _HoverRowState();
}

class _HoverRowState extends State<_HoverRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.onTap == null
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 110),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            color: widget.selected
                ? const Color(0x1FC2D51C)
                : _hover
                    ? const Color(0x0DFFFFFF)
                    : Colors.transparent,
            border: widget.isLast
                ? null
                : const Border(
                    bottom: BorderSide(color: Color(0x14FFFFFF)),
                  ),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

/// Texto padrão de célula (uma linha, com ellipsis).
class AppCellText extends StatelessWidget {
  const AppCellText(
    this.text, {
    super.key,
    this.bold = false,
    this.muted = false,
  });

  final String text;
  final bool bold;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
        color: muted ? const Color(0xB3FFFFFF) : Colors.white,
      ),
    );
  }
}
