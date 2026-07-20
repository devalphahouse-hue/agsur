import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import '/security/action_feedback.dart';
import '/security/write_guard.dart';
import '/backend/supabase/supabase.dart';
import '/core_ui/core_ui.dart';
import '/flutter_flow/custom_functions.dart' as functions;
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/upload_data.dart';
import 'modal_services_offering_model.dart';

export 'modal_services_offering_model.dart';

class ModalServicesOfferingWidget extends StatefulWidget {
  const ModalServicesOfferingWidget({
    super.key,
    required this.type,
    this.serviceID,
    required this.databaseRefresh,
  });

  final String? type;
  final String? serviceID;
  final Future Function()? databaseRefresh;

  @override
  State<ModalServicesOfferingWidget> createState() =>
      _ModalServicesOfferingWidgetState();
}

class _ModalServicesOfferingWidgetState
    extends State<ModalServicesOfferingWidget> {
  late ModalServicesOfferingModel _model;
  bool _busy = false;
  String? _typeError;
  String? _fileError;
  bool _editPrefilled = false;

  // Modelos de aeronave: multi-seleção a partir do catálogo de aeronaves.
  // Guardados como texto separado por vírgula em `models` (o app casa por
  // "contém", então o formato é compatível).
  List<String> _allModels = const [];
  bool _modelsLoaded = false;
  final Set<String> _selModels = {};
  final Set<String> _selModelsEdit = {};
  String? _modelsError;
  String? _modelsEditError;

  bool get _isRegister => widget.type == 'Register';

  static const _typeOptions = [
    ('Airworthiness Directives', 'Diretrizes de Aeronavegabilidade'),
    ('Service Boletim', 'Service Boletim'),
    ('Service Letter', 'Service Letter'),
  ];

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ModalServicesOfferingModel());
    _model.tFTitleTextController ??= TextEditingController();
    _model.tFTitleFocusNode ??= FocusNode();
    _model.tFModelsTextController ??= TextEditingController();
    _model.tFModelsFocusNode ??= FocusNode();
    _model.tFTitleEditTextController ??= TextEditingController();
    _model.tFTitleEditFocusNode ??= FocusNode();
    _model.tFModelsEditTextController ??= TextEditingController();
    _model.tFModelsEditFocusNode ??= FocusNode();
    _loadModels();
  }

  @override
  void dispose() {
    _model.maybeDispose();
    super.dispose();
  }

  /// Carrega os modelos distintos do catálogo de aeronaves para o seletor.
  Future<void> _loadModels() async {
    final rows = await AircraftsTable().queryRows(
      queryFn: (q) => q.eqOrNull('deleted', false),
    );
    final models = <String>{};
    for (final r in rows) {
      final m = r.aircraftModel.trim();
      if (m.isNotEmpty) models.add(m);
    }
    if (!mounted) return;
    setState(() {
      _allModels = models.toList()..sort();
      _modelsLoaded = true;
    });
  }

  void _setModels(Set<String> target, TextEditingController controller,
      Set<String> selection) {
    setState(() {
      target
        ..clear()
        ..addAll(selection);
      controller.text = target.join(', ');
      _modelsError = null;
      _modelsEditError = null;
    });
  }

  Future<void> _pickFile({required bool edit}) async {
    final selectedFiles = await selectFiles(
      multiFile: false,
      allowedExtensions: ['pdf'],
    );
    if (selectedFiles == null || selectedFiles.isEmpty) return;
    setState(() {
      if (edit) {
        _model.isDataUploading_uploadPDFEdit = true;
      } else {
        _model.isDataUploading_uploadPDF = true;
      }
    });
    try {
      final uploads = selectedFiles
          .map((m) => FFUploadedFile(
                name: m.storagePath.split('/').last,
                bytes: m.bytes,
                originalFilename: m.originalFilename,
              ))
          .toList();
      final urls = await uploadSupabaseStorageFiles(
        bucketName: 'AGSur',
        selectedFiles: selectedFiles,
      );
      if (uploads.length == selectedFiles.length &&
          urls.length == selectedFiles.length) {
        setState(() {
          if (edit) {
            _model.uploadedLocalFile_uploadPDFEdit = uploads.first;
            _model.uploadedFileUrl_uploadPDFEdit = urls.first;
          } else {
            _model.uploadedLocalFile_uploadPDF = uploads.first;
            _model.uploadedFileUrl_uploadPDF = urls.first;
          }
          _fileError = null;
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Falha no upload do PDF')),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          if (edit) {
            _model.isDataUploading_uploadPDFEdit = false;
          } else {
            _model.isDataUploading_uploadPDF = false;
          }
        });
      }
    }
  }

  Future<void> _create() async {
    if (_busy) return;
    setState(() {
      _typeError = (_model.dpdTypeValue == null ||
              _model.dpdTypeValue!.isEmpty)
          ? 'Selecione o tipo'
          : null;
      _fileError = _model.uploadedFileUrl_uploadPDF.isEmpty
          ? 'Anexe o PDF da carta'
          : null;
      _modelsError =
          _selModels.isEmpty ? 'Selecione ao menos um modelo' : null;
    });
    if (_model.formKey1.currentState == null ||
        !_model.formKey1.currentState!.validate()) return;
    if (_typeError != null || _fileError != null || _modelsError != null) {
      return;
    }
    setState(() => _busy = true);
    try {
      await ServicesOfferingTable().insert({
        'service_title': _model.tFTitleTextController!.text,
        'doc_url': _model.uploadedFileUrl_uploadPDF,
        'type': _model.dpdTypeValue,
        'models': _model.tFModelsTextController!.text,
      });
      await widget.databaseRefresh?.call();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Carta de serviços cadastrada com sucesso!',
              style: TextStyle(color: Color(0xFF313131))),
          backgroundColor: Color(0xFFC2D51C),
        ),
      );
      Navigator.of(context).pop();
    } catch (e, st) {
      // Sem catch a exceção subia para o framework: o botão saía de
      // "carregando" e nada aparecia na tela.
      await Sentry.captureException(e,
          stackTrace: st, withScope: (s) => s.setTag('acao', 'cartas'));
      if (!mounted) return;
      showWriteError(
        context,
        mensagemDeErro(e, fallback: 'Não foi possível salvar a carta de serviço.'),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    if (_busy) return;
    setState(() {
      _fileError = _model.uploadedFileUrl_uploadPDFEdit.isEmpty
          ? 'Anexe o PDF da carta'
          : null;
      _modelsEditError =
          _selModelsEdit.isEmpty ? 'Selecione ao menos um modelo' : null;
    });
    if (_model.formKey2.currentState == null ||
        !_model.formKey2.currentState!.validate()) return;
    if (_fileError != null || _modelsEditError != null) return;
    setState(() => _busy = true);
    try {
      await ServicesOfferingTable().update(
        data: {
          'service_title': _model.tFTitleEditTextController!.text,
          'doc_url': _model.uploadedFileUrl_uploadPDFEdit,
          'type': _model.dpdTypeEditValue,
          'models': _model.tFModelsEditTextController!.text,
        },
        matchingRows: (rows) => rows.eqOrNull('id', widget.serviceID),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Carta de serviços atualizada com sucesso!',
              style: TextStyle(color: Color(0xFF313131))),
          backgroundColor: Color(0xFFC2D51C),
        ),
      );
      Navigator.of(context).pop();
    } catch (e, st) {
      // Sem catch a exceção subia para o framework: o botão saía de
      // "carregando" e nada aparecia na tela.
      await Sentry.captureException(e,
          stackTrace: st, withScope: (s) => s.setTag('acao', 'cartas'));
      if (!mounted) return;
      showWriteError(
        context,
        mensagemDeErro(e, fallback: 'Não foi possível salvar a carta de serviço.'),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppModal(
      icon: Icons.miscellaneous_services_rounded,
      title:
          _isRegister ? 'Cadastrar carta de serviços' : 'Editar carta de serviços',
      description:
          'Selecione o tipo, descreva os modelos atendidos e anexe o PDF da carta.',
      maxWidth: 700,
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          AppSecondaryButton(
            label: 'Cancelar',
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: 10),
          AppPrimaryButton(
            label: _isRegister ? 'Cadastrar' : 'Salvar alterações',
            icon: Icons.check_rounded,
            busy: _busy,
            onPressed: _isRegister ? _create : _save,
          ),
        ],
      ),
      child: _isRegister ? _buildCreate() : _buildEdit(),
    );
  }

  Widget _buildCreate() {
    return Form(
      key: _model.formKey1,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _typeDropdown(
            value: _model.dpdTypeValue,
            onChanged: (v) => setState(() {
              _model.dpdTypeValue = v;
              _typeError = null;
            }),
            errorText: _typeError,
          ),
          const SizedBox(height: 14),
          AppFormField(
            controller: _model.tFTitleTextController,
            focusNode: _model.tFTitleFocusNode,
            label: 'Título',
            placeholder: 'Título da carta',
            icon: Icons.title_rounded,
            required: true,
            validator: (v) =>
                _model.tFTitleTextControllerValidator?.call(context, v),
          ),
          const SizedBox(height: 14),
          _ModelMultiSelect(
            all: _allModels,
            loaded: _modelsLoaded,
            selected: _selModels,
            error: _modelsError,
            onChanged: (sel) =>
                _setModels(_selModels, _model.tFModelsTextController!, sel),
          ),
          const SizedBox(height: 14),
          _PdfUpload(
            label: 'PDF da carta',
            url: _model.uploadedFileUrl_uploadPDF,
            uploading: _model.isDataUploading_uploadPDF,
            errorText: _fileError,
            onTap: () => _pickFile(edit: false),
          ),
        ],
      ),
    );
  }

  Widget _buildEdit() {
    return FutureBuilder<List<ServicesOfferingRow>>(
      future: ServicesOfferingTable().querySingleRow(
        queryFn: (q) => q.eqOrNull('id', widget.serviceID),
      ),
      builder: (context, snap) {
        if (!snap.hasData) {
          return Column(
            children: List.generate(
              4,
              (_) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AppSkeleton.box(height: 60),
              ),
            ),
          );
        }
        final row = snap.data!.isNotEmpty ? snap.data!.first : null;
        if (row != null && !_editPrefilled) {
          _editPrefilled = true;
          _model.tFTitleEditTextController!.text = row.serviceTitle;
          _model.tFModelsEditTextController!.text = row.models ?? '';
          for (final m in (row.models ?? '').split(',')) {
            final t = m.trim();
            if (t.isNotEmpty) _selModelsEdit.add(t);
          }
          _model.dpdTypeEditValue = row.type;
          if (row.docUrl != null && row.docUrl!.isNotEmpty) {
            _model.uploadedFileUrl_uploadPDFEdit = row.docUrl!;
          }
        }
        return Form(
          key: _model.formKey2,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _typeDropdown(
                value: _model.dpdTypeEditValue,
                onChanged: (v) =>
                    setState(() => _model.dpdTypeEditValue = v),
              ),
              const SizedBox(height: 14),
              AppFormField(
                controller: _model.tFTitleEditTextController,
                focusNode: _model.tFTitleEditFocusNode,
                label: 'Título',
                placeholder: 'Título da carta',
                icon: Icons.title_rounded,
                required: true,
                validator: (v) => _model.tFTitleEditTextControllerValidator
                    ?.call(context, v),
              ),
              const SizedBox(height: 14),
              _ModelMultiSelect(
                all: _allModels,
                loaded: _modelsLoaded,
                selected: _selModelsEdit,
                error: _modelsEditError,
                onChanged: (sel) => _setModels(
                    _selModelsEdit, _model.tFModelsEditTextController!, sel),
              ),
              const SizedBox(height: 14),
              _PdfUpload(
                label: 'PDF da carta',
                url: _model.uploadedFileUrl_uploadPDFEdit,
                uploading: _model.isDataUploading_uploadPDFEdit,
                errorText: _fileError,
                onTap: () => _pickFile(edit: true),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _typeDropdown({
    required String? value,
    required ValueChanged<String> onChanged,
    String? errorText,
  }) {
    // Dropdown compacto (menu ancorado ao campo) — o AppDropdown padrão abre
    // um bottom sheet de tela cheia, ruim no desktop.
    final current = (value == null || value.isEmpty) ? null : value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Tipo',
                style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.85))),
            Text(' *',
                style: GoogleFonts.inter(
                    fontSize: 12.5, color: const Color(0xFFE05656))),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF232323),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: errorText != null
                  ? const Color(0xFFE05656)
                  : Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.layers_outlined,
                  size: 18, color: Color(0xCCFFFFFF)),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: current,
                    isExpanded: true,
                    hint: Text('Selecione o tipo...',
                        style: GoogleFonts.roboto(
                            color: const Color(0x80FFFFFF), fontSize: 14)),
                    dropdownColor: const Color(0xFF262626),
                    borderRadius: BorderRadius.circular(12),
                    icon: const Icon(Icons.keyboard_arrow_down_rounded,
                        color: Color(0xCCFFFFFF)),
                    style:
                        GoogleFonts.roboto(color: Colors.white, fontSize: 14),
                    items: _typeOptions
                        .map((e) => DropdownMenuItem(
                            value: e.$1, child: Text(e.$2)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) onChanged(v);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 6),
          Text(errorText,
              style: GoogleFonts.roboto(
                  fontSize: 11.5, color: const Color(0xFFE05656))),
        ],
      ],
    );
  }
}

class _PdfUpload extends StatefulWidget {
  const _PdfUpload({
    required this.label,
    required this.url,
    required this.uploading,
    required this.onTap,
    this.errorText,
  });

  final String label;
  final String url;
  final bool uploading;
  final VoidCallback onTap;
  final String? errorText;

  @override
  State<_PdfUpload> createState() => _PdfUploadState();
}

class _PdfUploadState extends State<_PdfUpload> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;
    final hasFile = widget.url.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hover = true),
          onExit: (_) => setState(() => _hover = false),
          child: GestureDetector(
            onTap: widget.uploading ? null : widget.onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                color: hasFile
                    ? const Color(0x22C2D51C)
                    : const Color(0x14FFFFFF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: hasError
                      ? const Color(0xFFFF7B82).withValues(alpha: 0.85)
                      : hasFile
                          ? const Color(0x88C2D51C)
                          : _hover
                              ? const Color(0xFFC2D51C).withValues(alpha: 0.5)
                              : const Color(0x22FFFFFF),
                  width: 1.4,
                ),
              ),
              child: Row(
                children: [
                  if (widget.uploading)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.8,
                        color: Color(0xFFC2D51C),
                      ),
                    )
                  else
                    Icon(
                      hasFile
                          ? Icons.picture_as_pdf_rounded
                          : Icons.upload_file_rounded,
                      size: 16,
                      color: hasFile
                          ? const Color(0xFFC2D51C)
                          : const Color(0x99FFFFFF),
                    ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.uploading
                          ? 'Enviando arquivo...'
                          : hasFile
                              ? functions.fileNamePath(widget.url)
                              : 'Anexar PDF',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.roboto(
                        fontSize: 13,
                        color: hasFile
                            ? Colors.white
                            : const Color(0x88FFFFFF),
                        fontWeight:
                            hasFile ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ),
                  if (hasFile) ...[
                    // Visualizar o PDF anexado em nova aba antes de salvar,
                    // para conferir se o documento está correto.
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () => openStorageDoc(widget.url),
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: const Color(0x22C2D51C),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.visibility_outlined,
                            size: 16,
                            color: Color(0xFFC2D51C),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.swap_horiz_rounded,
                        size: 16, color: Color(0xCCFFFFFF)),
                  ],
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

/// Campo dropdown de modelos de aeronave: abre um diálogo com busca e
/// checkboxes (multi-seleção). Escala bem mesmo com muitos modelos.
class _ModelMultiSelect extends StatelessWidget {
  const _ModelMultiSelect({
    required this.all,
    required this.loaded,
    required this.selected,
    required this.onChanged,
    this.error,
  });

  final List<String> all;
  final bool loaded;
  final Set<String> selected;
  final void Function(Set<String>) onChanged;
  final String? error;

  Future<void> _open(BuildContext context) async {
    final result = await showDialog<Set<String>>(
      context: context,
      builder: (_) => _ModelPickerDialog(all: all, initial: selected),
    );
    if (result != null) onChanged(result);
  }

  @override
  Widget build(BuildContext context) {
    final hasError = error != null;
    final enabled = loaded && all.isNotEmpty;
    final placeholder = !loaded
        ? 'Carregando modelos...'
        : (all.isEmpty ? 'Nenhum modelo cadastrado' : 'Selecione os modelos');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            text: 'Modelos de aeronave',
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
        InkWell(
          onTap: enabled ? () => _open(context) : null,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0x14FFFFFF),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color:
                    hasError ? const Color(0xCCFF7B82) : const Color(0x22FFFFFF),
                width: 1.4,
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.flight_outlined,
                    size: 16, color: Color(0x99FFFFFF)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    selected.isEmpty
                        ? placeholder
                        : '${selected.length} selecionado(s): ${selected.join(', ')}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.roboto(
                      fontSize: 13.5,
                      color: selected.isEmpty
                          ? const Color(0x66FFFFFF)
                          : Colors.white,
                    ),
                  ),
                ),
                const Icon(Icons.expand_more_rounded,
                    color: Color(0xFFC2D51C), size: 20),
              ],
            ),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 8),
          Text(
            error!,
            style: GoogleFonts.roboto(
                fontSize: 12, color: const Color(0xFFFF7B82)),
          ),
        ],
      ],
    );
  }
}

/// Diálogo de seleção de modelos: busca + lista com checkboxes.
class _ModelPickerDialog extends StatefulWidget {
  const _ModelPickerDialog({required this.all, required this.initial});
  final List<String> all;
  final Set<String> initial;

  @override
  State<_ModelPickerDialog> createState() => _ModelPickerDialogState();
}

class _ModelPickerDialogState extends State<_ModelPickerDialog> {
  late final Set<String> _sel = {...widget.initial};
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.all
        .where((m) => m.toLowerCase().contains(_q.toLowerCase()))
        .toList();
    return Dialog(
      backgroundColor: const Color(0xFF2A2A2A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460, maxHeight: 560),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Modelos de aeronave',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded,
                        color: Color(0x99FFFFFF)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                autofocus: true,
                onChanged: (v) => setState(() => _q = v),
                style: GoogleFonts.roboto(color: Colors.white, fontSize: 13.5),
                decoration: InputDecoration(
                  hintText: 'Buscar modelo...',
                  hintStyle: GoogleFonts.roboto(
                      color: const Color(0x66FFFFFF), fontSize: 13.5),
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: Color(0x99FFFFFF), size: 20),
                  filled: true,
                  fillColor: const Color(0x14FFFFFF),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: filtered.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          'Nenhum modelo encontrado.',
                          style: GoogleFonts.roboto(
                              fontSize: 13, color: const Color(0x99FFFFFF)),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: filtered.length,
                        itemBuilder: (_, i) {
                          final m = filtered[i];
                          final on = _sel.contains(m);
                          return InkWell(
                            onTap: () => setState(
                                () => on ? _sel.remove(m) : _sel.add(m)),
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 12),
                              child: Row(
                                children: [
                                  Icon(
                                    on
                                        ? Icons.check_box_rounded
                                        : Icons.check_box_outline_blank_rounded,
                                    color: on
                                        ? const Color(0xFFC2D51C)
                                        : const Color(0x66FFFFFF),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      m,
                                      style: GoogleFonts.roboto(
                                          fontSize: 14, color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AppSecondaryButton(
                    label: 'Cancelar',
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 10),
                  AppPrimaryButton(
                    label: 'Concluir (${_sel.length})',
                    icon: Icons.check_rounded,
                    onPressed: () => Navigator.pop(context, _sel),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
