import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/backend/supabase/supabase.dart';
import '/core_ui/core_ui.dart';
import '/pages/shared/client_multi_select/client_multi_select_widget.dart';

/// Section reusável que lista clientes vinculados a um usuário da app
/// (Oficina ou Piloto) e permite gerenciar esses vínculos.
///
/// Genérica por design: recebe o nome da tabela pivot e o nome da coluna
/// pivot (ex.: `oficina_clients` + `oficina_id`, ou `pilot_clients` +
/// `pilot_id`). A coluna do cliente é sempre `client_id`.
class LinkedClientsSection extends StatefulWidget {
  const LinkedClientsSection({
    super.key,
    required this.ownerId,
    required this.pivotTable,
    required this.ownerColumn,
    this.title = 'Clientes vinculados',
    this.subtitle = 'Aeronaves dos clientes vinculados ficam acessíveis no app.',
    this.editable = true,
  });

  /// ID do dono do vínculo (oficina ou piloto = users.id).
  final String ownerId;

  /// Nome da tabela pivot no Supabase: 'oficina_clients' / 'pilot_clients'.
  final String pivotTable;

  /// Coluna que aponta pro dono do vínculo: 'oficina_id' / 'pilot_id'.
  final String ownerColumn;

  final String title;
  final String subtitle;
  final bool editable;

  @override
  State<LinkedClientsSection> createState() => _LinkedClientsSectionState();
}

class _LinkedClientsSectionState extends State<LinkedClientsSection> {
  bool _loading = true;
  String? _error;
  bool _saving = false;

  /// Mapa client_id → snapshot do cliente.
  Map<String, VwGetClientsRow> _clientsById = const {};

  /// Conjunto atual de client_ids vinculados.
  Set<String> _linked = {};

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
      final pivot = await SupaFlow.client
          .from(widget.pivotTable)
          .select('client_id')
          .eq(widget.ownerColumn, widget.ownerId);

      final ids = (pivot as List)
          .map((e) => (e as Map)['client_id'] as String?)
          .whereType<String>()
          .toSet();

      Map<String, VwGetClientsRow> byId = {};
      if (ids.isNotEmpty) {
        final rows = await VwGetClientsTable().queryRows(
          queryFn: (q) => q.inFilter('user_id', ids.toList()),
        );
        byId = {for (final r in rows) r.userId ?? '': r}
          ..removeWhere((k, _) => k.isEmpty);
      }

      if (!mounted) return;
      setState(() {
        _linked = ids;
        _clientsById = byId;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Não foi possível carregar os clientes vinculados.';
        _loading = false;
      });
    }
  }

  Future<void> _openEditor() async {
    if (_saving) return;
    final initial = Set<String>.from(_linked);

    final result = await showDialog<Set<String>>(
      context: context,
      builder: (ctx) => Dialog(
        elevation: 0,
        insetPadding: EdgeInsets.zero,
        backgroundColor: Colors.transparent,
        alignment: Alignment.center,
        child: _MultiSelectDialog(initial: initial),
      ),
    );

    if (result == null || !mounted) return;
    final added = result.difference(initial);
    final removed = initial.difference(result);
    if (added.isEmpty && removed.isEmpty) return;

    setState(() => _saving = true);
    try {
      for (final cid in added) {
        await SupaFlow.client.from(widget.pivotTable).insert({
          widget.ownerColumn: widget.ownerId,
          'client_id': cid,
        });
      }
      for (final cid in removed) {
        await SupaFlow.client
            .from(widget.pivotTable)
            .delete()
            .eq(widget.ownerColumn, widget.ownerId)
            .eq('client_id', cid);
      }
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Vínculos atualizados (${added.length} adicionado(s), ${removed.length} removido(s)).',
            style: GoogleFonts.inter(color: const Color(0xFF313131)),
          ),
          backgroundColor: const Color(0xFFC2D51C),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro ao salvar vínculos. Tente novamente.'),
          backgroundColor: Color(0xFFFF5963),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      icon: Icons.groups_outlined,
      title: widget.title,
      subtitle: widget.subtitle,
      actions: [
        if (widget.editable)
          AppSecondaryButton(
            label: _linked.isEmpty ? 'Vincular' : 'Editar',
            icon: Icons.edit_outlined,
            onPressed: _saving ? null : _openEditor,
          ),
      ],
      child: Builder(
        builder: (_) {
          if (_loading) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFFC2D51C),
                  ),
                ),
              ),
            );
          }
          if (_error != null) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Text(
                _error!,
                style: GoogleFonts.roboto(
                  fontSize: 12.5,
                  color: const Color(0xFFFF7B82),
                ),
              ),
            );
          }
          if (_linked.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: Colors.white.withValues(alpha: 0.45),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Nenhum cliente vinculado. ${widget.editable ? "Use o botão acima para vincular." : ""}',
                      style: GoogleFonts.roboto(
                        fontSize: 12.5,
                        color: const Color(0x99FFFFFF),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final cid in _linked)
                _ClientChip(client: _clientsById[cid], id: cid),
            ],
          );
        },
      ),
    );
  }
}

class _ClientChip extends StatelessWidget {
  const _ClientChip({required this.client, required this.id});

  final VwGetClientsRow? client;
  final String id;

  @override
  Widget build(BuildContext context) {
    final name = client?.clientFullname?.trim().isNotEmpty == true
        ? client!.clientFullname!
        : 'Cliente #${id.substring(0, id.length.clamp(0, 6))}';
    final initials = name
        .split(' ')
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0])
        .join()
        .toUpperCase();
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 6, 12, 6),
      decoration: BoxDecoration(
        color: const Color(0x14FFFFFF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0x33C2D51C)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: const Color(0x33C2D51C),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              initials.isNotEmpty ? initials : '·',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: const Color(0xFFC2D51C),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            name,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.92),
            ),
          ),
        ],
      ),
    );
  }
}

class _MultiSelectDialog extends StatefulWidget {
  const _MultiSelectDialog({required this.initial});

  final Set<String> initial;

  @override
  State<_MultiSelectDialog> createState() => _MultiSelectDialogState();
}

class _MultiSelectDialogState extends State<_MultiSelectDialog> {
  late Set<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = Set<String>.from(widget.initial);
  }

  @override
  Widget build(BuildContext context) {
    return AppModal(
      icon: Icons.groups_outlined,
      title: 'Editar clientes vinculados',
      description:
          'Selecione os clientes que devem ficar acessíveis para este usuário.',
      maxWidth: 640,
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          AppSecondaryButton(
            label: 'Cancelar',
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 10),
          AppPrimaryButton(
            label: 'Salvar vínculos',
            icon: Icons.check_rounded,
            onPressed: () => Navigator.of(context).pop(_selected),
          ),
        ],
      ),
      child: ClientMultiSelectWidget(
        selectedIds: _selected,
        onChanged: (ids) => setState(() => _selected = ids),
      ),
    );
  }
}
