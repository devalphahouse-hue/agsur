import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';

/// Multi-select de clientes (lê vw_get_clients).
/// Usado para vincular Oficina e Piloto a um ou mais clientes.
class ClientMultiSelectWidget extends StatefulWidget {
  const ClientMultiSelectWidget({
    super.key,
    required this.selectedIds,
    required this.onChanged,
    this.label = 'Clientes vinculados',
  });

  final Set<String> selectedIds;
  final ValueChanged<Set<String>> onChanged;
  final String label;

  @override
  State<ClientMultiSelectWidget> createState() =>
      _ClientMultiSelectWidgetState();
}

class _ClientMultiSelectWidgetState extends State<ClientMultiSelectWidget> {
  bool _loading = true;
  String? _error;
  String _filter = '';
  List<VwGetClientsRow> _clients = const [];

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
      final rows = await VwGetClientsTable().queryRows(
        queryFn: (q) => q.order('client_fullname'),
      );
      if (!mounted) return;
      setState(() {
        _clients = rows;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Não foi possível carregar a lista de clientes.';
        _loading = false;
      });
    }
  }

  void _toggle(String userId) {
    final next = Set<String>.from(widget.selectedIds);
    if (next.contains(userId)) {
      next.remove(userId);
    } else {
      next.add(userId);
    }
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    final filtered = _filter.trim().isEmpty
        ? _clients
        : _clients
            .where((c) =>
                (c.clientFullname ?? '')
                    .toLowerCase()
                    .contains(_filter.trim().toLowerCase()))
            .toList();

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
                Icon(Icons.people_outline,
                    size: 18, color: theme.primary),
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${widget.selectedIds.length} selecionado(s)',
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
              'Selecione os clientes que esta conta poderá atender. Pode ser mais de um.',
              style: GoogleFonts.roboto(
                fontSize: 11,
                color: const Color(0xCCFFFFFF),
              ),
            ),
            const SizedBox(height: 10),
            // busca
            TextField(
              onChanged: (v) => setState(() => _filter = v),
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Buscar por nome...',
                hintStyle:
                    const TextStyle(color: Color(0x99FFFFFF), fontSize: 12),
                prefixIcon: const Icon(Icons.search,
                    color: Color(0x99FFFFFF), size: 18),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                filled: true,
                fillColor: const Color(0x22FFFFFF),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide.none,
                ),
              ),
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
                            ? 'Nenhum cliente cadastrado.'
                            : 'Nenhum cliente corresponde à busca.',
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
                      final c = filtered[i];
                      final id = c.userId ?? '';
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
                                  onChanged: id.isEmpty
                                      ? null
                                      : (_) => _toggle(id),
                                  activeColor: theme.primary,
                                  visualDensity: VisualDensity.compact,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      c.clientFullname ?? '—',
                                      style: GoogleFonts.roboto(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    if ((c.companyName ?? '').isNotEmpty)
                                      Text(
                                        c.companyName!,
                                        style: GoogleFonts.roboto(
                                          color: const Color(0x99FFFFFF),
                                          fontSize: 11,
                                        ),
                                      ),
                                  ],
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
