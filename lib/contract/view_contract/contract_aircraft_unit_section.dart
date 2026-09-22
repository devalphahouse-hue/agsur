import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '/backend/supabase/supabase.dart';
import '/core_ui/core_ui.dart';
import '/custom_code/actions/index.dart' show ContractPdfUnit;
import '/pages/shared/stock_unit_picker/stock_unit_picker.dart';
import '/security/action_feedback.dart';
import '/security/write_guard.dart';

/// Seção "Aeronave do estoque" da tela de contrato.
///
/// Vínculo contrato ↔ unidade física de `available_aircrafts` (pedido do
/// cliente, 2026-07-21: "abre uma lista de aeronaves e coloca pra ele").
/// Grava em `contract.available_aircraft_id` (migration 20260722130000);
/// o banco garante uma unidade por contrato ativo via índice único parcial.
///
/// Desde o controle de estoque (migration 20260922120000) o vínculo MOVIMENTA
/// o estoque, por trigger: vincular dá saída ("Venda (contrato)"), trocar
/// devolve a antiga e dá saída na nova, remover/cancelar devolve. Na
/// conversão o contrato já nasce com a aeronave escolhida na proposta. O
/// seletor só oferece aeronaves do MODELO da proposta que estão no estoque —
/// o banco recusa as demais.
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
  VwStockUnitsRow? _unit;
  String? _proposalAircraftId;
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
      VwStockUnitsRow? unit;
      final unitId = contract?.availableAircraftId;
      if (unitId != null && unitId.isNotEmpty) {
        final units = await VwStockUnitsTable().queryRows(
          queryFn: (q) => q.eqOrNull('id', unitId),
        );
        unit = units.firstOrNull;
      }
      final proposals = await ProposalTable().queryRows(
        queryFn: (q) => q.eqOrNull('id', widget.proposalId),
      );
      if (!mounted) return;
      setState(() {
        _contract = contract;
        _unit = unit;
        _proposalAircraftId = proposals.firstOrNull?.aircraftId;
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
          context,
          unitId == null
              ? 'Vínculo removido — aeronave de volta ao estoque'
              : 'Aeronave vinculada — saída registrada no estoque');
      // O seletor cacheia o estoque; o vínculo acabou de movimentá-lo.
      QueryCache.invalidate('stock.units');
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
    final picked = await pickStockUnit(
      context,
      aircraftId: _proposalAircraftId,
      currentUnitId: _unit?.id,
      title: 'Vincular aeronave do estoque',
      description: 'Aeronaves do modelo desta proposta que estão no estoque. '
          'Ao vincular, a aeronave sai do estoque.',
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
              'A aeronave volta para o estoque como Disponível e fica livre '
              'para outra proposta. A devolução fica no histórico do estoque.',
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
                  unit.aircraftModelName.isEmpty
                      ? 'Modelo não informado'
                      : unit.aircraftModelName,
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
                    (unit.registrationPrefix ?? '').isNotEmpty
                        ? 'Prefixo ${unit.registrationPrefix}'
                        : 'Prefixo a definir',
                    if (unit.manufactureDate != null)
                      'Fab. ${unit.manufactureDate!.year}',
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
            tone: stockStatusTone(unit.status, inStock: unit.inStock),
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


/// Aeronave do estoque do contrato desta proposta, no formato da minuta.
/// `null` = contrato sem aeronave vinculada (a minuta sai como antes).
/// Propaga erro de leitura: o "Gerar PDF" não deve seguir sem saber.
Future<ContractPdfUnit?> loadContractPdfUnit(String proposalId) async {
  final contracts = await ContractTable().queryRows(
    queryFn: (q) => q.eqOrNull('proposal_id', proposalId),
  );
  final unitId = contracts.firstOrNull?.availableAircraftId;
  if (unitId == null || unitId.isEmpty) return null;
  final units = await VwStockUnitsTable().queryRows(
    queryFn: (q) => q.eqOrNull('id', unitId),
  );
  final u = units.firstOrNull;
  if (u == null) return null;
  return ContractPdfUnit(
    serialNumber: u.serialNumber,
    registrationPrefix: u.registrationPrefix,
    manufactureYear: u.manufactureDate?.year,
    deliveryDate: u.deliveryDate,
  );
}
