import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';

/// Multi-select de aeronaves (lê vw_aircraft_options).
/// Usado para vincular o Piloto a uma, várias ou todas as aeronaves.
class AircraftMultiSelectWidget extends StatefulWidget {
  const AircraftMultiSelectWidget({
    super.key,
    required this.selectedIds,
    required this.onChanged,
    this.label = 'Aeronaves vinculadas',
  });

  final Set<String> selectedIds;
  final ValueChanged<Set<String>> onChanged;
  final String label;

  @override
  State<AircraftMultiSelectWidget> createState() =>
      _AircraftMultiSelectWidgetState();
}

class _AircraftMultiSelectWidgetState extends State<AircraftMultiSelectWidget> {
  bool _loading = true;
  String? _error;
  String _filter = '';
  List<VwAircraftOptionsRow> _aircrafts = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = await VwAircraftOptionsTable().queryRows(
        queryFn: (q) => q.order('aircraft_model'),
      );
      if (!mounted) return;
      setState(() {
        _aircrafts = rows;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Não foi possível carregar a lista de aeronaves.';
        _loading = false;
      });
    }
  }

  void _toggle(String id) {
    final next = Set<String>.from(widget.selectedIds);
    if (next.contains(id)) {
      next.remove(id);
    } else {
      next.add(id);
    }
    widget.onChanged(next);
  }

  /// IDs válidos (não vazios) de todas as aeronaves carregadas.
  Set<String> get _allIds => _aircrafts
      .map((a) => a.aircraftId ?? '')
      .where((id) => id.isNotEmpty)
      .toSet();

  void _toggleAll() {
    final all = _allIds;
    final allSelected =
        all.isNotEmpty && all.every(widget.selectedIds.contains);
    widget.onChanged(allSelected ? <String>{} : all);
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    final filtered = _filter.trim().isEmpty
        ? _aircrafts
        : _aircrafts.where((a) {
            final q = _filter.trim().toLowerCase();
            return (a.aircraftModel ?? '').toLowerCase().contains(q);
          }).toList();

    final all = _allIds;
    final allSelected =
        all.isNotEmpty && all.every(widget.selectedIds.contains);

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(0, 12, 0, 0),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0x33000000),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0x33FFFFFF), width: 1),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.flight_outlined, size: 18, color: theme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.label,
                    style: GoogleFonts.roboto(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      fontSize: 13,
                    ),
                  ),
                ),
                if (widget.selectedIds.isNotEmpty)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${widget.selectedIds.length} selecionada(s)',
                      style: GoogleFonts.roboto(
                        fontSize: 11,
                        color: theme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Selecione as aeronaves que este piloto poderá acessar. Pode marcar uma, várias ou todas.',
              style: GoogleFonts.roboto(
                fontSize: 11,
                color: const Color(0xCCFFFFFF),
              ),
            ),
            const SizedBox(height: 10),
            // busca + marcar todas
            Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (v) => setState(() => _filter = v),
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'Buscar por modelo...',
                      hintStyle: const TextStyle(
                          color: Color(0x99FFFFFF), fontSize: 12),
                      prefixIcon: const Icon(Icons.search,
                          color: Color(0x99FFFFFF), size: 18),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 8),
                      filled: true,
                      fillColor: const Color(0x22FFFFFF),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: all.isEmpty ? null : _toggleAll,
                  icon: Icon(
                    allSelected
                        ? Icons.remove_done_rounded
                        : Icons.done_all_rounded,
                    size: 18,
                  ),
                  label: Text(allSelected ? 'Limpar' : 'Marcar todas'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220, minHeight: 80),
              child: Builder(
                builder: (_) {
                  if (_loading) {
                    return const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  }
                  if (_error != null) {
                    return Center(
                      child: Text(
                        _error!,
                        style: const TextStyle(
                            color: Color(0xFFFF5963), fontSize: 12),
                      ),
                    );
                  }
                  if (filtered.isEmpty) {
                    return Center(
                      child: Text(
                        _filter.isEmpty
                            ? 'Nenhuma aeronave cadastrada.'
                            : 'Nenhuma aeronave corresponde à busca.',
                        style: const TextStyle(
                            color: Color(0x99FFFFFF), fontSize: 12),
                      ),
                    );
                  }
                  return ListView.separated(
                    shrinkWrap: true,
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const Divider(
                      height: 1,
                      thickness: 1,
                      color: Color(0x14FFFFFF),
                    ),
                    itemBuilder: (_, i) {
                      final a = filtered[i];
                      final id = a.aircraftId ?? '';
                      final selected = widget.selectedIds.contains(id);
                      return InkWell(
                        onTap: id.isEmpty ? null : () => _toggle(id),
                        borderRadius: BorderRadius.circular(6),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 4),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 18,
                                height: 18,
                                child: Checkbox(
                                  value: selected,
                                  onChanged:
                                      id.isEmpty ? null : (_) => _toggle(id),
                                  activeColor: theme.primary,
                                  visualDensity: VisualDensity.compact,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  a.aircraftModel ?? '—',
                                  style: GoogleFonts.roboto(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
