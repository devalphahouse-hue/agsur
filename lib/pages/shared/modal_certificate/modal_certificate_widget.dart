import 'package:flutter/material.dart';

import '/backend/supabase/supabase.dart';
import '/core_ui/core_ui.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'modal_certificate_model.dart';

export 'modal_certificate_model.dart';

class ModalCertificateWidget extends StatefulWidget {
  const ModalCertificateWidget({
    super.key,
    required this.type,
    this.certificateID,
  });

  final String? type;
  final int? certificateID;

  @override
  State<ModalCertificateWidget> createState() => _ModalCertificateWidgetState();
}

class _ModalCertificateWidgetState extends State<ModalCertificateWidget> {
  late ModalCertificateModel _model;
  bool _busy = false;
  bool _editPrefilled = false;

  bool get _isRegister => widget.type == 'Register';

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ModalCertificateModel());
    _model.tFCertificateNameTextController ??= TextEditingController();
    _model.tFCertificateNameFocusNode ??= FocusNode();
    _model.tFEditCertificateNameTextController ??= TextEditingController();
    _model.tFEditCertificateNameFocusNode ??= FocusNode();
  }

  @override
  void dispose() {
    _model.maybeDispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (_busy) return;
    final name = _model.tFCertificateNameTextController!.text.trim();
    if (name.isEmpty) return;
    setState(() => _busy = true);
    try {
      await CertificatesTable().insert({'certificate_name': name});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Certificado cadastrado com sucesso!',
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
    final name = _model.tFEditCertificateNameTextController!.text.trim();
    if (name.isEmpty) return;
    setState(() => _busy = true);
    try {
      await CertificatesTable().update(
        data: {'certificate_name': name},
        matchingRows: (rows) => rows.eqOrNull('id', widget.certificateID),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Alterações salvas com sucesso!',
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
      icon: Icons.workspace_premium_outlined,
      title: _isRegister ? 'Cadastrar certificado' : 'Editar certificado',
      description: _isRegister
          ? 'Cadastre um tipo de certificado disponível para os pilotos.'
          : 'Atualize o nome do certificado.',
      maxWidth: 540,
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
    return AppFormField(
      controller: _model.tFCertificateNameTextController,
      focusNode: _model.tFCertificateNameFocusNode,
      label: 'Certificado',
      placeholder: 'Digite o nome do certificado',
      icon: Icons.workspace_premium_outlined,
      required: true,
      validator: (v) =>
          v == null || v.trim().isEmpty ? 'Campo obrigatório' : null,
    );
  }

  Widget _buildEdit() {
    return FutureBuilder<List<CertificatesRow>>(
      future: CertificatesTable().querySingleRow(
        queryFn: (q) => q.eqOrNull('id', widget.certificateID),
      ),
      builder: (context, snap) {
        if (!snap.hasData) {
          return AppSkeleton.box(height: 60);
        }
        final row = snap.data!.isNotEmpty ? snap.data!.first : null;
        if (row != null && !_editPrefilled) {
          _editPrefilled = true;
          _model.tFEditCertificateNameTextController!.text =
              row.certificateName ?? '';
        }
        return AppFormField(
          controller: _model.tFEditCertificateNameTextController,
          focusNode: _model.tFEditCertificateNameFocusNode,
          label: 'Certificado',
          placeholder: 'Nome do certificado',
          icon: Icons.workspace_premium_outlined,
          required: true,
          validator: (v) =>
              v == null || v.trim().isEmpty ? 'Campo obrigatório' : null,
        );
      },
    );
  }
}
