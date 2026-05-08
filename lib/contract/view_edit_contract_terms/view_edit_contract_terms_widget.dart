import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/backend/supabase/supabase.dart';
import '/core_ui/core_ui.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'view_edit_contract_terms_model.dart';

export 'view_edit_contract_terms_model.dart';

const _kTermsId = 'f2cb3aab-9209-4db7-8522-f24e575494fd';

class ViewEditContractTermsWidget extends StatefulWidget {
  const ViewEditContractTermsWidget({super.key});

  static String routeName = 'ViewEditContractTerms';
  static String routePath = '/viewEditContractTerms';

  @override
  State<ViewEditContractTermsWidget> createState() =>
      _ViewEditContractTermsWidgetState();
}

class _ViewEditContractTermsWidgetState
    extends State<ViewEditContractTermsWidget> {
  late ViewEditContractTermsModel _model;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ViewEditContractTermsModel());
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  void _editTerms(String id) {
    context.pushNamed(
      CreateContractTermsWidget.routeName,
      queryParameters: {
        'idContractTerms': serializeParam(id, ParamType.String),
        'type': serializeParam('terms', ParamType.String),
      }.withoutNulls,
    );
  }

  void _editInstructions(String id) {
    context.pushNamed(
      CreateContractTermsWidget.routeName,
      queryParameters: {
        'idContractTerms': serializeParam(id, ParamType.String),
        'type': serializeParam('instructions', ParamType.String),
      }.withoutNulls,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppListScaffold(
      eyebrow: 'Configurações',
      title: 'Termos e instruções',
      description:
          'Texto-padrão dos termos do contrato e instruções de pagamento.',
      body: FutureBuilder<List<ContractTermsRow>>(
        future: ContractTermsTable().querySingleRow(
          queryFn: (q) => q.eqOrNull('id', _kTermsId),
        ),
        builder: (context, snap) {
          if (!snap.hasData) {
            return Column(
              children: List.generate(
                2,
                (_) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: AppSkeleton.box(height: 220),
                ),
              ),
            );
          }
          final row = snap.data!.isNotEmpty ? snap.data!.first : null;
          if (row == null) {
            return AppCard(
              child: AppEmptyState(
                icon: Icons.lan_outlined,
                title: 'Termos não cadastrados',
              ),
            );
          }
          return Column(
            children: [
              _DocCard(
                icon: Icons.gavel_outlined,
                tone: AppStatusTone.brand,
                title: 'Termos do contrato',
                subtitle: 'Texto inserido no PDF de cada contrato gerado.',
                content: row.terms,
                lastUpdate: _format(row.updateTermsAt),
                onEdit: () => _editTerms(row.id),
              ).appStagger(0),
              const SizedBox(height: 14),
              _DocCard(
                icon: Icons.payments_outlined,
                tone: AppStatusTone.success,
                title: 'Instruções de pagamento',
                subtitle:
                    'Aparece para o cliente após o aceite do contrato.',
                content: row.paymentInstructions,
                lastUpdate: _format(row.updateInstructionsAt),
                onEdit: () => _editInstructions(row.id),
              ).appStagger(1),
            ],
          );
        },
      ),
    );
  }

  String _format(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }
}

class _DocCard extends StatelessWidget {
  const _DocCard({
    required this.icon,
    required this.tone,
    required this.title,
    required this.subtitle,
    required this.content,
    required this.lastUpdate,
    required this.onEdit,
  });

  final IconData icon;
  final AppStatusTone tone;
  final String title;
  final String subtitle;
  final String content;
  final String lastUpdate;
  final VoidCallback onEdit;

  Color get _bg => switch (tone) {
        AppStatusTone.brand => const Color(0x33C2D51C),
        AppStatusTone.success => const Color(0x33249689),
        AppStatusTone.warning => const Color(0x33F9CF58),
        AppStatusTone.danger => const Color(0x33FF5963),
        AppStatusTone.teal => const Color(0x3339D2C0),
        AppStatusTone.neutral => const Color(0x22FFFFFF),
      };

  Color get _fg => switch (tone) {
        AppStatusTone.brand => const Color(0xFFC2D51C),
        AppStatusTone.success => const Color(0xFF4FBFA9),
        AppStatusTone.warning => const Color(0xFFF9CF58),
        AppStatusTone.danger => const Color(0xFFFF7B82),
        AppStatusTone.teal => const Color(0xFF4FE0D0),
        AppStatusTone.neutral => Colors.white,
      };

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _bg,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, size: 18, color: _fg),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.roboto(
                        fontSize: 12,
                        color: const Color(0xAAFFFFFF),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _EditBtn(onTap: onEdit),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF313131),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0x14FFFFFF)),
            ),
            child: Text(
              content.isEmpty ? '—' : content,
              maxLines: 8,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.roboto(
                fontSize: 12.5,
                color: const Color(0xCCFFFFFF),
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.update_rounded,
                  size: 12, color: Color(0x99FFFFFF)),
              const SizedBox(width: 4),
              Text(
                'Atualizado em $lastUpdate',
                style: GoogleFonts.roboto(
                  fontSize: 11.5,
                  color: const Color(0x99FFFFFF),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EditBtn extends StatefulWidget {
  const _EditBtn({required this.onTap});
  final VoidCallback onTap;

  @override
  State<_EditBtn> createState() => _EditBtnState();
}

class _EditBtnState extends State<_EditBtn> {
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: _hover
                ? const Color(0x33C2D51C)
                : const Color(0x14C2D51C),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: _hover
                  ? const Color(0x99C2D51C)
                  : const Color(0x33C2D51C),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.edit_outlined,
                  size: 14, color: Color(0xFFC2D51C)),
              const SizedBox(width: 6),
              Text(
                'Editar',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFC2D51C),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
