import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/backend/supabase/supabase.dart';
import '/core_ui/core_ui.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/pages/shared/alert_dialog/alert_dialog_widget.dart';
import '/pages/shared/modal_certificate/modal_certificate_widget.dart';
import 'certificates_model.dart';

export 'certificates_model.dart';

class CertificatesWidget extends StatefulWidget {
  const CertificatesWidget({super.key});

  static String routeName = 'Certificates';
  static String routePath = '/certificates';

  @override
  State<CertificatesWidget> createState() => _CertificatesWidgetState();
}

class _CertificatesWidgetState extends State<CertificatesWidget> {
  late CertificatesModel _model;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => CertificatesModel());
    _model.textController ??= TextEditingController();
    _model.textFieldFocusNode ??= FocusNode();
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  void _refresh() => safeSetState(() => _model.requestCompleter = null);

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
          child: const ModalCertificateWidget(type: 'Register'),
        ),
      ),
    );
    _refresh();
  }

  Future<void> _openEdit(CertificatesRow item) async {
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
          child: ModalCertificateWidget(
            type: 'Edit',
            certificateID: item.id,
          ),
        ),
      ),
    );
    _refresh();
  }

  Future<void> _confirmDelete(CertificatesRow item) async {
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
            title: 'Deseja excluir este certificado?',
            iconColor: const Color(0xFFFF5963),
            btnColor: const Color(0xFFFF5963),
            confirmBtnAction: () async {
              await CertificatesTable().update(
                data: {'is_deleted': true},
                matchingRows: (rows) => rows.eqOrNull('id', item.id),
              );
              if (!mounted) return;
              Navigator.of(dialogContext).pop();
              _refresh();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Certificado excluído',
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
    return AppListScaffold(
      eyebrow: 'Configurações',
      title: 'Certificados',
      description:
          'Catálogo de certificados de simulador disponíveis para pilotos.',
      actions: [
        _PrimaryAction(
          icon: Icons.workspace_premium_outlined,
          label: 'Cadastrar certificado',
          onTap: _openCreate,
        ),
      ],
      search: AppSearchInput(
        value: _query,
        placeholder: 'Buscar por nome do certificado...',
        onChanged: (v) {
          setState(() => _query = v);
          _model.textController?.text = v;
          _refresh();
        },
      ),
      body: FutureBuilder<List<CertificatesRow>>(
        future: (_model.requestCompleter ??=
                Completer<List<CertificatesRow>>()
                  ..complete(CertificatesTable().queryRows(
                    queryFn: (q) => q
                        .eqOrNull('is_deleted', false)
                        .ilike('certificate_name', '%$_query%')
                        .order('certificate_name', ascending: true),
                  )))
            .future,
        builder: (context, snap) {
          if (!snap.hasData) {
            return Column(
              children: List.generate(
                4,
                (_) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AppSkeleton.box(height: 64),
                ),
              ),
            );
          }
          final list = snap.data!;
          if (list.isEmpty) {
            return AppCard(
              child: AppEmptyState(
                icon: Icons.workspace_premium_outlined,
                title: _query.isEmpty
                    ? 'Nenhum certificado'
                    : 'Nenhum certificado encontrado',
                description: _query.isEmpty
                    ? 'Cadastre o primeiro certificado de simulador.'
                    : 'Tente outro termo de busca.',
              ),
            );
          }
          return Column(
            children: [
              for (int i = 0; i < list.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _CertRow(
                    item: list[i],
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

class _CertRow extends StatelessWidget {
  const _CertRow({
    required this.item,
    required this.onTap,
    required this.onDelete,
  });

  final CertificatesRow item;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0x33C2D51C),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.workspace_premium_outlined,
                size: 18, color: Color(0xFFC2D51C)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              item.certificateName ?? 'Sem nome',
              style: GoogleFonts.inter(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          AppRowAction(
            icon: Icons.edit_outlined,
            tooltip: 'Editar',
            onPressed: onTap,
          ),
          const SizedBox(width: 4),
          AppRowAction(
            icon: Icons.delete_outline_rounded,
            tooltip: 'Excluir',
            danger: true,
            onPressed: onDelete,
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
