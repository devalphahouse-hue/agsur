import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/backend/cascade_delete.dart';
import '/core_ui/core_ui.dart';

/// Confirmação de exclusão que MOSTRA o que será afetado antes de agir.
///
/// Existe porque a exclusão no funil nunca atinge só o registro clicado:
/// apagar um lead leva as propostas e os contratos dele junto, e apaga a
/// esteira de rastreio em definitivo. Um "Deseja excluir?" genérico esconderia
/// isso — o usuário só descobriria depois, quando o contrato sumisse.
///
/// Devolve `true` se o usuário confirmou.
Future<bool> confirmDeleteWithImpact(
  BuildContext context, {
  required String titulo,
  required DeletionImpact impacto,
  required String principal,
}) async {
  final itens = resumoDoImpacto(impacto, principal: principal);
  final ok = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => Dialog(
      elevation: 0,
      insetPadding: EdgeInsets.zero,
      backgroundColor: Colors.transparent,
      alignment: Alignment.center,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: AppCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0x33FF5963),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Icon(Icons.delete_outline_rounded,
                        color: Color(0xFFFF7B82), size: 21),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      titulo,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                itens.length == 1
                    ? 'Será excluído:'
                    : 'Isso não afeta só este registro. Será excluído:',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xCCFFFFFF),
                ),
              ),
              const SizedBox(height: 10),
              for (final item in itens)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      const Icon(Icons.remove_rounded,
                          size: 14, color: Color(0x8AFFFFFF)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item,
                          style: GoogleFonts.inter(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (impacto.etapasTracking > 0) ...[
                const SizedBox(height: 12),
                _Aviso(
                  'As ${impacto.etapasTracking} etapas de rastreio serão '
                  'apagadas em definitivo — isso não tem como desfazer. '
                  'O restante é reversível.',
                ),
              ],
              if (impacto.temClienteComAcesso) ...[
                const SizedBox(height: 10),
                _Aviso(
                  'Este lead já virou cliente com acesso ao app. Ele deixará '
                  'de ver a aeronave e o andamento da importação.',
                ),
              ],
              const SizedBox(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    child: Text(
                      'Cancelar',
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        color: const Color(0xCCFFFFFF),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFFF5963),
                      foregroundColor: const Color(0xFF1A1A1A),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                    ),
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                    child: Text(
                      'Excluir',
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
  return ok ?? false;
}

class _Aviso extends StatelessWidget {
  const _Aviso(this.texto);
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0x1FF9CF58),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded,
              size: 16, color: Color(0xFFF9CF58)),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              texto,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                height: 1.4,
                color: const Color(0xE6FFFFFF),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
