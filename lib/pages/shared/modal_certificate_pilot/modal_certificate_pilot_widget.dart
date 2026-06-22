import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/backend/supabase/supabase.dart';
import '/core_ui/core_ui.dart';
import '/flutter_flow/custom_functions.dart' as functions;
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/upload_data.dart';
import 'modal_certificate_pilot_model.dart';

export 'modal_certificate_pilot_model.dart';

class ModalCertificatePilotWidget extends StatefulWidget {
  const ModalCertificatePilotWidget({
    super.key,
    required this.pilotId,
    required this.btnAction,
    required this.pilotName,
  });

  final String? pilotId;
  final Future Function(
    String pilotId,
    int certificateId,
    String docUrl,
    DateTime validity,
  )? btnAction;
  final String? pilotName;

  @override
  State<ModalCertificatePilotWidget> createState() =>
      _ModalCertificatePilotWidgetState();
}

class _ModalCertificatePilotWidgetState
    extends State<ModalCertificatePilotWidget> {
  late ModalCertificatePilotModel _model;
  bool _busy = false;
  String? _certError;
  String? _dateError;
  String? _fileError;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ModalCertificatePilotModel());
    _model.tFPilotNameTextController ??=
        TextEditingController(text: widget.pilotName);
    _model.tFPilotNameFocusNode ??= FocusNode();
  }

  @override
  void dispose() {
    _model.maybeDispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _model.datePicked ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 30),
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
    if (picked != null) {
      setState(() {
        _model.datePicked = DateTime(picked.year, picked.month, picked.day);
        _dateError = null;
      });
    }
  }

  Future<void> _pickFile() async {
    final selectedFiles = await selectFiles(
      multiFile: false,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (selectedFiles == null || selectedFiles.isEmpty) return;
    setState(
        () => _model.isDataUploading_uploadCertificatePilot = true);
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
          _model.uploadedLocalFile_uploadCertificatePilot = uploads.first;
          _model.uploadedFileUrl_uploadCertificatePilot = urls.first;
          _fileError = null;
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Falha no upload do arquivo')),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() =>
            _model.isDataUploading_uploadCertificatePilot = false);
      }
    }
  }

  Future<void> _submit() async {
    if (_busy) return;
    if (_model.formKey.currentState == null ||
        !_model.formKey.currentState!.validate()) return;
    setState(() {
      _certError = _model.dpdCertificateValue == null
          ? 'Selecione o certificado'
          : null;
      _dateError =
          _model.datePicked == null ? 'Selecione a data de validade' : null;
      _fileError = (_model.uploadedFileUrl_uploadCertificatePilot.isEmpty)
          ? 'Anexe o documento do certificado'
          : null;
    });
    if (_certError != null || _dateError != null || _fileError != null) {
      return;
    }
    setState(() => _busy = true);
    try {
      await widget.btnAction?.call(
        widget.pilotId!,
        _model.dpdCertificateValue!,
        _model.uploadedFileUrl_uploadCertificatePilot,
        _model.datePicked!,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppModal(
      icon: Icons.workspace_premium_outlined,
      title: 'Cadastrar certificado do piloto',
      description:
          'Vincule um certificado, defina a validade e anexe o comprovante.',
      maxWidth: 620,
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          AppSecondaryButton(
            label: 'Cancelar',
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: 10),
          AppPrimaryButton(
            label: 'Cadastrar certificado',
            icon: Icons.check_rounded,
            busy: _busy,
            onPressed: _submit,
          ),
        ],
      ),
      child: FutureBuilder<List<CertificatesRow>>(
        future: CertificatesTable().queryRows(
          queryFn: (q) => q.eqOrNull('is_deleted', false),
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
          final certs = snap.data!;
          return Form(
            key: _model.formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppFormField(
                  controller: _model.tFPilotNameTextController,
                  focusNode: _model.tFPilotNameFocusNode,
                  label: 'Piloto',
                  icon: Icons.person_outline_rounded,
                  enabled: false,
                ),
                const SizedBox(height: 14),
                AppDropdown<CertificatesRow>(
                  label: 'Certificado',
                  icon: Icons.workspace_premium_outlined,
                  required: true,
                  searchable: true,
                  placeholder: 'Selecione o certificado...',
                  value: certs.firstWhereOrNull(
                      (c) => c.id == _model.dpdCertificateValue),
                  options: certs,
                  labelOf: (c) => c.certificateName ?? '',
                  errorText: _certError,
                  onChanged: (c) {
                    setState(() {
                      _model.dpdCertificateValue = c.id;
                      _certError = null;
                    });
                  },
                ),
                const SizedBox(height: 14),
                _DateButton(
                  label: 'Validade',
                  date: _model.datePicked,
                  errorText: _dateError,
                  onTap: _pickDate,
                ),
                const SizedBox(height: 14),
                _UploadButton(
                  url: _model.uploadedFileUrl_uploadCertificatePilot,
                  uploading: _model.isDataUploading_uploadCertificatePilot,
                  errorText: _fileError,
                  onTap: _pickFile,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DateButton extends StatefulWidget {
  const _DateButton({
    required this.label,
    required this.date,
    required this.onTap,
    this.errorText,
  });

  final String label;
  final DateTime? date;
  final VoidCallback onTap;
  final String? errorText;

  @override
  State<_DateButton> createState() => _DateButtonState();
}

class _DateButtonState extends State<_DateButton> {
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
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hover = true),
          onExit: (_) => setState(() => _hover = false),
          child: GestureDetector(
            onTap: widget.onTap,
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
                      : _hover
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

class _UploadButton extends StatefulWidget {
  const _UploadButton({
    required this.url,
    required this.uploading,
    required this.onTap,
    this.errorText,
  });

  final String url;
  final bool uploading;
  final VoidCallback onTap;
  final String? errorText;

  @override
  State<_UploadButton> createState() => _UploadButtonState();
}

class _UploadButtonState extends State<_UploadButton> {
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
            text: 'Documento',
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
                          ? Icons.check_circle_outline_rounded
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
                              : 'Anexar certificado (PDF / JPG / PNG)',
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
                    // Visualizar o documento anexado em nova aba antes de
                    // salvar, para conferir se o arquivo está correto.
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () => launchURL(widget.url),
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

extension _ListExt<T> on List<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (final e in this) {
      if (test(e)) return e;
    }
    return null;
  }
}
