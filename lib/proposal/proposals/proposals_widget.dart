import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';

import '/auth/supabase_auth/auth_util.dart';
import '/backend/supabase/supabase.dart';
import '/core_ui/core_ui.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/security/access_control.dart';
import '/index.dart';
import 'proposals_model.dart';

export 'proposals_model.dart';

class ProposalsWidget extends StatefulWidget {
  const ProposalsWidget({super.key});

  static String routeName = 'Proposals';
  static String routePath = '/proposals';

  @override
  State<ProposalsWidget> createState() => _ProposalsWidgetState();
}

class _ProposalsWidgetState extends State<ProposalsWidget> {
  late ProposalsModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  String _query = '';
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ProposalsModel());

    SchedulerBinding.instance.addPostFrameCallback((_) async {
      try {
        final user = await QueryCache.fetch<List<UsersRow>>(
          key: 'proposals.currentUser:$currentUserUid',
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

  void _refresh() => safeSetState(() => _model.requestCompleter = null);

  bool get _canEdit => AccessControl.canEditFunil(
      AccessControl.roleOf(_model.user?.firstOrNull));

  @override
  Widget build(BuildContext context) {
    return AppListScaffold(
      eyebrow: 'Funil de vendas',
      title: 'Propostas',
      description:
          'Cotações enviadas a clientes. Quando aceitas, evoluem para contrato.',
      actions: [
        _PrimaryAction(
          icon: Icons.request_quote_outlined,
          label: 'Cadastrar proposta',
          onTap: () => context.pushNamed(CreateProposalWidget.routeName),
        ),
      ],
      search: AppSearchInput(
        value: _query,
        placeholder: 'Buscar por empresa, ID ou aeronave...',
        onChanged: (v) => setState(() => _query = v),
      ),
      body: FutureBuilder<List<VwProposalDataRow>>(
        future: (_model.requestCompleter ??=
                Completer<List<VwProposalDataRow>>()
                  ..complete(VwProposalDataTable().queryRows(
                    queryFn: (q) => q.order('created_at'),
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
          final all = snap.data!;
          final list = _query.isEmpty
              ? all
              : all.where((p) {
                  final q = _query.toLowerCase();
                  return (p.companyName ?? '').toLowerCase().contains(q) ||
                      (p.idRef ?? '').toLowerCase().contains(q) ||
                      (p.aircraftModel ?? '').toLowerCase().contains(q) ||
                      (p.leadFullname ?? '').toLowerCase().contains(q);
                }).toList();
          if (list.isEmpty) {
            return AppCard(
              child: AppEmptyState(
                icon: Icons.request_quote_outlined,
                title: _query.isEmpty
                    ? 'Nenhuma proposta cadastrada'
                    : 'Nenhuma proposta encontrada',
                description: _query.isEmpty
                    ? 'Crie a primeira proposta a partir de um lead qualificado.'
                    : 'Tente outro termo de busca.',
              ),
            );
          }
          return Column(
            children: [
              for (int i = 0; i < list.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ProposalRow(
                    item: list[i],
                    onTap: () => context.pushNamed(
                      ViewEditProposalWidget.routeName,
                      queryParameters: {
                        'proposalId':
                            serializeParam(list[i].id, ParamType.String),
                        'typeAccess': serializeParam(
                            _canEdit ? 'edit' : 'view', ParamType.String),
                        'companyName': serializeParam(
                            list[i].companyName, ParamType.String),
                        'sellerName': serializeParam(
                            list[i].createdByName, ParamType.String),
                      }.withoutNulls,
                    ),
                  ).appStagger(i),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ProposalRow extends StatelessWidget {
  const _ProposalRow({required this.item, required this.onTap});
  final VwProposalDataRow item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isContract = item.isContract ?? false;
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0x33C2D51C),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(Icons.flight_outlined,
                color: Color(0xFFC2D51C), size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      'ID #${item.idRef ?? '0000000'}',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _Dot(),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        item.aircraftModel ?? 'Modelo não informado',
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          color: const Color(0xCCFFFFFF),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 14,
                  runSpacing: 4,
                  children: [
                    if ((item.companyName ?? '').isNotEmpty)
                      _Meta(Icons.business_outlined, item.companyName!),
                    if ((item.leadFullname ?? '').isNotEmpty)
                      _Meta(Icons.person_search_rounded, item.leadFullname!),
                    if ((item.createdByName ?? '').isNotEmpty)
                      _Meta(Icons.person_outline_rounded, item.createdByName!),
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
              Text(
                _money(item.fullprice),
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              AppStatusBadge(
                label: isContract ? 'Contrato' : 'Proposta',
                icon: isContract
                    ? Icons.verified_outlined
                    : Icons.edit_note_rounded,
                tone: isContract ? AppStatusTone.success : AppStatusTone.brand,
                dense: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _money(num? v) {
    if (v == null) return r'$ 0';
    return formatNumber(v,
        formatType: FormatType.decimal,
        decimalType: DecimalType.periodDecimal,
        currency: r'$ ');
  }
}

class _Dot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 4,
      height: 4,
      decoration: const BoxDecoration(
        color: Color(0x55FFFFFF),
        shape: BoxShape.circle,
      ),
    );
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
