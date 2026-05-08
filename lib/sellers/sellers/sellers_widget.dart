import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/backend/schema/enums/enums.dart';
import '/backend/supabase/supabase.dart';
import '/core_ui/core_ui.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import '/pages/shared/alert_dialog/alert_dialog_widget.dart';
import '/pages/shared/menu/menu_widget.dart';
import '/pages/shared/modal_register_seller/modal_register_seller_widget.dart';
import '/pages/shared/switch_component/switch_component_widget.dart';
import 'sellers_model.dart';

export 'sellers_model.dart';

class SellersWidget extends StatefulWidget {
  const SellersWidget({super.key});

  static String routeName = 'Sellers';
  static String routePath = '/sellers';

  @override
  State<SellersWidget> createState() => _SellersWidgetState();
}

class _SellersWidgetState extends State<SellersWidget> {
  late SellersModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => SellersModel());
    _model.tFSearchSellerTextController ??= TextEditingController();
    _model.tFSearchSellerFocusNode ??= FocusNode();
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
          child: ModalRegisterSellerWidget(
            refreshDatabase: () async {
              _refresh();
            },
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(UsersRow item) async {
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
            title: 'Deseja excluir este vendedor?',
            iconColor: const Color(0xFFFF5963),
            btnColor: const Color(0xFFFF5963),
            confirmBtnAction: () async {
              await UsersTable().update(
                data: {'is_deleted': true, 'is_active': false},
                matchingRows: (rows) => rows.eqOrNull('id', item.id),
              );
              if (!mounted) return;
              Navigator.of(dialogContext).pop();
              _refresh();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Vendedor excluído',
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
      eyebrow: 'Pessoas',
      title: 'Vendedores',
      description:
          'Vendedores acompanham leads, propostas e contratos da sua carteira.',
      actions: [
        _PrimaryAction(
          icon: Icons.business_center_outlined,
          label: 'Cadastrar vendedor',
          onTap: _openCreate,
        ),
      ],
      search: AppSearchInput(
        value: _query,
        placeholder: 'Buscar por nome do vendedor...',
        onChanged: (v) {
          setState(() => _query = v);
          _model.tFSearchSellerTextController?.text = v;
          _refresh();
        },
      ),
      body: FutureBuilder<List<UsersRow>>(
        future: (_model.requestCompleter ??= Completer<List<UsersRow>>()
              ..complete(UsersTable().queryRows(
                queryFn: (q) => q
                    .eqOrNull('profile_type', ProfileType.Vendedor.name)
                    .eqOrNull('is_deleted', false)
                    .ilike('fullname', '%$_query%')
                    .order('fullname', ascending: true),
              )))
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
          final list = snap.data!;
          if (list.isEmpty) {
            return AppCard(
              child: AppEmptyState(
                icon: Icons.business_center_outlined,
                title: _query.isEmpty
                    ? 'Nenhum vendedor cadastrado'
                    : 'Nenhum vendedor encontrado',
                description: _query.isEmpty
                    ? 'Crie o primeiro vendedor para começar.'
                    : 'Tente outro termo de busca.',
              ),
            );
          }
          return Column(
            children: [
              for (int i = 0; i < list.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _SellerRow(
                    item: list[i],
                    model: _model,
                    index: i,
                    onTap: () => context.pushNamed(
                      ViewEditSellerWidget.routeName,
                      queryParameters: {
                        'sellerId':
                            serializeParam(list[i].id, ParamType.String),
                        'typeAccess': serializeParam('view', ParamType.String),
                        'fullname': serializeParam(
                            list[i].fullname, ParamType.String),
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

class _SellerRow extends StatelessWidget {
  const _SellerRow({
    required this.item,
    required this.model,
    required this.index,
    required this.onTap,
    required this.onDelete,
  });

  final UsersRow item;
  final SellersModel model;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return AppPersonCard(
      name: item.fullname ?? 'Vendedor sem nome',
      subtitle: item.email,
      avatarIcon: Icons.business_center_outlined,
      isActive: item.isActive ?? false,
      onTap: onTap,
      metas: [
        if ((item.phone ?? '').isNotEmpty)
          AppPersonMeta(Icons.phone_outlined, item.phone!),
      ],
      trailing: [
        wrapWithModel(
          model: model.switchComponentModels.getModel(
            item.id ?? '$index',
            index,
          ),
          updateCallback: () {},
          child: SwitchComponentWidget(
            key: Key('seller_switch_${item.id ?? index}'),
            initialValue: item.isActive ?? false,
            activeAction: () async {
              await UsersTable().update(
                data: {'is_active': true},
                matchingRows: (rows) => rows.eqOrNull('id', item.id),
              );
              _toast(context, 'Vendedor ativado');
            },
            disableAction: () async {
              await UsersTable().update(
                data: {'is_active': false},
                matchingRows: (rows) => rows.eqOrNull('id', item.id),
              );
              _toast(context, 'Vendedor desativado');
            },
          ),
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

  void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: GoogleFonts.inter(color: const Color(0xFF313131)),
        ),
        backgroundColor: const Color(0xFFC2D51C),
        duration: const Duration(seconds: 2),
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
