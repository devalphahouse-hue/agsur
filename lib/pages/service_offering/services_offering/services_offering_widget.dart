import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/backend/paged_query.dart';
import '/backend/supabase/supabase.dart';
import '/core_ui/core_ui.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/security/action_feedback.dart';
import '/security/write_guard.dart';
import '/pages/shared/alert_dialog/alert_dialog_widget.dart';
import '/pages/shared/modal_services_offering/modal_services_offering_widget.dart';
import 'services_offering_model.dart';

export 'services_offering_model.dart';

class ServicesOfferingWidget extends StatefulWidget {
  const ServicesOfferingWidget({super.key});

  static String routeName = 'ServicesOffering';
  static String routePath = '/servicesOffering';

  @override
  State<ServicesOfferingWidget> createState() => _ServicesOfferingWidgetState();
}

class _ServicesOfferingWidgetState extends State<ServicesOfferingWidget> {
  late ServicesOfferingModel _model;
  String _query = '';
  int _page = 1;
  int _perPage = kDefaultPerPage;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ServicesOfferingModel());
    _model.textController ??= TextEditingController();
    _model.textFieldFocusNode ??= FocusNode();
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  void _refresh() => safeSetState(() => _model.requestCompleter = null);

  void _goToPage(int p) => safeSetState(() {
        _page = p;
        _model.requestCompleter = null;
      });

  void _setPerPage(int n) => safeSetState(() {
        _perPage = n;
        _page = 1;
        _model.requestCompleter = null;
      });

  /// Página vinda do backend (`range` + `count=exact`).
  ///
  /// A busca vai no `queryFn` — filtrar em Dart depois de paginar filtraria só
  /// a página corrente, e o total mentiria. `orIlike` também limpa `(`, `)`,
  /// `,` e `*` do termo, que quebrariam a sintaxe do filtro.
  Future<PagedResult<ServicesOfferingRow>> _fetchPage() => queryPage(
        table: ServicesOfferingTable(),
        page: _page,
        perPage: _perPage,
        queryFn: (q) {
          final base = q.eqOrNull('is_deleted', false);
          final f = _query.trim().isEmpty
              ? base
              : base.or(orIlike(const ['service_title', 'models'], _query));
          return f.order('service_title', ascending: true);
        },
      );

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
          child: ModalServicesOfferingWidget(
            type: 'Register',
            databaseRefresh: () async => _refresh(),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(ServicesOfferingRow item) async {
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
            title: 'Deseja excluir esta carta de serviço?',
            iconColor: const Color(0xFFFF5963),
            btnColor: const Color(0xFFFF5963),
            confirmBtnAction: () async {
              // Num UPDATE a RLS filtra a linha ANTES da trigger e devolve 2xx
              // com 0 linhas: sem o guardWrite a tela confirmava "excluída" com
              // a carta ainda na lista. `returnRows: true` é obrigatório —
              // sem ele o update devolve [] SEMPRE e o guard acusaria bloqueio
              // em toda exclusão.
              var apagou = false;
              final ok = await runAction(
                context,
                dialogContext: dialogContext,
                contexto: 'cartas.excluir',
                failure: 'Não foi possível excluir a carta de serviço.',
                action: () async {
                  apagou = await guardWrite(
                    context,
                    () => ServicesOfferingTable().update(
                      data: {'is_deleted': true},
                      matchingRows: (rows) => rows.eqOrNull('id', item.id),
                      returnRows: true,
                    ),
                    contexto: 'cartas.excluir',
                  );
                },
              );
              if (!mounted || !ok || !apagou) return;
              _refresh();
              showActionSuccess(context, 'Carta de serviço excluída');
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
      title: 'Cartas de serviço',
      description:
          'Documentos de serviço (PDF) que clientes e oficinas podem baixar.',
      actions: [
        _PrimaryAction(
          icon: Icons.upload_file_rounded,
          label: 'Cadastrar carta',
          onTap: _openCreate,
        ),
      ],
      search: AppSearchInput(
        value: _query,
        placeholder: 'Buscar por título ou modelo...',
        onChanged: (v) {
          setState(() {
            _query = v;
            // Buscar volta para a primeira página: parado na pág. 3, um termo
            // com 5 resultados devolveria uma página vazia.
            _page = 1;
          });
          _model.textController?.text = v;
          _refresh();
        },
      ),
      body: FutureBuilder<PagedResult<ServicesOfferingRow>>(
        future: (_model.requestCompleter ??=
                Completer<PagedResult<ServicesOfferingRow>>()
                  ..complete(_fetchPage()))
            .future,
        builder: (context, snap) {
          if (!snap.hasData) {
            return Column(
              children: List.generate(
                4,
                (_) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AppSkeleton.box(height: 76),
                ),
              ),
            );
          }
          final paged = snap.data!;
          final list = paged.items;
          if (list.isEmpty) {
            return AppCard(
              child: AppEmptyState(
                icon: Icons.miscellaneous_services_outlined,
                title: _query.isEmpty
                    ? 'Nenhuma carta cadastrada'
                    : 'Nenhuma carta encontrada',
                description: _query.isEmpty
                    ? 'Faça upload do primeiro PDF para começar.'
                    : 'Tente outro termo de busca.',
              ),
            );
          }
          return Column(
            children: [
              for (int i = 0; i < list.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ServiceRow(
                    item: list[i],
                    onOpen: () => openStorageDoc(list[i].docUrl),
                    onDelete: () => _confirmDelete(list[i]),
                  ).appStagger(i),
                ),
              AppPagination(
                result: paged,
                onPageChanged: _goToPage,
                onPerPageChanged: _setPerPage,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ServiceRow extends StatelessWidget {
  const _ServiceRow({
    required this.item,
    required this.onOpen,
    required this.onDelete,
  });

  final ServicesOfferingRow item;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isMaintenance = item.type.toLowerCase().contains('manuten') ||
        item.type.toLowerCase().contains('mainten');
    return AppCard(
      onTap: onOpen,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isMaintenance
                  ? const Color(0x33F9CF58)
                  : const Color(0x33C2D51C),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              Icons.picture_as_pdf_outlined,
              size: 20,
              color: isMaintenance
                  ? const Color(0xFFF9CF58)
                  : const Color(0xFFC2D51C),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.serviceTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    if (item.type.isNotEmpty)
                      _Meta(Icons.label_outline, item.type),
                    if ((item.models ?? '').isNotEmpty)
                      _Meta(Icons.flight_outlined, item.models!),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          AppRowAction(
            icon: Icons.download_rounded,
            tooltip: 'Baixar PDF',
            onPressed: onOpen,
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
