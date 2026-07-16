import 'dart:async';

import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '/flutter_flow/custom_functions.dart' as functions;

import '/auth/supabase_auth/auth_util.dart';
import '/backend/supabase/supabase.dart';
import '/core_ui/core_ui.dart';
import '/flutter_flow/flutter_flow_drop_down.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/form_field_controller.dart';
import '/index.dart' show CreateItemsStandardWidget, CreateItemsOptionsWidget;
import '/security/write_guard.dart';
import 'create_category_model.dart';

export 'create_category_model.dart';

class CreateCategoryWidget extends StatefulWidget {
  const CreateCategoryWidget({super.key});

  static String routeName = 'CreateCategory';
  static String routePath = '/createCategory';

  @override
  State<CreateCategoryWidget> createState() => _CreateCategoryWidgetState();
}

class _CreateCategoryWidgetState extends State<CreateCategoryWidget> {
  late CreateCategoryModel _model;

  // Aba ativa (série/opcional): filtra a lista E define o tipo do que se
  // cria — um controle só, para não parecer que o toggle do formulário é um
  // filtro que não filtra (feedback do dono em 2026-07-14).
  String get _tipo => _model.dpdTypeItemValue ?? 'series';

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => CreateCategoryModel());
    _model.tFCategoryNameTextController ??= TextEditingController();
    _model.tFCategoryNameFocusNode ??= FocusNode();
    _model.dpdTypeItemValue ??= 'series';
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  void _refresh() => safeSetState(() => _model.requestCompleter = null);

  /// Modal único de criação: categoria + itens + aeronaves numa tacada
  /// (feedback do dono em 2026-07-14: "criar tudo e fazer tudo ali ao
  /// adicionar", sem criar a categoria e depois caçar onde pôr os itens).
  Future<void> _openCreateDialog() async {
    final aircrafts = await AircraftsTable().queryRows(
      queryFn: (q) => q
          .eqOrNull('active', true)
          .eqOrNull('deleted', false)
          .order('aircraft_model', ascending: true),
    );
    if (!mounted) return;
    final created = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => Dialog(
        elevation: 0,
        insetPadding: EdgeInsets.zero,
        backgroundColor: Colors.transparent,
        alignment: AlignmentDirectional(0.0, 0.0)
            .resolve(Directionality.of(context)),
        child: _CreateCategoryDialog(tipo: _tipo, aircrafts: aircrafts),
      ),
    );
    if (created == true && mounted) {
      _refresh();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Categoria e itens cadastrados',
            style: GoogleFonts.inter(color: const Color(0xFF313131)),
          ),
          backgroundColor: const Color(0xFFC2D51C),
        ),
      );
    }
  }

  /// Abre a tela de itens da categoria (série ou opcionais), com ela
  /// pré-selecionada. Até 2026-07-14 essas telas eram rotas órfãs — nenhuma
  /// navegação chegava nelas; o cadastro de itens ficava inacessível.
  void _openItems(CategoryRow item) {
    context.pushNamed(
      item.itemType == 'optional'
          ? CreateItemsOptionsWidget.routeName
          : CreateItemsStandardWidget.routeName,
      queryParameters: {
        'categoryId': serializeParam(item.id, ParamType.String),
      }.withoutNulls,
    );
  }

  Future<void> _delete(CategoryRow item) async {
    // Carrega os itens (ainda ativos) da categoria para avisar no modal quais
    // serão removidos junto.
    final items = await AircraftItemsTable().queryRows(
      queryFn: (q) => q
          .eqOrNull('category_id', item.id)
          .eqOrNull('deleted', false)
          .order('item_name', ascending: true),
    );
    if (!mounted) return;
    final itemNames = items.map((e) => e.itemName).toList();
    final done = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => Dialog(
        elevation: 0,
        insetPadding: EdgeInsets.zero,
        backgroundColor: Colors.transparent,
        alignment: Alignment.center,
        child: _DeleteCategoryDialog(category: item, itemNames: itemNames),
      ),
    );
    if (done == true && mounted) {
      _refresh();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Categoria removida',
            style: GoogleFonts.inter(color: const Color(0xFF313131)),
          ),
          backgroundColor: const Color(0xFFC2D51C),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppListScaffold(
      eyebrow: 'Operação',
      title: 'Categorias',
      description:
          'Agrupe itens de série e opcionais por categoria para usar nas propostas.',
      search: _TypeToggle(
        value: _tipo,
        onChanged: (v) => safeSetState(() => _model.dpdTypeItemValue = v),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _tipo == 'optional'
                      ? 'Categorias de opcionais e seus itens.'
                      : 'Categorias de itens de série e seus itens.',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    color: const Color(0x99FFFFFF),
                  ),
                ),
              ),
              AppPrimaryButton(
                label: 'Adicionar',
                icon: Icons.add_rounded,
                onPressed: _openCreateDialog,
              ),
            ],
          ),
          const SizedBox(height: 16),
          FutureBuilder<List<CategoryRow>>(
            future: (_model.requestCompleter ??=
                    Completer<List<CategoryRow>>()
                      ..complete(CategoryTable().queryRows(
                        queryFn: (q) => q
                            .eqOrNull('deleted', false)
                            .order('category_name', ascending: true),
                      )))
                .future,
            builder: (context, snap) {
              if (!snap.hasData) {
                return Column(
                  children: List.generate(
                    4,
                    (_) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: AppSkeleton.box(height: 56),
                    ),
                  ),
                );
              }
              final all = snap.data!;
              final list =
                  all.where((c) => c.itemType == _tipo).toList();
              if (list.isEmpty) {
                return AppCard(
                  child: AppEmptyState(
                    icon: Icons.category_outlined,
                    title: _tipo == 'optional'
                        ? 'Nenhuma categoria de opcionais'
                        : 'Nenhuma categoria de série',
                    description:
                        'Clique em Adicionar para criar a primeira.',
                    compact: true,
                  ),
                );
              }
              return Column(
                children: [
                  for (int i = 0; i < list.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _CategoryRow(
                        item: list[i],
                        onDelete: () => _delete(list[i]),
                        onOpenItems: () => _openItems(list[i]),
                      ).appStagger(i),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TypeToggle extends StatelessWidget {
  const _TypeToggle({required this.value, required this.onChanged});
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0x14FFFFFF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0x22FFFFFF)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _seg('series', 'Itens de série'),
          _seg('optional', 'Opcionais'),
        ],
      ),
    );
  }

  Widget _seg(String v, String label) {
    final active = v == value;
    return GestureDetector(
      onTap: () => onChanged(v),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFC2D51C) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: active ? const Color(0xFF313131) : Colors.white,
          ),
        ),
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.item,
    required this.onDelete,
    required this.onOpenItems,
  });
  final CategoryRow item;
  final VoidCallback onDelete;
  final VoidCallback onOpenItems;

  @override
  Widget build(BuildContext context) {
    final isOpcional = item.itemType == 'optional';
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onOpenItems,
        child: AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isOpcional
                      ? const Color(0x33F9CF58)
                      : const Color(0x33C2D51C),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  isOpcional ? Icons.add_circle_outline : Icons.label_outline,
                  size: 16,
                  color: isOpcional
                      ? const Color(0xFFF9CF58)
                      : const Color(0xFFC2D51C),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.categoryName,
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              AppStatusBadge(
                label: isOpcional ? 'Opcional' : 'Série',
                tone: isOpcional ? AppStatusTone.warning : AppStatusTone.brand,
                dense: true,
              ),
              const SizedBox(width: 8),
              AppRowAction(
                icon: Icons.inventory_2_outlined,
                tooltip: 'Itens da categoria',
                onPressed: onOpenItems,
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
        ),
      ),
    );
  }
}


/// Rascunho de um item dentro do modal de criação.
class _ItemDraft {
  final nome = TextEditingController();
  final qtd = TextEditingController(text: '1');
  final preco = TextEditingController();
  final precoFocus = FocusNode();
  String get debounceKey => 'catPreco_${identityHashCode(this)}';
  void dispose() {
    EasyDebounce.cancel(debounceKey);
    nome.dispose();
    qtd.dispose();
    preco.dispose();
    precoFocus.dispose();
  }
}

/// Modal único: cria a categoria E os itens dela (com as aeronaves) de uma
/// vez. As aeronaves selecionadas valem para todos os itens deste cadastro —
/// depois cada item pode ser ajustado individualmente pela tela de itens.
class _CreateCategoryDialog extends StatefulWidget {
  const _CreateCategoryDialog({required this.tipo, required this.aircrafts});

  /// 'series' | 'optional' (vem da aba ativa).
  final String tipo;
  final List<AircraftsRow> aircrafts;

  @override
  State<_CreateCategoryDialog> createState() => _CreateCategoryDialogState();
}

class _CreateCategoryDialogState extends State<_CreateCategoryDialog> {
  final _nomeController = TextEditingController();
  final _aircraftsController = FormFieldController<List<String>?>(null);
  List<String>? _selectedAircraftIds;
  final List<_ItemDraft> _drafts = [_ItemDraft()];
  bool _busy = false;

  bool get _isOptional => widget.tipo == 'optional';

  @override
  void dispose() {
    _nomeController.dispose();
    for (final d in _drafts) {
      d.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy) return;
    final nome = _nomeController.text.trim();
    if (nome.isEmpty) {
      showWriteError(context, 'Informe o nome da categoria.');
      return;
    }
    final preenchidos =
        _drafts.where((d) => d.nome.text.trim().isNotEmpty).toList();
    final aeronaves = _selectedAircraftIds?.toList() ?? [];
    if (preenchidos.isNotEmpty && aeronaves.isEmpty) {
      showWriteError(
          context, 'Selecione ao menos uma aeronave para os itens.');
      return;
    }
    for (final d in preenchidos) {
      final qty = int.tryParse(d.qtd.text.trim());
      if (qty == null || qty < 1) {
        showWriteError(context,
            'Quantidade inválida no item "${d.nome.text.trim()}" (mínimo 1).');
        return;
      }
    }
    setState(() => _busy = true);
    try {
      final categoria = await guardInsert(
        context,
        () => CategoryTable().insert({
          'category_name': nome,
          'item_type': widget.tipo,
          'created_by': currentUserUid,
        }),
      );
      if (categoria == null) return; // bloqueado — não fecha a modal
      for (final d in preenchidos) {
        final item = await guardInsert(
          context,
          () => AircraftItemsTable().insert({
            'category_id': categoria.id,
            'item_name': d.nome.text.trim(),
            'qty': int.parse(d.qtd.text.trim()),
            'price': _isOptional
                ? valueOrDefault<double>(
                    functions.textToNumeric(d.preco.text), 0.0)
                : 0.00,
            'item_type': widget.tipo,
            'created_by': currentUserUid,
          }),
        );
        if (item == null) continue; // erro já exibido; segue os demais
        for (final aircraftId in aeronaves) {
          await guardInsert(
            context,
            () => AircraftItemLinksTable().insert({
              'aircraft_item_id': item.id,
              'aircraft_id': aircraftId,
              'created_by': currentUserUid,
            }),
          );
        }
      }
      if (mounted) Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppModal(
      icon: Icons.add_rounded,
      title: _isOptional
          ? 'Nova categoria de opcionais'
          : 'Nova categoria de itens de série',
      description:
          'Crie a categoria e já cadastre os itens dela, vinculados às aeronaves.',
      maxWidth: 640,
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          AppSecondaryButton(
            label: 'Cancelar',
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: 10),
          AppPrimaryButton(
            label: 'Salvar tudo',
            icon: Icons.check_rounded,
            busy: _busy,
            onPressed: _save,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppFormField(
            controller: _nomeController,
            label: 'Nome da categoria',
            placeholder: _isOptional
                ? 'Ex.: DGPS - AGNAV'
                : 'Ex.: Instrumentos de voo',
            icon: Icons.category_outlined,
            required: true,
          ),
          const SizedBox(height: 14),
          Text(
            'Aeronaves dos itens *',
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: const Color(0x99FFFFFF),
            ),
          ),
          const SizedBox(height: 6),
          FlutterFlowDropDown<String>(
            multiSelectController: _aircraftsController,
            isMultiSelect: true,
            onMultiSelectChanged: (values) =>
                setState(() => _selectedAircraftIds = values),
            options:
                List<String>.from(widget.aircrafts.map((a) => a.id).toList()),
            optionLabels: widget.aircrafts.map((a) => a.aircraftModel).toList(),
            height: 48.0,
            textStyle: GoogleFonts.inter(
              fontSize: 13.5,
              color: Colors.white,
            ),
            hintText: 'Selecione as aeronaves',
            icon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Color(0x73FFFFFF),
              size: 24.0,
            ),
            fillColor: const Color(0xFF404040),
            elevation: 2.0,
            borderColor: const Color(0x73FFFFFF),
            borderWidth: 1.0,
            borderRadius: 8.0,
            margin: const EdgeInsetsDirectional.fromSTEB(12.0, 0.0, 12.0, 0.0),
            hidesUnderline: true,
            isOverButton: false,
            isSearchable: false,
          ),
          const SizedBox(height: 18),
          Text(
            _isOptional ? 'Itens opcionais' : 'Itens de série',
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: const Color(0x99FFFFFF),
            ),
          ),
          const SizedBox(height: 6),
          for (int i = 0; i < _drafts.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: AppFormField(
                      controller: _drafts[i].nome,
                      label: i == 0 ? 'Nome do item' : 'Nome do item ${i + 1}',
                      placeholder: 'Ex.: GPS AGNAV',
                      icon: Icons.settings_suggest_rounded,
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 92,
                    child: AppFormField(
                      controller: _drafts[i].qtd,
                      label: 'Qtd',
                      placeholder: '1',
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly
                      ],
                    ),
                  ),
                  if (_isOptional) ...[
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 150,
                      child: AppFormField(
                        controller: _drafts[i].preco,
                        focusNode: _drafts[i].precoFocus,
                        label: 'Preço (US\$)',
                        placeholder: '\$ 0.00',
                        icon: Icons.attach_money_rounded,
                        keyboardType: TextInputType.number,
                        onChanged: (_) {
                          final draft = _drafts[i];
                          EasyDebounce.debounce(
                            draft.debounceKey,
                            const Duration(milliseconds: 0),
                            () {
                              setState(() {
                                draft.preco.text = valueOrDefault<String>(
                                  functions.formatarMoedaEmDolar(
                                    valueOrDefault<String>(
                                        draft.preco.text, '0'),
                                  ),
                                  '\$ 0.00',
                                );
                                draft.precoFocus.requestFocus();
                                WidgetsBinding.instance
                                    .addPostFrameCallback((_) {
                                  draft.preco.selection =
                                      TextSelection.collapsed(
                                    offset: draft.preco.text.length,
                                  );
                                });
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ],
                  if (_drafts.length > 1) ...[
                    const SizedBox(width: 6),
                    Padding(
                      padding: const EdgeInsets.only(top: 30),
                      child: AppRowAction(
                        icon: Icons.close_rounded,
                        tooltip: 'Remover este item',
                        danger: true,
                        onPressed: () => setState(() {
                          _drafts.removeAt(i).dispose();
                        }),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: AppSecondaryButton(
              label: 'Adicionar outro item',
              icon: Icons.add_rounded,
              onPressed: () => setState(() => _drafts.add(_ItemDraft())),
            ),
          ),
        ],
      ),
    );
  }
}

/// Confirmação de exclusão de categoria. Lista os itens que serão removidos
/// junto e, ao confirmar, faz soft-delete dos itens e da categoria.
///
/// Soft-delete (não hard-delete) porque `aircraft_items.category_id` é FK
/// NO ACTION e NOT NULL — apagar de verdade travaria em itens já usados em
/// propostas (23503) e corromperia o histórico. Com `deleted=true` tudo some
/// do painel e das propostas novas, preservando as antigas; é reversível.
class _DeleteCategoryDialog extends StatefulWidget {
  const _DeleteCategoryDialog({required this.category, required this.itemNames});

  final CategoryRow category;
  final List<String> itemNames;

  @override
  State<_DeleteCategoryDialog> createState() => _DeleteCategoryDialogState();
}

class _DeleteCategoryDialogState extends State<_DeleteCategoryDialog> {
  bool _busy = false;

  Future<void> _confirm() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      // 1) Soft-delete dos itens da categoria (se houver).
      if (widget.itemNames.isNotEmpty) {
        final ok = await guardWrite(
          context,
          () => AircraftItemsTable().update(
            data: {'deleted': true},
            matchingRows: (rows) =>
                rows.eqOrNull('category_id', widget.category.id),
            returnRows: true,
          ),
        );
        if (!ok) return; // bloqueado — mantém a modal
      }
      // 2) Soft-delete da categoria.
      final okCat = await guardWrite(
        context,
        () => CategoryTable().update(
          data: {'deleted': true},
          matchingRows: (rows) => rows.eqOrNull('id', widget.category.id),
          returnRows: true,
        ),
      );
      if (!okCat) return;
      if (mounted) Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.itemNames.length;
    return AppModal(
      icon: Icons.warning_amber_rounded,
      iconTone: AppModalTone.danger,
      title: 'Excluir a categoria "${widget.category.categoryName}"?',
      description: n == 0
          ? 'A categoria será removida do painel.'
          : 'Esta categoria tem $n ${n == 1 ? 'item' : 'itens'}. Ao excluir, '
              'todos serão removidos junto (somem do painel e das propostas '
              'novas; propostas já feitas são preservadas).',
      maxWidth: 480,
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          AppSecondaryButton(
            label: 'Cancelar',
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: 10),
          AppPrimaryButton(
            label: n == 0 ? 'Excluir' : 'Excluir tudo',
            icon: Icons.delete_outline_rounded,
            busy: _busy,
            onPressed: _confirm,
          ),
        ],
      ),
      child: n == 0
          ? const SizedBox(height: 4)
          : ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final name in widget.itemNames)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 7, right: 8),
                              child: Icon(Icons.circle,
                                  size: 5, color: Color(0x99FFFFFF)),
                            ),
                            Expanded(
                              child: Text(
                                name,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: const Color(0xCCFFFFFF),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}
