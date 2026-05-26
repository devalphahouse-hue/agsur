import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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

  void _toggleModel(Set<String> target, TextEditingController controller,
      String model) {
    setState(() {
      if (target.contains(model)) {
        target.remove(model);
      } else {
        target.add(model);
      }
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
            onToggle: (m) =>
                _toggleModel(_selModels, _model.tFModelsTextController!, m),
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
                onToggle: (m) => _toggleModel(
                    _selModelsEdit, _model.tFModelsEditTextController!, m),
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
    return AppDropdown<String>(
      label: 'Tipo',
      icon: Icons.layers_outlined,
      placeholder: 'Selecione o tipo...',
      required: true,
      value: value == null || value.isEmpty ? null : value,
      options: _typeOptions.map((e) => e.$1).toList(),
      labelOf: (v) => _typeOptions.firstWhere(
        (e) => e.$1 == v,
        orElse: () => (v, v),
      ).$2,
      errorText: errorText,
      onChanged: onChanged,
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
                  if (hasFile)
                    const Icon(Icons.swap_horiz_rounded,
                        size: 16, color: Color(0xCCFFFFFF)),
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

/// Multi-seleção de modelos de aeronave (chips), a partir do catálogo.
class _ModelMultiSelect extends StatelessWidget {
  const _ModelMultiSelect({
    required this.all,
    required this.loaded,
    required this.selected,
    required this.onToggle,
    this.error,
  });

  final List<String> all;
  final bool loaded;
  final Set<String> selected;
  final void Function(String) onToggle;
  final String? error;

  @override
  Widget build(BuildContext context) {
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
              TextSpan(
                text: ' *',
                style: TextStyle(color: Color(0xFFFF7B82)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (!loaded)
          Row(
            children: const [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Color(0xFFC2D51C)),
              ),
              SizedBox(width: 10),
              Text('Carregando modelos...',
                  style: TextStyle(color: Color(0x99FFFFFF), fontSize: 12.5)),
            ],
          )
        else if (all.isEmpty)
          Text(
            'Nenhum modelo cadastrado. Cadastre aeronaves primeiro.',
            style: GoogleFonts.roboto(
                fontSize: 12.5, color: const Color(0x99FFFFFF)),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final m in all)
                _ModelChip(
                  label: m,
                  selected: selected.contains(m),
                  onTap: () => onToggle(m),
                ),
            ],
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

class _ModelChip extends StatelessWidget {
  const _ModelChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(99),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? const Color(0x33C2D51C) : const Color(0x14FFFFFF),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: selected ? const Color(0xFFC2D51C) : const Color(0x22FFFFFF),
            width: 1.4,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected ? Icons.check_rounded : Icons.flight_outlined,
              size: 14,
              color: selected ? const Color(0xFFC2D51C) : const Color(0x99FFFFFF),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color:
                    selected ? const Color(0xFFC2D51C) : const Color(0xCCFFFFFF),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
