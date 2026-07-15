import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/backend/supabase/supabase.dart';
import '/core_ui/core_ui.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import '/security/write_guard.dart';
import '/pages/shared/alert_dialog/alert_dialog_widget.dart';
import '/pages/shared/modal_register_lead/modal_register_lead_widget.dart';
import 'leads_model.dart';

export 'leads_model.dart';

class LeadsWidget extends StatefulWidget {
  const LeadsWidget({super.key});

  static String routeName = 'Leads';
  static String routePath = '/leads';

  @override
  State<LeadsWidget> createState() => _LeadsWidgetState();
}

class _LeadsWidgetState extends State<LeadsWidget> {
  late LeadsModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => LeadsModel());
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
          child: ModalRegisterLeadWidget(
            btnAction: (name, lastname, cpf, company, jobTitle, email, phone,
                city, uf, createdBy) async {
              _model.insertLead = await LeadsTable().insert({
                'name': name,
                'last_name': lastname,
                'cpf': cpf,
                'email': email,
                'phone': phone,
                'city': city,
                'state': uf,
                'created_by': createdBy,
                'job_title': jobTitle,
                'company_name': company,
              });
              if (!mounted) return;
              _refresh();
              Navigator.of(dialogContext).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Lead cadastrado com sucesso!',
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

  Future<void> _confirmDelete(LeadsRow item) async {
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
            title: 'Deseja excluir este lead?',
            iconColor: const Color(0xFFFF5963),
            btnColor: const Color(0xFFFF5963),
            confirmBtnAction: () async {
              final okDeleteLead = await guardWrite(
                context,
                () => LeadsTable().update(
                  data: {'is_deleted': true},
                  matchingRows: (rows) => rows.eqOrNull('id', item.id),
                  returnRows: true,
                ),
              );
              if (!okDeleteLead) return;
              if (!mounted) return;
              Navigator.of(dialogContext).pop();
              _refresh();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Lead excluído',
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
      eyebrow: 'Funil de vendas',
      title: 'Leads',
      description:
          'Prospects iniciais. Quando qualificados, viram propostas e seguem o funil.',
      actions: [
        _PrimaryAction(
          icon: Icons.person_add_alt_rounded,
          label: 'Cadastrar lead',
          onTap: _openCreate,
        ),
      ],
      search: AppSearchInput(
        value: _query,
        placeholder: 'Buscar por nome do lead...',
        onChanged: (v) {
          setState(() => _query = v);
          _model.textController?.text = v;
          _refresh();
        },
      ),
      body: FutureBuilder<List<LeadsRow>>(
        future: (_model.requestCompleter ??= Completer<List<LeadsRow>>()
              ..complete(LeadsTable().queryRows(
                queryFn: (q) => q
                    .eqOrNull('is_deleted', false)
                    .ilike('fullname', '%$_query%')
                    .order('created_at'),
              )))
            .future,
        builder: (context, snap) {
          if (!snap.hasData) {
            return Column(
              children: List.generate(
                4,
                (_) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AppSkeleton.box(height: 86),
                ),
              ),
            );
          }
          final list = snap.data!;
          if (list.isEmpty) {
            return AppCard(
              child: AppEmptyState(
                icon: Icons.person_search_rounded,
                title: _query.isEmpty
                    ? 'Nenhum lead cadastrado'
                    : 'Nenhum lead encontrado',
                description: _query.isEmpty
                    ? 'Crie o primeiro lead para começar.'
                    : 'Tente outro termo de busca.',
              ),
            );
          }
          return Column(
            children: [
              for (int i = 0; i < list.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _LeadRow(
                    item: list[i],
                    onTap: () => context.pushNamed(
                      ViewEditLeadWidget.routeName,
                      queryParameters: {
                        'leadId':
                            serializeParam(list[i].id, ParamType.String),
                        'typeAccess': serializeParam('view', ParamType.String),
                        'fullname':
                            serializeParam(list[i].fullname, ParamType.String),
                      }.withoutNulls,
                    ),
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

class _LeadRow extends StatelessWidget {
  const _LeadRow({
    required this.item,
    required this.onTap,
    required this.onDelete,
  });

  final LeadsRow item;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return AppPersonCard(
      name: item.fullname ?? '${item.name} ${item.lastName}'.trim(),
      subtitle: (item.jobTitle ?? '').isNotEmpty
          ? item.jobTitle
          : item.email,
      avatarIcon: Icons.person_search_rounded,
      isActive: !item.isDeleted,
      onTap: onTap,
      metas: [
        if ((item.companyName ?? '').isNotEmpty)
          AppPersonMeta(Icons.business_outlined, item.companyName!),
        if (item.phone.isNotEmpty)
          AppPersonMeta(Icons.phone_outlined, item.phone),
        if (item.city.isNotEmpty)
          AppPersonMeta(Icons.location_on_outlined,
              '${item.city}${item.state.isNotEmpty ? '/${item.state}' : ''}'),
      ],
      trailing: [
        const AppStatusBadge(
          label: 'Lead',
          icon: Icons.bolt_outlined,
          tone: AppStatusTone.warning,
          dense: true,
        ),
        AppRowAction(
          icon: Icons.delete_outline_rounded,
          tooltip: 'Excluir',
          danger: true,
          onPressed: onDelete,
        ),
      ],
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
