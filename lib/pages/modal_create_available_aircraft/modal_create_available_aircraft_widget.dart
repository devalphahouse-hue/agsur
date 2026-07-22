import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/auth/supabase_auth/auth_util.dart';
import '/backend/supabase/supabase.dart';
import '/core_ui/core_ui.dart';
import '/flutter_flow/custom_functions.dart' as functions;
import '/flutter_flow/flutter_flow_util.dart';
import 'modal_create_available_aircraft_model.dart';

export 'modal_create_available_aircraft_model.dart';

class ModalCreateAvailableAircraftWidget extends StatefulWidget {
  const ModalCreateAvailableAircraftWidget({
    super.key,
    this.btnAction,
    required this.type,
    this.aircraftId,
    this.id,
    this.aircraftModel,
  });

  final Future Function(
    String idAeronave,
    String numeroSerie,
    DateTime dataFabricacao,
    DateTime prazoConfiguracao,
    DateTime dataEntrega,
    String createdBy,
    String anoBase,
    String status,
    String updateBy,
    String id,
  )? btnAction;
  final String? type;
  final String? aircraftId;
  final String? id;
  final String? aircraftModel;

  @override
  State<ModalCreateAvailableAircraftWidget> createState() =>
      _ModalCreateAvailableAircraftWidgetState();
}

class _ModalCreateAvailableAircraftWidgetState
    extends State<ModalCreateAvailableAircraftWidget> {
  late ModalCreateAvailableAircraftModel _model;
  bool _busy = false;
  bool _editPrefilled = false;
  String? _aircraftError;
  String? _yearError;
  String? _statusError;
  String? _dateError;

  static const _years = [
    '2025', '2026', '2027', '2028', '2029', '2030',
    '2031', '2032', '2033', '2034', '2035',
  ];
  static const _statuses = [
    'Disponível',
    'Em negociação',
    'Entregue',
    'Vendido',
  ];

  bool get _isCreate => widget.type == 'create';
  bool get _isView => widget.type == 'view' && !_model.editar;
  bool get _isEdit => widget.type != 'create' && _model.editar;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ModalCreateAvailableAircraftModel());
    _model.tFSerialNumberTextController ??= TextEditingController();
    _model.tFSerialNumberFocusNode ??= FocusNode();
    _model.tFEditSerialNumberTextController ??= TextEditingController();
    _model.tFEditSerialNumberFocusNode ??= FocusNode();
    _model.tFViewAircraftTextController ??=
        TextEditingController(text: widget.aircraftModel);
    _model.tFViewAircraftFocusNode ??= FocusNode();
    _model.tFViewSerialNumberTextController ??= TextEditingController();
    _model.tFViewSerialNumberFocusNode ??= FocusNode();
    _model.tFViewEntryYearTextController ??= TextEditingController();
    _model.tFViewEntryYearFocusNode ??= FocusNode();
    _model.tFViewStatusTextController ??= TextEditingController();
    _model.tFViewStatusFocusNode ??= FocusNode();
  }

  @override
  void dispose() {
    _model.maybeDispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool edit}) async {
    final initial = edit
        ? (_model.datePicked2 ?? DateTime.now())
        : (_model.datePicked1 ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(initial.year - 5),
      lastDate: DateTime(initial.year + 30),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFFC2D51C),
            onPrimary: Color(0xFF313131),
            surface: Color(0xFF2A2A2A),
          ),
          dialogBackgroundColor: const Color(0xFF2A2A2A),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      if (edit) {
        _model.datePicked2 = DateTime(picked.year, picked.month, picked.day);
      } else {
        _model.datePicked1 = DateTime(picked.year, picked.month, picked.day);
      }
      _dateError = null;
    });
  }

  Future<void> _create() async {
    if (_busy) return;
    setState(() {
      _aircraftError =
          _model.dPDAircraftsValue == null ? 'Selecione o modelo' : null;
      _yearError = _model.dPDEntryYearValue == null ? 'Selecione o ano' : null;
      _statusError =
          _model.dPDStatusValue == null ? 'Selecione o status' : null;
      _dateError =
          _model.datePicked1 == null ? 'Selecione a data de fabricação' : null;
    });
    if (_model.formKey1.currentState == null ||
        !_model.formKey1.currentState!.validate()) return;
    if (_aircraftError != null ||
        _yearError != null ||
        _statusError != null ||
        _dateError != null) return;
    setState(() => _busy = true);
    try {
      await widget.btnAction?.call(
        _model.dPDAircraftsValue!,
        _model.tFSerialNumberTextController!.text,
        _model.datePicked1!,
        functions.subtractDate(_model.datePicked1!),
        functions.addDate(_model.datePicked1!),
        currentUserUid,
        _model.dPDEntryYearValue!,
        _model.dPDStatusValue!,
        currentUserUid,
        '',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save(AvailableAircraftsRow row) async {
    if (_busy) return;
    setState(() {
      // Valida como no create em vez de estourar no null-check mais
      // adiante — era isso que fazia o salvar "não responder".
      _aircraftError =
          _model.dPDEditAircraftsValue == null ? 'Selecione o modelo' : null;
      _yearError =
          _model.dPDEditEntryYearValue == null ? 'Selecione o ano' : null;
      _statusError =
          _model.dPDEditStatusValue == null ? 'Selecione o status' : null;
    });
    if (_model.formKey2.currentState == null ||
        !_model.formKey2.currentState!.validate()) return;
    if (_aircraftError != null || _yearError != null || _statusError != null) {
      return;
    }
    setState(() => _busy = true);
    try {
      final manuf = _model.datePicked2 ?? row.manufactureDate;
      await widget.btnAction?.call(
        _model.dPDEditAircraftsValue!,
        _model.tFEditSerialNumberTextController!.text,
        manuf,
        _model.datePicked2 != null
            ? functions.subtractDate(_model.datePicked2!)
            : row.configurationDeadline,
        _model.datePicked2 != null
            ? functions.addDate(_model.datePicked2!)
            : row.deliveryDate,
        row.createdBy ?? currentUserUid,
        _model.dPDEditEntryYearValue!,
        _model.dPDEditStatusValue!,
        currentUserUid,
        widget.id ?? '',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppModal(
      icon: Icons.flight_takeoff_rounded,
      title: _isCreate
          ? 'Adicionar ao estoque'
          : _isEdit
              ? 'Editar unidade'
              : 'Detalhes da unidade',
      description: _isCreate
          ? 'Selecione um modelo do catálogo e informe os dados da unidade física.'
          : null,
      maxWidth: 700,
      footer: _buildFooter(),
      child: _isCreate ? _buildCreate() : _buildEditOrView(),
    );
  }

  Widget _buildFooter() {
    if (_isView) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          AppSecondaryButton(
            label: 'Fechar',
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: 10),
          AppPrimaryButton(
            label: 'Editar unidade',
            icon: Icons.edit_outlined,
            onPressed: () => setState(() => _model.editar = true),
          ),
        ],
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        AppSecondaryButton(
          label: 'Cancelar',
          onPressed: () => _isEdit
              ? setState(() => _model.editar = false)
              : Navigator.of(context).maybePop(),
        ),
        const SizedBox(width: 10),
        if (_isCreate)
          AppPrimaryButton(
            label: 'Adicionar ao estoque',
            icon: Icons.check_rounded,
            busy: _busy,
            onPressed: _create,
          )
        else
          // Edit button precisa do row carregado — botão é renderizado dentro do FutureBuilder.
          const SizedBox.shrink(),
      ],
    );
  }

  Widget _buildCreate() {
    return FutureBuilder<List<AircraftsRow>>(
      future: AircraftsTable().queryRows(queryFn: (q) => q),
      builder: (context, snap) {
        if (!snap.hasData) {
          return Column(
            children: List.generate(
              5,
              (_) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AppSkeleton.box(height: 60),
              ),
            ),
          );
        }
        final aircrafts = snap.data!;
        return Form(
          key: _model.formKey1,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppDropdown<AircraftsRow>(
                label: 'Modelo de aeronave',
                icon: Icons.flight_outlined,
                placeholder: 'Selecione o modelo...',
                required: true,
                searchable: true,
                value: aircrafts.firstWhereOrNull(
                    (a) => a.id == _model.dPDAircraftsValue),
                options: aircrafts,
                labelOf: (a) => a.aircraftModel ?? a.id,
                errorText: _aircraftError,
                onChanged: (a) => setState(() {
                  _model.dPDAircraftsValue = a.id;
                  _aircraftError = null;
                }),
              ),
              const SizedBox(height: 14),
              AppFormField(
                controller: _model.tFSerialNumberTextController,
                focusNode: _model.tFSerialNumberFocusNode,
                label: 'Número de série',
                placeholder: 'Ex.: ABC-1234',
                icon: Icons.tag_rounded,
                required: true,
                validator: (v) => _model.tFSerialNumberTextControllerValidator
                    ?.call(context, v),
              ),
              const SizedBox(height: 14),
              _DateField(
                label: 'Data de fabricação',
                date: _model.datePicked1,
                errorText: _dateError,
                onTap: () => _pickDate(edit: false),
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: AppDropdown<String>(
                      label: 'Ano base',
                      icon: Icons.calendar_today_rounded,
                      placeholder: 'Selecione o ano...',
                      required: true,
                      value: _model.dPDEntryYearValue,
                      options: _years,
                      labelOf: (y) => y,
                      errorText: _yearError,
                      onChanged: (y) => setState(() {
                        _model.dPDEntryYearValue = y;
                        _yearError = null;
                      }),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AppDropdown<String>(
                      label: 'Status',
                      icon: Icons.flag_rounded,
                      placeholder: 'Selecione o status...',
                      required: true,
                      value: _model.dPDStatusValue,
                      options: _statuses,
                      labelOf: (s) => s,
                      errorText: _statusError,
                      onChanged: (s) => setState(() {
                        _model.dPDStatusValue = s;
                        _statusError = null;
                      }),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEditOrView() {
    return FutureBuilder<List<AvailableAircraftsRow>>(
      future: AvailableAircraftsTable().querySingleRow(
        queryFn: (q) => q.eqOrNull('id', widget.id),
      ),
      builder: (context, snap) {
        if (!snap.hasData) {
          return Column(
            children: List.generate(
              5,
              (_) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AppSkeleton.box(height: 60),
              ),
            ),
          );
        }
        final row = snap.data!.isNotEmpty ? snap.data!.first : null;
        if (row == null) {
          return AppEmptyState(
            icon: Icons.error_outline_rounded,
            title: 'Unidade não encontrada',
          );
        }
        if (!_editPrefilled) {
          _editPrefilled = true;
          _model.tFEditSerialNumberTextController!.text = row.serialNumber ?? '';
          // A coluna aircraft_model guarda o ID do catálogo (aircrafts.id):
          // é o que o create insere e o que fn_available_aircrafts resolve
          // para nome na listagem. Sem este prefill o dropdown de modelo
          // abria vazio e salvar sem re-selecionar o modelo morria no
          // null-check — o usuário tinha que escolher o modelo de novo a
          // cada edição de status (bug reportado em 2026-07-21).
          _model.dPDEditAircraftsValue ??= widget.aircraftId ?? row.aircraftModel;
          _model.dPDEditEntryYearValue ??= row.entryYear;
          _model.dPDEditStatusValue ??= row.status;
          _model.tFViewSerialNumberTextController!.text = row.serialNumber ?? '';
          _model.tFViewEntryYearTextController!.text = row.entryYear ?? '';
          _model.tFViewStatusTextController!.text = row.status ?? '';
        }
        if (_isView) {
          return _buildView(row);
        }
        return _buildEditForm(row);
      },
    );
  }

  Widget _buildView(AvailableAircraftsRow row) {
    final manuf = row.manufactureDate;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppFormField(
          controller: _model.tFViewAircraftTextController,
          focusNode: _model.tFViewAircraftFocusNode,
          label: 'Modelo',
          icon: Icons.flight_outlined,
          enabled: false,
        ),
        const SizedBox(height: 14),
        AppFormField(
          controller: _model.tFViewSerialNumberTextController,
          focusNode: _model.tFViewSerialNumberFocusNode,
          label: 'Número de série',
          icon: Icons.tag_rounded,
          enabled: false,
        ),
        const SizedBox(height: 14),
        _DateField(
          label: 'Data de fabricação',
          date: manuf,
          enabled: false,
          onTap: () {},
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AppFormField(
                controller: _model.tFViewEntryYearTextController,
                focusNode: _model.tFViewEntryYearFocusNode,
                label: 'Ano base',
                icon: Icons.calendar_today_rounded,
                enabled: false,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AppFormField(
                controller: _model.tFViewStatusTextController,
                focusNode: _model.tFViewStatusFocusNode,
                label: 'Status',
                icon: Icons.flag_rounded,
                enabled: false,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEditForm(AvailableAircraftsRow row) {
    return FutureBuilder<List<AircraftsRow>>(
      future: AircraftsTable().queryRows(queryFn: (q) => q),
      builder: (context, snap) {
        if (!snap.hasData) {
          return Column(
            children: List.generate(
              5,
              (_) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AppSkeleton.box(height: 60),
              ),
            ),
          );
        }
        final aircrafts = snap.data!;
        return Form(
          key: _model.formKey2,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppDropdown<AircraftsRow>(
                label: 'Modelo de aeronave',
                icon: Icons.flight_outlined,
                required: true,
                searchable: true,
                // Casa por id (padrão atual) OU por nome — tolerância a
                // unidades antigas que gravaram o nome do modelo na coluna.
                value: aircrafts.firstWhereOrNull((a) =>
                    a.id == _model.dPDEditAircraftsValue ||
                    a.aircraftModel == _model.dPDEditAircraftsValue),
                options: aircrafts,
                labelOf: (a) => a.aircraftModel ?? a.id,
                errorText: _aircraftError,
                onChanged: (a) => setState(() {
                  _model.dPDEditAircraftsValue = a.id;
                  _aircraftError = null;
                }),
              ),
              const SizedBox(height: 14),
              AppFormField(
                controller: _model.tFEditSerialNumberTextController,
                focusNode: _model.tFEditSerialNumberFocusNode,
                label: 'Número de série',
                icon: Icons.tag_rounded,
                required: true,
                validator: (v) => _model
                    .tFEditSerialNumberTextControllerValidator
                    ?.call(context, v),
              ),
              const SizedBox(height: 14),
              _DateField(
                label: 'Data de fabricação',
                date: _model.datePicked2 ?? row.manufactureDate,
                onTap: () => _pickDate(edit: true),
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: AppDropdown<String>(
                      label: 'Ano base',
                      icon: Icons.calendar_today_rounded,
                      required: true,
                      value: _model.dPDEditEntryYearValue,
                      options: _years,
                      labelOf: (y) => y,
                      errorText: _yearError,
                      onChanged: (y) => setState(() {
                        _model.dPDEditEntryYearValue = y;
                        _yearError = null;
                      }),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AppDropdown<String>(
                      label: 'Status',
                      icon: Icons.flag_rounded,
                      required: true,
                      value: _model.dPDEditStatusValue,
                      options: _statuses,
                      labelOf: (s) => s,
                      errorText: _statusError,
                      onChanged: (s) => setState(() {
                        _model.dPDEditStatusValue = s;
                        _statusError = null;
                      }),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AppPrimaryButton(
                    label: 'Salvar alterações',
                    icon: Icons.check_rounded,
                    busy: _busy,
                    onPressed: () => _save(row),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DateField extends StatefulWidget {
  const _DateField({
    required this.label,
    required this.date,
    required this.onTap,
    this.errorText,
    this.enabled = true,
  });

  final String label;
  final DateTime? date;
  final VoidCallback onTap;
  final String? errorText;
  final bool enabled;

  @override
  State<_DateField> createState() => _DateFieldState();
}

class _DateFieldState extends State<_DateField> {
  bool _hover = false;

  String _format(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

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
            children: const [
              TextSpan(text: ' *', style: TextStyle(color: Color(0xFFFF7B82))),
            ],
          ),
        ),
        const SizedBox(height: 6),
        MouseRegion(
          cursor: widget.enabled
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic,
          onEnter: (_) => setState(() => _hover = true),
          onExit: (_) => setState(() => _hover = false),
          child: GestureDetector(
            onTap: widget.enabled ? widget.onTap : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0x14FFFFFF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: hasError
                      ? const Color(0xFFFF7B82).withValues(alpha: 0.85)
                      : (widget.enabled && _hover)
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
                    selected ? _format(widget.date!) : 'Selecionar data...',
                    style: GoogleFonts.roboto(
                      fontSize: 13.5,
                      color: selected
                          ? Colors.white
                          : const Color(0x66FFFFFF),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 13, color: Color(0xFFFF7B82)),
              const SizedBox(width: 4),
              Text(
                widget.errorText!,
                style: GoogleFonts.roboto(
                  fontSize: 11.5,
                  color: const Color(0xFFFF7B82),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

extension _ListExt<T> on List<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (final e in this) {
      if (test(e)) return e;
    }
    return null;
  }
}
