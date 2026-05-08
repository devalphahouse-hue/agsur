import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/auth/supabase_auth/auth_util.dart';
import '/backend/supabase/supabase.dart';
import '/core_ui/core_ui.dart';
import '/flutter_flow/flutter_flow_util.dart';
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
  String _filter = 'all';

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

  Future<void> _create() async {
    final name = _model.tFCategoryNameTextController?.text.trim() ?? '';
    if (name.isEmpty || (_model.dpdTypeItemValue ?? '').isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preencha tipo e nome da categoria'),
          backgroundColor: Color(0xFFFF5963),
        ),
      );
      return;
    }
    await CategoryTable().insert({
      'category_name': name,
      'item_type': _model.dpdTypeItemValue,
      'created_by': currentUserUid,
    });
    if (!mounted) return;
    _model.tFCategoryNameTextController?.clear();
    _refresh();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Categoria cadastrada',
          style: GoogleFonts.inter(color: const Color(0xFF313131)),
        ),
        backgroundColor: const Color(0xFFC2D51C),
      ),
    );
  }

  Future<void> _delete(CategoryRow item) async {
    await CategoryTable().delete(
      matchingRows: (rows) => rows.eqOrNull('id', item.id),
    );
    if (!mounted) return;
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

  @override
  Widget build(BuildContext context) {
    return AppListScaffold(
      eyebrow: 'Operação',
      title: 'Categorias',
      description:
          'Agrupe itens de série e opcionais por categoria para usar nas propostas.',
      search: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _FilterChips(
            label: 'Mostrar',
            value: _filter,
            options: const [
              MapEntry('all', 'Todos'),
              MapEntry('series', 'Série'),
              MapEntry('optional', 'Opcionais'),
            ],
            onChanged: (v) => setState(() => _filter = v),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CreateForm(
            controller: _model.tFCategoryNameTextController!,
            type: _model.dpdTypeItemValue ?? 'series',
            onTypeChanged: (v) =>
                safeSetState(() => _model.dpdTypeItemValue = v),
            onSubmit: _create,
          ),
          const SizedBox(height: 16),
          FutureBuilder<List<CategoryRow>>(
            future: (_model.requestCompleter ??=
                    Completer<List<CategoryRow>>()
                      ..complete(CategoryTable().queryRows(
                        queryFn: (q) =>
                            q.order('category_name', ascending: true),
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
              final list = _filter == 'all'
                  ? all
                  : all.where((c) => c.itemType == _filter).toList();
              if (list.isEmpty) {
                return AppCard(
                  child: AppEmptyState(
                    icon: Icons.category_outlined,
                    title: 'Nenhuma categoria',
                    description:
                        'Use o formulário acima para criar a primeira.',
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

class _CreateForm extends StatelessWidget {
  const _CreateForm({
    required this.controller,
    required this.type,
    required this.onTypeChanged,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final String type;
  final ValueChanged<String> onTypeChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Tipo (chip toggle)
          _TypeToggle(
            value: type,
            onChanged: onTypeChanged,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              style: GoogleFonts.roboto(color: Colors.white, fontSize: 13.5),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Nome da categoria',
                hintStyle: GoogleFonts.roboto(
                  color: const Color(0x99FFFFFF),
                  fontSize: 13.5,
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 14),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.04),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: Color(0x22FFFFFF), width: 1.4),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: Color(0x22FFFFFF), width: 1.4),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                      color: Color(0xFFC2D51C), width: 1.4),
                ),
              ),
              onSubmitted: (_) => onSubmit(),
            ),
          ),
          const SizedBox(width: 12),
          _SubmitBtn(onTap: onSubmit),
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
          _seg('series', 'Série'),
          _seg('optional', 'Opcional'),
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

class _SubmitBtn extends StatefulWidget {
  const _SubmitBtn({required this.onTap});
  final VoidCallback onTap;

  @override
  State<_SubmitBtn> createState() => _SubmitBtnState();
}

class _SubmitBtnState extends State<_SubmitBtn> {
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
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
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
              const Icon(Icons.add_rounded,
                  size: 16, color: Color(0xFF313131)),
              const SizedBox(width: 6),
              Text(
                'Adicionar',
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

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({required this.item, required this.onDelete});
  final CategoryRow item;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isOpcional = item.itemType == 'optional';
    return AppCard(
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

class _FilterChips extends StatelessWidget {
  const _FilterChips({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<MapEntry<String, String>> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0x14FFFFFF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0x22FFFFFF)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label:',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: const Color(0x99FFFFFF),
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(width: 8),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isDense: true,
              dropdownColor: const Color(0xFF2A2A2A),
              icon: const Icon(Icons.expand_more_rounded,
                  color: Color(0xFFC2D51C), size: 18),
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              items: [
                for (final opt in options)
                  DropdownMenuItem(value: opt.key, child: Text(opt.value)),
              ],
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
            ),
          ),
        ],
      ),
    );
  }
}
