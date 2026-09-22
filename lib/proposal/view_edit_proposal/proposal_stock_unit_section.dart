import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '/backend/supabase/supabase.dart';
import '/core_ui/core_ui.dart';
import '/pages/shared/stock_unit_picker/stock_unit_picker.dart';
import '/security/action_feedback.dart';
import '/security/write_guard.dart';

/// Seção "Aeronave do estoque" da proposta (migration 20260922120000).
///
/// Grava `proposal.available_aircraft_id`. A escolha é da PROPOSTA — várias
/// podem disputar a mesma aeronave; quem ganha é a primeira a virar contrato
/// (o trigger de contrato herda a aeronave e dá saída no estoque). Depois da
/// conversão a seção some: a aeronave passa a ser gerida na tela do contrato.
///
/// Mesmo padrão do `ContractAircraftUnitSection`: widget próprio, fora do
/// código gerado pelo FlutterFlow.
class ProposalStockUnitSection extends StatefulWidget {
  const ProposalStockUnitSection({
    super.key,
    required this.proposalId,
    required this.canEdit,
  });

  final String proposalId;
  final bool canEdit;

  @override
  State<ProposalStockUnitSection> createState() =>
      _ProposalStockUnitSectionState();
}

class _ProposalStockUnitSectionState extends State<ProposalStockUnitSection> {
  ProposalRow? _proposal;
  VwStockUnitsRow? _unit;
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final rows = await ProposalTable().queryRows(
        queryFn: (q) => q.eqOrNull('id', widget.proposalId),
      );
      final proposal = rows.firstOrNull;
      VwStockUnitsRow? unit;
      final unitId = proposal?.availableAircraftId;
      if (unitId != null && unitId.isNotEmpty) {
        final units = await VwStockUnitsTable().queryRows(
          queryFn: (q) => q.eqOrNull('id', unitId),
        );
        unit = units.firstOrNull;
      }
      if (!mounted) return;
      setState(() {
        _proposal = proposal;
        _unit = unit;
        _loading = false;
      });
    } catch (e, st) {
      // Falha de leitura não derruba a tela da proposta — a seção só não
      // aparece e o erro vai para o Sentry.
      Sentry.captureException(e,
          stackTrace: st,
          withScope: (s) => s.setTag('acao', 'proposta.estoque_load'));
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save(String? unitId) async {
    if (_busy || _proposal == null) return;
    setState(() => _busy = true);
    var gravou = false;
    await runAction(
      context,
      contexto: 'proposta.estoque_vincular',
      failure: 'Não foi possível salvar a aeronave da proposta.',
      action: () async {
        gravou = await guardWrite(
          context,
          () => ProposalTable().update(
            data: {'available_aircraft_id': unitId},
            matchingRows: (q) => q.eqOrNull('id', _proposal!.id),
            returnRows: true,
          ),
          contexto: 'proposta.estoque_vincular',
        );
      },
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (!gravou) return;
    showActionSuccess(
        context, unitId == null ? 'Aeronave removida' : 'Aeronave escolhida');
    await _load();
  }

  Future<void> _pick() async {
    final model = _proposal?.aircraftId;
    final u = await pickStockUnit(
      context,
      aircraftId: model,
      currentUnitId: _unit?.id,
      description: 'Aeronaves deste modelo que estão no estoque. Ela só sai '
          'do estoque quando a proposta virar contrato.',
    );
    if (u != null) await _save(u.id);
  }

  @override
  Widget build(BuildContext context) {
    // Já é contrato (ou a leitura falhou): a aeronave é gerida no contrato.
    if (!_loading && (_proposal == null || _proposal!.isContract)) {
      return const SizedBox.shrink();
    }
    final unit = _unit;
    // Escolhida, mas já saiu do estoque por outra proposta que virou
    // contrato: avisar antes que alguém tente converter esta.
    final lost = unit != null && (!unit.inStock || unit.contractId != null);
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
              else ...[
                StockUnitField(
                  unit: unit,
                  enabled: widget.canEdit && !_busy,
                  onPick: _pick,
                  onClear: () => _save(null),
                  emptyText: widget.canEdit
                      ? 'Nenhuma aeronave do estoque escolhida. Ela sai do '
                          'estoque quando a proposta virar contrato.'
                      : 'Nenhuma aeronave do estoque escolhida.',
                ),
                if (lost) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Esta aeronave já saiu do estoque (outro contrato ou '
                    'baixa). Troque antes de converter a proposta.',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFFF7B82),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Checagem ANTES de converter a proposta em contrato: a conversão faz várias
/// escritas encadeadas (cliente, contrato, venda, esteira) e o contrato é
/// onde o banco recusaria uma aeronave que já saiu do estoque — a essa altura
/// o cliente já teria sido criado. Devolve a mensagem de bloqueio, ou `null`
/// para seguir.
Future<String?> stockConversionBlocker(String proposalId) async {
  final rows = await ProposalTable().queryRows(
    queryFn: (q) => q.eqOrNull('id', proposalId),
  );
  final unitId = rows.firstOrNull?.availableAircraftId;
  if (unitId == null || unitId.isEmpty) return null;
  final units = await VwStockUnitsTable().queryRows(
    queryFn: (q) => q.eqOrNull('id', unitId),
  );
  final u = units.firstOrNull;
  if (u == null) return null; // excluída → FK set null; nada a validar
  if (!u.inStock || u.contractId != null) {
    return 'A aeronave do estoque desta proposta (S/N ${u.serialNumber}) já '
        'saiu do estoque. Troque a aeronave na seção "Aeronave do estoque" '
        'antes de converter.';
  }
  return null;
}
