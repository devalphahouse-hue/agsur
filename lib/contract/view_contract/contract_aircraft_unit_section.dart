import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '/backend/supabase/supabase.dart';
import '/core_ui/core_ui.dart';
import '/security/action_feedback.dart';
import '/security/write_guard.dart';

/// Seção "Aeronave do estoque" da tela de contrato.
///
/// Vínculo contrato ↔ unidade física de `available_aircrafts` (pedido do
/// cliente, 2026-07-21: "abre uma lista de aeronaves e coloca pra ele").
/// Grava em `contract.available_aircraft_id` (migration 20260722130000);
/// o banco garante uma unidade por contrato ativo via índice único parcial.
///
/// Regras de exibição:
///  * Sem contrato (proposta ainda não convertida) → a seção não aparece:
///    o vínculo é da VENDA, não da proposta.
///  * `canEdit` (typeAccess == 'edit', i.e. AccessControl.canEditFunil) libera
///    vincular/trocar/remover; os demais perfis só visualizam. A RLS
///    (`contract_write_seller`) + trigger de nível são o guarda real.
class ContractAircraftUnitSection extends StatefulWidget {
  const ContractAircraftUnitSection({
    super.key,
    required this.proposalId,
    required this.canEdit,
  });

  final String proposalId;
  final bool canEdit;

  @override
  State<ContractAircraftUnitSection> createState() =>
      _ContractAircraftUnitSectionState();
}

class _ContractAircraftUnitSectionState
    extends State<ContractAircraftUnitSection> {
  ContractRow? _contract;
  AvailableAircraftsRow? _unit;
  String? _unitModelName;
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final contracts = await ContractTable().queryRows(
        queryFn: (q) => q.eqOrNull('proposal_id', widget.proposalId),
      );
      final contract = contracts.firstOrNull;
      AvailableAircraftsRow? unit;
      String? modelName;
      final unitId = contract?.availableAircraftId;
      if (unitId != null && unitId.isNotEmpty) {
        final units = await AvailableAircraftsTable().queryRows(
          queryFn: (q) => q.eqOrNull('id', unitId),
        );
        unit = units.firstOrNull;
        if (unit != null) {
          modelName = await _resolveModelName(unit.aircraftModel);
        }
      }
      if (!mounted) return;
      setState(() {
        _contract = contract;
        _unit = unit;
        _unitModelName = modelName;
        _loading = false;
      });
    } catch (e, st) {
      // Falha de leitura não pode derrubar a tela do contrato — a seção
      // simplesmente não aparece e o erro vai para o Sentry.
      Sentry.captureException(e, stackTrace: st,
          withScope: (s) => s.setTag('acao', 'contrato.unidade_load'));
      if (mounted) setState(() => _loading = false);
    }
  }

  /// `available_aircrafts.aircraft_model` guarda o id do catálogo; unidades
  /// legadas podem ter gravado o nome direto (mesma tolerância do modal do
  /// estoque).
  Future<String?> _resolveModelName(String stored) async {
    if (stored.isEmpty) return null;
    final rows = await AircraftsTable().queryRows(
      queryFn: (q) => q.eqOrNull('id', stored),
    );
    return rows.firstOrNull?.aircraftModel ?? stored;
  }

  Future<void> _saveLink(String? unitId) async {
    if (_busy || _contract == null) return;
    setState(() => _busy = true);
    try {
      final rows = await ContractTable().update(
        data: {'available_aircraft_id': unitId},
        matchingRows: (q) => q.eqOrNull('id', _contract!.id),
        returnRows: true,
      );
      if (!mounted) return;
      if (rows.isEmpty) {
        // UPDATE bloqueado em silêncio pela RLS/trigger de nível.
        showWriteError(context, kWriteBlockedMessage);
        return;
      }
      showActionSuccess(
          context, unitId == null ? 'Vínculo removido' : 'Unidade vinculada');
      await _load();
    } on PostgrestException catch (e, st) {
      if (!mounted) return;
      if (e.code == '23505') {
        // Índice único parcial: a unidade já está em outro contrato ativo.
        showWriteError(context,
            'Esta unidade já está vinculada a outro contrato ativo.');
      } else {
        Sentry.captureException(e, stackTrace: st,
            withScope: (s) => s.setTag('acao', 'contrato.unidade_vincular'));
        showWriteError(context, mensagemDeErro(e,
            fallback: 'Não foi possível salvar o vínculo. Tente novamente.'));
      }
    } catch (e, st) {
      Sentry.captureException(e, stackTrace: st,
          withScope: (s) => s.setTag('acao', 'contrato.unidade_vincular'));
      if (mounted) {
        showWriteError(context, mensagemDeErro(e,
            fallback: 'Não foi possível salvar o vínculo. Tente novamente.'));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openPicker() async {
    final picked = await showDialog<AvailableAircraftsRow>(
      context: context,
      builder: (dialogContext) => Dialog(
        elevation: 0,
        insetPadding: EdgeInsets.zero,
        backgroundColor: Colors.transparent,
        alignment: Alignment.center,
        child: _UnitPickerModal(currentUnitId: _unit?.id),
      ),
    );
    if (picked != null) await _saveLink(picked.id);
  }

  Future<void> _confirmUnlink() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => Dialog(
        elevation: 0,
        insetPadding: EdgeInsets.zero,
        backgroundColor: Colors.transparent,
        alignment: Alignment.center,
        child: AppModal(
          icon: Icons.link_off_rounded,
          iconTone: AppModalTone.danger,
          title: 'Remover vínculo',
          description:
              'A unidade volta a ficar livre para ser vinculada a outro contrato. '
              'O status dela no estoque não muda.',
          maxWidth: 480,
          footer: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              AppSecondaryButton(
                label: 'Cancelar',
                onPressed: () => Navigator.of(dialogContext).pop(false),
              ),
              const SizedBox(width: 10),
              AppPrimaryButton(
                label: 'Remover vínculo',
                icon: Icons.link_off_rounded,
                onPressed: () => Navigator.of(dialogContext).pop(true),
              ),
            ],
          ),
          child: const SizedBox.shrink(),
        ),
      ),
    );
    if (ok == true) await _saveLink(null);
  }

  @override
  Widget build(BuildContext context) {
    // Proposta ainda sem contrato (ou usuário sem SELECT no contrato): a
    // seção não se aplica.
    if (!_loading && _contract == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 16.0),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF404040),
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(36.0, 28.0, 36.0, 36.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Aeronave do estoque',
                style: GoogleFonts.roboto(
                  fontSize: 18.0,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              const Divider(thickness: 2.0, color: Color(0x74FFFFFF)),
              const SizedBox(height: 8),
              if (_loading)
                AppSkeleton.box(height: 64)
              else if (_unit != null)
                _linkedCard()
              else
                _emptyCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _linkedCard() {
    final unit = _unit!;
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          const Icon(Icons.flight_takeoff_rounded,
              color: Color(0xFFC2D51C), size: 26),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _unitModelName ?? 'Modelo não informado',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  [
                    if (unit.serialNumber.isNotEmpty) 'S/N ${unit.serialNumber}',
                    if (unit.entryYear.isNotEmpty) 'Ano ${unit.entryYear}',
                  ].join(' · '),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xB3FFFFFF),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          AppStatusBadge(
            label: unit.status.isEmpty ? '—' : unit.status,
            tone: _toneFor(unit.status),
            dense: true,
          ),
          if (widget.canEdit) ...[
            const SizedBox(width: 12),
            AppRowAction(
              icon: Icons.swap_horiz_rounded,
              tooltip: 'Trocar unidade',
              onPressed: _busy ? () {} : _openPicker,
            ),
            const SizedBox(width: 4),
            AppRowAction(
              icon: Icons.link_off_rounded,
              tooltip: 'Remover vínculo',
              danger: true,
              onPressed: _busy ? () {} : _confirmUnlink,
            ),
          ],
        ],
      ),
    );
  }

  Widget _emptyCard() {
    return Row(
      children: [
        Expanded(
          child: Text(
            widget.canEdit
                ? 'Nenhuma unidade do estoque vinculada a este contrato.'
                : 'Nenhuma unidade do estoque vinculada.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xB3FFFFFF),
            ),
          ),
        ),
        if (widget.canEdit)
          AppPrimaryButton(
            label: 'Vincular unidade',
            icon: Icons.add_link_rounded,
            busy: _busy,
            onPressed: _openPicker,
          ),
      ],
    );
  }
}

AppStatusTone _toneFor(String status) {
  final s = status.toLowerCase();
  if (s.contains('vendido')) return AppStatusTone.danger;
  if (s.contains('reserv') || s.contains('negocia')) {
    return AppStatusTone.warning;
  }
  if (s.contains('dispon')) return AppStatusTone.success;
  if (s.contains('entreg')) return AppStatusTone.teal;
  return AppStatusTone.brand;
}

/// Seletor de unidade: lista o estoque com busca, resolve o nome do modelo e
/// marca as unidades já presas a outro contrato ativo (não selecionáveis —
/// o índice único do banco é o backstop).
class _UnitPickerModal extends StatefulWidget {
  const _UnitPickerModal({this.currentUnitId});

  final String? currentUnitId;

  @override
  State<_UnitPickerModal> createState() => _UnitPickerModalState();
}

class _PickerUnit {
  _PickerUnit(this.row, this.modelName, this.takenByOther);
  final AvailableAircraftsRow row;
  final String modelName;
  final bool takenByOther;
}

class _UnitPickerModalState extends State<_UnitPickerModal> {
  List<_PickerUnit>? _units;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        AvailableAircraftsTable().queryRows(queryFn: (q) => q),
        AircraftsTable().queryRows(queryFn: (q) => q),
        ContractTable().queryRows(
          queryFn: (q) =>
              q.not('available_aircraft_id', 'is', null).isFilter(
                    'cancelled_at',
                    null,
                  ),
        ),
      ]);
      final units = results[0] as List<AvailableAircraftsRow>;
      final catalog = results[1] as List<AircraftsRow>;
      final activeLinks = results[2] as List<ContractRow>;
      final nameById = {for (final a in catalog) a.id: a.aircraftModel};
      final takenIds = activeLinks
          .map((c) => c.availableAircraftId)
          .whereType<String>()
          .toSet();
      if (!mounted) return;
      setState(() {
        _units = units
            .map((u) => _PickerUnit(
                  u,
                  nameById[u.aircraftModel] ?? u.aircraftModel,
                  takenIds.contains(u.id) && u.id != widget.currentUnitId,
                ))
            .toList()
          ..sort((a, b) => a.modelName.compareTo(b.modelName));
      });
    } catch (e, st) {
      Sentry.captureException(e, stackTrace: st,
          withScope: (s) => s.setTag('acao', 'contrato.unidade_picker'));
      if (mounted) setState(() => _units = []);
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final visible = (_units ?? [])
        .where((u) =>
            q.isEmpty ||
            u.modelName.toLowerCase().contains(q) ||
            u.row.serialNumber.toLowerCase().contains(q))
        .toList();

    return AppModal(
      icon: Icons.flight_takeoff_rounded,
      title: 'Vincular unidade do estoque',
      description:
          'Selecione a unidade física vendida neste contrato. Unidades já '
          'vinculadas a outro contrato ativo aparecem bloqueadas.',
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSearchInput(
            value: _query,
            placeholder: 'Buscar por modelo ou serial...',
            width: double.infinity,
            onChanged: (v) => setState(() => _query = v),
          ),
          const SizedBox(height: 12),
          if (_units == null)
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
            const AppEmptyState(
              icon: Icons.flight_outlined,
              title: 'Nenhuma unidade encontrada',
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 380),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: visible.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) => _unitTile(visible[i]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _unitTile(_PickerUnit u) {
    final isCurrent = u.row.id == widget.currentUnitId;
    final blocked = u.takenByOther;
    return Opacity(
      opacity: blocked ? 0.45 : 1,
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        onTap: (blocked || isCurrent)
            ? null
            : () => Navigator.of(context).pop(u.row),
        child: Row(
          children: [
            Icon(
              blocked ? Icons.lock_outline_rounded : Icons.flight_outlined,
              color: blocked
                  ? const Color(0x99FFFFFF)
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
                    u.modelName.isEmpty ? 'Modelo não informado' : u.modelName,
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
                      if (u.row.serialNumber.isNotEmpty)
                        'S/N ${u.row.serialNumber}',
                      if (u.row.entryYear.isNotEmpty) 'Ano ${u.row.entryYear}',
                      if (isCurrent) 'vinculada a este contrato',
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
              label: u.row.status.isEmpty ? '—' : u.row.status,
              tone: _toneFor(u.row.status),
              dense: true,
            ),
          ],
        ),
      ),
    );
  }
}
