import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';

import '/auth/supabase_auth/auth_util.dart';
import '/backend/api_requests/api_calls.dart';
import '/backend/schema/structs/index.dart';
import '/backend/supabase/supabase.dart';
import '/core_ui/core_ui.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/pages/modal_create_available_aircraft/modal_create_available_aircraft_widget.dart';
import '/pages/shared/alert_dialog/alert_dialog_widget.dart';
import 'available_aircrafts_model.dart';

export 'available_aircrafts_model.dart';

class AvailableAircraftsWidget extends StatefulWidget {
  const AvailableAircraftsWidget({super.key});

  static String routeName = 'AvailableAircrafts';
  static String routePath = '/availableAircrafts';

  @override
  State<AvailableAircraftsWidget> createState() =>
      _AvailableAircraftsWidgetState();
}

class _AvailableAircraftsWidgetState extends State<AvailableAircraftsWidget> {
  late AvailableAircraftsModel _model;
  String _query = '';
  bool _disposed = false;

  static const _statusOptions = ['Todos', 'Disponível', 'Vendido', 'Reservado'];

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AvailableAircraftsModel());
    _model.dPDEntryYearValue ??= DateTime.now().year.toString();
    _model.dPDStatusValue ??= 'Todos';

    SchedulerBinding.instance.addPostFrameCallback((_) async {
      try {
        final user = await QueryCache.fetch<List<UsersRow>>(
          key: 'aircrafts.currentUser:$currentUserUid',
          ttl: const Duration(minutes: 5),
          fetcher: () => UsersTable().queryRows(
            queryFn: (q) => q.eqOrNull('id', currentUserUid),
          ),
        );
        if (_disposed) return;
        _model.user = user;
        safeSetState(() {});
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _model.dispose();
    super.dispose();
  }

  bool get _isAdmin =>
      _model.user?.firstOrNull?.profileType == 'Admin Master';

  void _refresh() => safeSetState(() => _model.apiRequestCompleter = null);

  Future<void> _openCreate() async {
    await showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        elevation: 0,
        insetPadding: EdgeInsets.zero,
        backgroundColor: Colors.transparent,
        alignment: Alignment.center,
        child: GestureDetector(
          onTap: () {
            FocusScope.of(dialogContext).unfocus();
            FocusManager.instance.primaryFocus?.unfocus();
          },
          child: ModalCreateAvailableAircraftWidget(
            type: 'create',
            btnAction: (idAeronave, numeroSerie, dataFabricacao,
                prazoConfiguracao, dataEntrega, createdBy, anoBase, status,
                updateBy, id) async {
              await AvailableAircraftsTable().insert({
                'aircraft_model': idAeronave,
                'serial_number': numeroSerie,
                'manufacture_date': supaSerialize<DateTime>(dataFabricacao),
                'configuration_deadline':
                    supaSerialize<DateTime>(prazoConfiguracao),
                'delivery_date': supaSerialize<DateTime>(dataEntrega),
                'status': status,
                'created_by': createdBy,
                'update_by': createdBy,
                'entry_year': anoBase,
              });
              if (!mounted) return;
              _refresh();
              Navigator.of(dialogContext).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Aeronave cadastrada',
                    style: GoogleFonts.inter(color: const Color(0xFF313131)),
                  ),
                  backgroundColor: const Color(0xFFC2D51C),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _openEdit(ListAvailableAircraftsStruct item) async {
    await showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        elevation: 0,
        insetPadding: EdgeInsets.zero,
        backgroundColor: Colors.transparent,
        alignment: Alignment.center,
        child: GestureDetector(
          onTap: () {
            FocusScope.of(dialogContext).unfocus();
            FocusManager.instance.primaryFocus?.unfocus();
          },
          child: ModalCreateAvailableAircraftWidget(
            type: 'edit',
            id: item.id,
            btnAction: (idAeronave, numeroSerie, dataFabricacao,
                prazoConfiguracao, dataEntrega, createdBy, anoBase, status,
                updateBy, id) async {
              await AvailableAircraftsTable().update(
                data: {
                  'aircraft_model': idAeronave,
                  'serial_number': numeroSerie,
                  'manufacture_date': supaSerialize<DateTime>(dataFabricacao),
                  'configuration_deadline':
                      supaSerialize<DateTime>(prazoConfiguracao),
                  'delivery_date': supaSerialize<DateTime>(dataEntrega),
                  'status': status,
                  'update_by': updateBy,
                  'entry_year': anoBase,
                },
                matchingRows: (rows) => rows.eqOrNull('id', item.id),
              );
              if (!mounted) return;
              _refresh();
              Navigator.of(dialogContext).pop();
            },
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(ListAvailableAircraftsStruct item) async {
    await showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        elevation: 0,
        insetPadding: EdgeInsets.zero,
        backgroundColor: Colors.transparent,
        alignment: Alignment.center,
        child: GestureDetector(
          onTap: () {
            FocusScope.of(dialogContext).unfocus();
            FocusManager.instance.primaryFocus?.unfocus();
          },
          child: AlertDialogWidget(
            title: 'Deseja excluir esta aeronave?',
            iconColor: const Color(0xFFFF5963),
            btnColor: const Color(0xFFFF5963),
            confirmBtnAction: () async {
              await AvailableAircraftsTable().delete(
                matchingRows: (rows) => rows.eqOrNull('id', item.id),
              );
              if (!mounted) return;
              Navigator.of(dialogContext).pop();
              _refresh();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Aeronave excluída',
                    style: GoogleFonts.inter(color: const Color(0xFF313131)),
                  ),
                  backgroundColor: const Color(0xFFC2D51C),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final years = List<String>.generate(
      DateTime.now().year - 2018 + 2,
      (i) => (2018 + i).toString(),
    );

    return AppListScaffold(
      eyebrow: 'Operação',
      title: 'Estoque de aeronaves',
      description:
          'Cada item é uma unidade física disponível para venda. Filtre por ano e status.',
      actions: [
        if (_isAdmin)
          _PrimaryAction(
            icon: Icons.flight_outlined,
            label: 'Cadastrar aeronave',
            onTap: _openCreate,
          ),
      ],
      search: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          AppSearchInput(
            value: _query,
            placeholder: 'Buscar por modelo ou serial...',
            onChanged: (v) => setState(() => _query = v),
          ),
          _FilterChips(
            label: 'Ano',
            options: years,
            value: _model.dPDEntryYearValue ?? years.last,
            onChanged: (v) {
              safeSetState(() {
                _model.dPDEntryYearValue = v;
              });
              _refresh();
            },
          ),
          _FilterChips(
            label: 'Status',
            options: _statusOptions,
            value: _model.dPDStatusValue ?? 'Todos',
            onChanged: (v) {
              safeSetState(() {
                _model.dPDStatusValue = v;
              });
              _refresh();
            },
          ),
        ],
      ),
      body: FutureBuilder<ApiCallResponse>(
        future: (_model.apiRequestCompleter ??= Completer<ApiCallResponse>()
              ..complete(GetListAvailableAircraftsCall.call(
                pEntryYear: _model.dPDEntryYearValue,
                pStatus: _model.dPDStatusValue,
              )))
            .future,
        builder: (context, snap) {
          if (!snap.hasData) {
            return Column(
              children: List.generate(
                4,
                (_) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AppSkeleton.box(height: 96),
                ),
              ),
            );
          }
          final all = (snap.data!.jsonBody as List)
              .map<ListAvailableAircraftsStruct?>(
                  ListAvailableAircraftsStruct.maybeFromMap)
              .whereType<ListAvailableAircraftsStruct>()
              .toList();
          final list = _query.isEmpty
              ? all
              : all.where((a) {
                  final q = _query.toLowerCase();
                  return a.aircraftModel.toLowerCase().contains(q) ||
                      a.serialNumber.toLowerCase().contains(q);
                }).toList();
          if (list.isEmpty) {
            return AppCard(
              child: AppEmptyState(
                icon: Icons.warehouse_outlined,
                title: 'Nenhuma aeronave',
                description:
                    'Nenhuma unidade encontrada para os filtros atuais.',
              ),
            );
          }
          return Column(
            children: [
              for (int i = 0; i < list.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _AircraftRow(
                    item: list[i],
                    canManage: _isAdmin,
                    onTap: () => _openEdit(list[i]),
                    onDelete: () => _confirmDelete(list[i]),
                  ).appStagger(i),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _AircraftRow extends StatelessWidget {
  const _AircraftRow({
    required this.item,
    required this.canManage,
    required this.onTap,
    required this.onDelete,
  });

  final ListAvailableAircraftsStruct item;
  final bool canManage;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  AppStatusTone get _statusTone {
    final s = item.status.toLowerCase();
    if (s.contains('vendido')) return AppStatusTone.danger;
    if (s.contains('reserv')) return AppStatusTone.warning;
    if (s.contains('dispon')) return AppStatusTone.success;
    return AppStatusTone.brand;
  }

  @override
  Widget build(BuildContext context) {
    final hasPhoto = item.aircraftPhotoUrl.isNotEmpty;
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0x14FFFFFF),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: const Color(0x22FFFFFF)),
            ),
            clipBehavior: Clip.antiAlias,
            child: hasPhoto
                ? Image.network(
                    item.aircraftPhotoUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.flight_outlined,
                      color: Color(0xFFC2D51C),
                      size: 26,
                    ),
                  )
                : const Icon(
                    Icons.flight_outlined,
                    color: Color(0xFFC2D51C),
                    size: 26,
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.aircraftModel.isNotEmpty
                      ? item.aircraftModel
                      : 'Modelo não informado',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    if (item.serialNumber.isNotEmpty)
                      _Meta(Icons.tag_rounded, 'S/N ${item.serialNumber}'),
                    if (item.entryYear.isNotEmpty)
                      _Meta(Icons.event_outlined, 'Ano ${item.entryYear}'),
                    if (item.deliveryDate.isNotEmpty)
                      _Meta(Icons.flight_takeoff_rounded,
                          _shortDate(item.deliveryDate)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              AppStatusBadge(
                label: item.status.isEmpty ? '—' : item.status,
                tone: _statusTone,
                dense: true,
              ),
              if (canManage) ...[
                const SizedBox(height: 8),
                AppRowAction(
                  icon: Icons.delete_outline_rounded,
                  tooltip: 'Excluir',
                  danger: true,
                  onPressed: onDelete,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _shortDate(String iso) {
    try {
      final d = DateTime.parse(iso);
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    } catch (_) {
      return iso;
    }
  }
}

class _Meta extends StatelessWidget {
  const _Meta(this.icon, this.text);
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: const Color(0x99FFFFFF)),
        const SizedBox(width: 4),
        Text(
          text,
          style: GoogleFonts.roboto(
            fontSize: 11.5,
            color: const Color(0x99FFFFFF),
          ),
        ),
      ],
    );
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({
    required this.label,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final List<String> options;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0x14FFFFFF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0x22FFFFFF)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label:',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: const Color(0x99FFFFFF),
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(width: 8),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isDense: true,
              dropdownColor: const Color(0xFF2A2A2A),
              icon: const Icon(Icons.expand_more_rounded,
                  color: Color(0xFFC2D51C), size: 18),
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              items: [
                for (final opt in options)
                  DropdownMenuItem(value: opt, child: Text(opt)),
              ],
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryAction extends StatefulWidget {
  const _PrimaryAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  State<_PrimaryAction> createState() => _PrimaryActionState();
}

class _PrimaryActionState extends State<_PrimaryAction> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFC2D51C), Color(0xFFAEC117)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFC2D51C)
                    .withValues(alpha: _hover ? 0.45 : 0.25),
                blurRadius: _hover ? 18 : 10,
                spreadRadius: -2,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 16, color: const Color(0xFF313131)),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF313131),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
