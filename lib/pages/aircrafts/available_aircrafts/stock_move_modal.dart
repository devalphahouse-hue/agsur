import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/backend/stock.dart';
import '/backend/supabase/supabase.dart';
import '/core_ui/core_ui.dart';
import 'stock_widgets.dart';

/// Saída manual (baixa, devolução ao fabricante, ajuste) ou reentrada de uma
/// unidade que já tinha saído. RPCs `stock_exit` / `stock_reentry`
/// (migration 20260922120000). Venda não passa aqui: quem dá saída por venda é
/// a conversão da proposta em contrato.
///
/// Devolve `true` ao fechar quando gravou.
class StockMoveModal extends StatefulWidget {
  const StockMoveModal({
    super.key,
    required this.unit,
    required this.isExit,
  });

  final VwStockUnitsRow unit;

  /// `true` = saída; `false` = reentrada.
  final bool isExit;

  @override
  State<StockMoveModal> createState() => _StockMoveModalState();
}

class _StockMoveModalState extends State<StockMoveModal> {
  final _note = TextEditingController();
  late String _reason =
      (widget.isExit ? kStockExitReasons : kStockReentryReasons).first;
  bool _busy = false;
  bool _tried = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  // Ajuste de inventário sem explicação vira mistério no histórico.
  bool get _noteRequired => _reason == 'ajuste_inventario';

  Future<void> _submit() async {
    setState(() => _tried = true);
    if (_noteRequired && _note.text.trim().isEmpty) return;
    setState(() => _busy = true);
    try {
      await SupaFlow.client.rpc(
        widget.isExit ? 'stock_exit' : 'stock_reentry',
        params: {
          'p_unit_id': widget.unit.id,
          'p_reason': _reason,
          'p_note': _note.text.trim(),
        },
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e, st) {
      if (!mounted) return;
      setState(() => _busy = false);
      reportStockError(context, e, st,
          fallback: widget.isExit
              ? 'Não foi possível registrar a saída.'
              : 'Não foi possível registrar a reentrada.',
          contexto: widget.isExit ? 'estoque.saida' : 'estoque.reentrada');
    }
  }

  @override
  Widget build(BuildContext context) {
    final u = widget.unit;
    final reasons = widget.isExit ? kStockExitReasons : kStockReentryReasons;
    return AppModal(
      icon: widget.isExit ? Icons.outbox_rounded : Icons.move_to_inbox_rounded,
      iconTone: widget.isExit ? AppModalTone.danger : AppModalTone.success,
      title: widget.isExit ? 'Registrar saída' : 'Registrar reentrada',
      description: widget.isExit
          ? 'A aeronave sai do estoque e a quantidade do modelo diminui. '
              'Venda não é por aqui: ela sai sozinha quando a proposta vira contrato.'
          : 'A aeronave volta para o estoque como Disponível.',
      maxWidth: 520,
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          AppSecondaryButton(
            label: 'Cancelar',
            onPressed: _busy ? null : () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 10),
          AppPrimaryButton(
            label: widget.isExit ? 'Dar saída' : 'Devolver ao estoque',
            icon: Icons.check_rounded,
            busy: _busy,
            onPressed: _submit,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppCard(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Icon(Icons.flight_outlined,
                    color: Color(0xFFC2D51C), size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${u.aircraftModelName} · S/N ${u.serialNumber}',
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          AppDropdown<String>(
            label: 'Motivo',
            icon: Icons.label_outline_rounded,
            required: true,
            value: _reason,
            options: reasons,
            labelOf: stockReasonLabel,
            onChanged: (r) => setState(() => _reason = r),
          ),
          const SizedBox(height: 14),
          AppFormField(
            controller: _note,
            label: 'Observação',
            placeholder: _noteRequired
                ? 'Explique o ajuste (obrigatório)'
                : 'Opcional',
            icon: Icons.notes_rounded,
            required: _noteRequired,
            maxLines: 3,
            onChanged: (_) => setState(() {}),
          ),
          if (_tried && _noteRequired && _note.text.trim().isEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Ajuste de inventário precisa de observação.',
              style: GoogleFonts.roboto(
                fontSize: 11.5,
                color: const Color(0xFFFF7B82),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
