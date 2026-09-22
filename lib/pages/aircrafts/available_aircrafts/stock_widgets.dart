import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '/core_ui/core_ui.dart';
import '/security/action_feedback.dart';
import '/security/write_guard.dart';

// Peças compartilhadas pelos modais do estoque (entrada, saída/reentrada,
// histórico). Widgets próprios, fora do código gerado pelo FlutterFlow.

String formatStockDate(DateTime? d) => d == null
    ? '—'
    : '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

String formatStockDateTime(DateTime d) {
  final l = d.toLocal();
  return '${formatStockDate(l)} ${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
}

/// `YYYY-MM-DD` para a RPC (coluna `date`).
String? stockDateParam(DateTime? d) => d == null
    ? null
    : '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

Future<DateTime?> pickStockDate(BuildContext context, DateTime? initial) async {
  final start = initial ?? DateTime.now();
  final picked = await showDatePicker(
    context: context,
    initialDate: start,
    firstDate: DateTime(start.year - 10),
    lastDate: DateTime(start.year + 30),
    builder: (ctx, child) => Theme(
      data: ThemeData.dark().copyWith(
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFC2D51C),
          onPrimary: Color(0xFF313131),
          surface: Color(0xFF2A2A2A),
        ),
      ),
      child: child!,
    ),
  );
  return picked == null ? null : DateTime(picked.year, picked.month, picked.day);
}

AppStatusTone stockStatusTone(String status, {required bool inStock}) {
  final s = status.toLowerCase();
  if (!inStock) {
    if (s.contains('entreg')) return AppStatusTone.teal;
    if (s.contains('baix')) return AppStatusTone.neutral;
    return AppStatusTone.danger;
  }
  if (s.contains('reserv') || s.contains('negocia')) {
    return AppStatusTone.warning;
  }
  return AppStatusTone.success;
}

/// Campo de data no visual do `AppFormField` (clicável, abre o picker).
class StockDateField extends StatefulWidget {
  const StockDateField({
    super.key,
    required this.label,
    required this.date,
    required this.onChanged,
    this.required = true,
    this.errorText,
  });

  final String label;
  final DateTime? date;
  final ValueChanged<DateTime> onChanged;
  final bool required;
  final String? errorText;

  @override
  State<StockDateField> createState() => _StockDateFieldState();
}

class _StockDateFieldState extends State<StockDateField> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;
    final selected = widget.date != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        RichText(
          text: TextSpan(
            text: widget.label,
            style: GoogleFonts.inter(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: const Color(0xCCFFFFFF),
              letterSpacing: 0.3,
            ),
            children: [
              if (widget.required)
                const TextSpan(
                    text: ' *', style: TextStyle(color: Color(0xFFFF7B82))),
            ],
          ),
        ),
        const SizedBox(height: 6),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hover = true),
          onExit: (_) => setState(() => _hover = false),
          child: GestureDetector(
            onTap: () async {
              final d = await pickStockDate(context, widget.date);
              if (d != null) widget.onChanged(d);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0x14FFFFFF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: hasError
                      ? const Color(0xFFFF7B82).withValues(alpha: 0.85)
                      : _hover
                          ? const Color(0xFFC2D51C).withValues(alpha: 0.55)
                          : const Color(0x22FFFFFF),
                  width: 1.4,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.event_outlined,
                    size: 16,
                    color: selected
                        ? const Color(0xFFC2D51C)
                        : const Color(0x99FFFFFF),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    selected ? formatStockDate(widget.date) : 'Selecionar data...',
                    style: GoogleFonts.roboto(
                      fontSize: 13.5,
                      color: selected ? Colors.white : const Color(0x66FFFFFF),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Text(
            widget.errorText!,
            style: GoogleFonts.roboto(
              fontSize: 11.5,
              color: const Color(0xFFFF7B82),
            ),
          ),
        ],
      ],
    );
  }
}

/// Erro de uma ação do estoque em modal que precisa CONTINUAR aberto (para
/// não perder o que foi digitado): Sentry + mensagem traduzida. Para ações
/// que fecham o diálogo nos dois caminhos, use `runAction`.
void reportStockError(
  BuildContext context,
  Object e,
  StackTrace st, {
  required String fallback,
  required String contexto,
}) {
  Sentry.captureException(e,
      stackTrace: st, withScope: (s) => s.setTag('acao', contexto));
  if (context.mounted) {
    showWriteError(context, mensagemDeErro(e, fallback: fallback));
  }
}

/// Abre um modal do estoque no mesmo invólucro que as outras telas usam.
Future<T?> showStockDialog<T>(BuildContext context, Widget child) {
  return showDialog<T>(
    context: context,
    builder: (dialogContext) => Dialog(
      elevation: 0,
      insetPadding: EdgeInsets.zero,
      backgroundColor: Colors.transparent,
      alignment: Alignment.center,
      child: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: child,
      ),
    ),
  );
}
