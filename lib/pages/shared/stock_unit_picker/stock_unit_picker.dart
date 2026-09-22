import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '/backend/stock.dart';
import '/backend/supabase/supabase.dart';
import '/core_ui/core_ui.dart';

// Escolha de aeronave do estoque na proposta e no contrato (migration
// 20260922120000). Widgets próprios, fora do código gerado pelo FlutterFlow.
//
// Regra: só aparece como escolhível a unidade que está NO estoque e SEM
// contrato ativo (`isStockUnitSellable`). O banco é o backstop — a trigger
// da proposta recusa modelo diferente ou unidade fora do estoque, e a do
// contrato recusa converter com unidade que já saiu.

/// Unidades do estoque, cacheadas por pouco tempo: o seletor abre várias
/// vezes na mesma tela e o dado muda só com entrada/saída.
Future<List<VwStockUnitsRow>> loadStockUnits({bool fresh = false}) {
  const key = 'stock.units';
  if (fresh) QueryCache.invalidate(key);
  return QueryCache.fetch<List<VwStockUnitsRow>>(
    key: key,
    ttl: const Duration(minutes: 1),
    fetcher: () => VwStockUnitsTable().queryRows(queryFn: (q) => q),
  );
}

/// Quantas unidades vendáveis cada modelo tem agora (id do catálogo → n).
Future<Map<String, int>> loadSellableCountByModel() async {
  final units = await loadStockUnits();
  final map = <String, int>{};
  for (final u in units) {
    if (isStockUnitSellable(
        inStock: u.inStock,
        hasActiveContract: u.contractId != null,
        status: u.status)) {
      map[u.aircraftId] = (map[u.aircraftId] ?? 0) + 1;
    }
  }
  return map;
}

// ── Filtro rápido do seletor de modelo ─────────────────────────────────────

enum AircraftQuickFilter { todos, destaque, disponiveis }

/// Aplica o filtro rápido à lista do catálogo. [keepId] continua na lista
/// mesmo fora do filtro — o dropdown não pode perder o valor já escolhido.
List<AircraftsRow> applyAircraftQuickFilter(
  List<AircraftsRow> all,
  AircraftQuickFilter filter,
  Map<String, int> sellable, {
  String? keepId,
}) {
  final list = all.where((a) {
    if (a.id == keepId) return true;
    return switch (filter) {
      AircraftQuickFilter.todos => true,
      AircraftQuickFilter.destaque => a.featured,
      AircraftQuickFilter.disponiveis => (sellable[a.id] ?? 0) > 0,
    };
  }).toList();
  // Destaques no topo em qualquer filtro.
  list.sort((a, b) {
    if (a.featured != b.featured) return a.featured ? -1 : 1;
    return a.aircraftModel.toLowerCase().compareTo(b.aircraftModel.toLowerCase());
  });
  return list;
}

/// Rótulo do modelo no dropdown: ★ para destaque e a quantidade vendável.
String aircraftOptionLabel(AircraftsRow a, Map<String, int> sellable) {
  final n = sellable[a.id] ?? 0;
  final star = a.featured ? '★ ' : '';
  return n > 0 ? '$star${a.aircraftModel} · $n em estoque' : '$star${a.aircraftModel}';
}

class AircraftQuickFilterChips extends StatelessWidget {
  const AircraftQuickFilterChips({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final AircraftQuickFilter value;
  final ValueChanged<AircraftQuickFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    const labels = {
      AircraftQuickFilter.todos: 'Todos',
      AircraftQuickFilter.destaque: '★ Em destaque',
      AircraftQuickFilter.disponiveis: 'Disponíveis no estoque',
    };
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final e in labels.entries)
          _Chip(
            label: e.value,
            selected: e.key == value,
            onTap: () => onChanged(e.key),
          ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFC2D51C) : const Color(0x14FFFFFF),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? const Color(0xFFC2D51C) : const Color(0x33FFFFFF),
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: selected ? const Color(0xFF313131) : const Color(0xCCFFFFFF),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Modal de escolha ───────────────────────────────────────────────────────

/// Lista as aeronaves do estoque para escolher uma. Com [aircraftId], só as
/// daquele modelo (é o caso da proposta com modelo já escolhido e do
/// contrato). Devolve a unidade escolhida.
class StockUnitPickerModal extends StatefulWidget {
  const StockUnitPickerModal({
    super.key,
    this.aircraftId,
    this.currentUnitId,
    this.title = 'Escolher aeronave do estoque',
    this.description,
  });

  final String? aircraftId;
  final String? currentUnitId;
  final String title;
  final String? description;

  @override
  State<StockUnitPickerModal> createState() => _StockUnitPickerModalState();
}

class _StockUnitPickerModalState extends State<StockUnitPickerModal> {
  late final Future<List<VwStockUnitsRow>> _units = _load();
  String _query = '';
  bool _onlyFeatured = false;

  Future<List<VwStockUnitsRow>> _load() async {
    try {
      // Fresco: escolher unidade que acabou de sair do estoque só daria erro
      // no banco depois.
      final all = await loadStockUnits(fresh: true);
      // Modelo que saiu do catálogo não se vende mais: a aeronave dele não
      // pode ir para proposta/contrato (o seletor de modelo da proposta nem o
      // lista, e escolher por aqui quebrava o fluxo — QA de 2026-09-22).
      final modelIds = all.map((u) => u.aircraftId).toSet().toList();
      final removed = modelIds.isEmpty
          ? <String>{}
          : (await AircraftsTable().queryRows(
              queryFn: (q) => q.inFilter('id', modelIds).eq('deleted', true),
            ))
              .map((a) => a.id)
              .toSet();
      return all
          .where((u) =>
              (widget.aircraftId == null || u.aircraftId == widget.aircraftId) &&
              (u.id == widget.currentUnitId ||
                  (u.inStock &&
                      !removed.contains(u.aircraftId) &&
                      // Reunião de 2026-09-22: a proposta escolhe aeronave
                      // Disponível ou Em negociação. Reservado fica de fora.
                      isStockUnitSellable(
                          inStock: true,
                          hasActiveContract: u.contractId != null,
                          status: u.status))))
          .toList()
        ..sort((a, b) {
          if (a.featured != b.featured) return a.featured ? -1 : 1;
          final m = a.aircraftModelName.compareTo(b.aircraftModelName);
          return m != 0 ? m : a.serialNumber.compareTo(b.serialNumber);
        });
    } catch (e, st) {
      Sentry.captureException(e,
          stackTrace: st, withScope: (s) => s.setTag('acao', 'estoque.picker'));
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppModal(
      icon: Icons.flight_takeoff_rounded,
      title: widget.title,
      description: widget.description ??
          'Aparecem as aeronaves em estoque com status Disponível ou Em '
              'negociação. As que estão em contrato ativo aparecem bloqueadas.',
      maxWidth: 640,
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          AppSecondaryButton(
            label: 'Cancelar',
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ],
      ),
      child: FutureBuilder<List<VwStockUnitsRow>>(
        future: _units,
        builder: (context, snap) {
          if (snap.hasError) {
            return const AppEmptyState(
              icon: Icons.error_outline_rounded,
              title: 'Não foi possível carregar o estoque',
              compact: true,
            );
          }
          final q = _query.trim().toLowerCase();
          final visible = (snap.data ?? [])
              .where((u) =>
                  (!_onlyFeatured || u.featured) &&
                  (q.isEmpty ||
                      u.aircraftModelName.toLowerCase().contains(q) ||
                      u.serialNumber.toLowerCase().contains(q) ||
                      (u.registrationPrefix ?? '').toLowerCase().contains(q)))
              .toList();
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  AppSearchInput(
                    value: _query,
                    placeholder: 'Buscar por modelo, serial ou prefixo...',
                    width: 320,
                    onChanged: (v) => setState(() => _query = v),
                  ),
                  if (widget.aircraftId == null)
                    _Chip(
                      label: '★ Só destaques',
                      selected: _onlyFeatured,
                      onTap: () => setState(() => _onlyFeatured = !_onlyFeatured),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (!snap.hasData)
                Column(
                  children: List.generate(
                    3,
                    (_) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: AppSkeleton.box(height: 56),
                    ),
                  ),
                )
              else if (visible.isEmpty)
                AppEmptyState(
                  icon: Icons.flight_outlined,
                  title: 'Nenhuma aeronave disponível',
                  description: widget.aircraftId != null
                      ? 'Não há aeronave deste modelo no estoque.'
                      : null,
                  compact: true,
                )
              else
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 380),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: visible.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) => _tile(visible[i]),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _tile(VwStockUnitsRow u) {
    final isCurrent = u.id == widget.currentUnitId;
    final blocked = !isCurrent &&
        !isStockUnitSellable(
            inStock: u.inStock,
            hasActiveContract: u.contractId != null,
            status: u.status);
    return Opacity(
      opacity: blocked ? 0.45 : 1,
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        onTap: (blocked || isCurrent) ? null : () => Navigator.of(context).pop(u),
        child: Row(
          children: [
            Icon(
              blocked
                  ? Icons.lock_outline_rounded
                  : u.featured
                      ? Icons.star_rounded
                      : Icons.flight_outlined,
              color: blocked
                  ? const Color(0x99FFFFFF)
                  : u.featured
                      ? const Color(0xFFFFC857)
                      : const Color(0xFFC2D51C),
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    u.aircraftModelName.isEmpty
                        ? 'Modelo não informado'
                        : u.aircraftModelName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      'S/N ${u.serialNumber}',
                      if ((u.registrationPrefix ?? '').isNotEmpty)
                        u.registrationPrefix!,
                      if (u.manufactureDate != null)
                        'Fab. ${u.manufactureDate!.year}',
                      if (isCurrent) 'escolhida',
                      if (blocked) 'em outro contrato ativo',
                    ].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      color: const Color(0xB3FFFFFF),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            AppStatusBadge(
              label: u.status.isEmpty ? '—' : u.status,
              tone: u.status.toLowerCase().contains('negocia') ||
                      u.status.toLowerCase().contains('reserv')
                  ? AppStatusTone.warning
                  : AppStatusTone.success,
              dense: true,
            ),
          ],
        ),
      ),
    );
  }
}

Future<VwStockUnitsRow?> pickStockUnit(
  BuildContext context, {
  String? aircraftId,
  String? currentUnitId,
  String? title,
  String? description,
}) {
  return showDialog<VwStockUnitsRow>(
    context: context,
    builder: (_) => Dialog(
      elevation: 0,
      insetPadding: EdgeInsets.zero,
      backgroundColor: Colors.transparent,
      alignment: Alignment.center,
      child: StockUnitPickerModal(
        aircraftId: aircraftId,
        currentUnitId: currentUnitId,
        title: title ?? 'Escolher aeronave do estoque',
        description: description,
      ),
    ),
  );
}

// ── Campo "Aeronave do estoque" (proposta) ─────────────────────────────────

/// Mostra a unidade escolhida (ou o botão para escolher). Não grava nada:
/// quem usa decide quando persistir.
class StockUnitField extends StatelessWidget {
  const StockUnitField({
    super.key,
    required this.unit,
    required this.onPick,
    required this.onClear,
    this.enabled = true,
    this.emptyText =
        'Opcional — escolha a aeronave do estoque para esta proposta. '
            'Ela sai do estoque quando a proposta virar contrato.',
  });

  final VwStockUnitsRow? unit;
  final VoidCallback onPick;
  final VoidCallback onClear;
  final bool enabled;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    final u = unit;
    if (u == null) {
      return Wrap(
        spacing: 12,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Text(
              emptyText,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                color: const Color(0xB3FFFFFF),
              ),
            ),
          ),
          if (enabled)
            AppSecondaryButton(
              label: 'Escolher do estoque',
              icon: Icons.add_link_rounded,
              onPressed: onPick,
            ),
        ],
      );
    }
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(u.featured ? Icons.star_rounded : Icons.flight_takeoff_rounded,
              color: u.featured
                  ? const Color(0xFFFFC857)
                  : const Color(0xFFC2D51C),
              size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  u.aircraftModelName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    'S/N ${u.serialNumber}',
                    (u.registrationPrefix ?? '').isNotEmpty
                        ? 'Prefixo ${u.registrationPrefix}'
                        : 'Prefixo a definir',
                    if (u.manufactureDate != null)
                      'Fab. ${u.manufactureDate!.year}',
                  ].join(' · '),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xB3FFFFFF),
                  ),
                ),
              ],
            ),
          ),
          if (enabled) ...[
            AppRowAction(
              icon: Icons.swap_horiz_rounded,
              tooltip: 'Trocar aeronave',
              onPressed: onPick,
            ),
            const SizedBox(width: 4),
            AppRowAction(
              icon: Icons.link_off_rounded,
              tooltip: 'Remover escolha',
              danger: true,
              onPressed: onClear,
            ),
          ],
        ],
      ),
    );
  }
}
