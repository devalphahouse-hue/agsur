import 'package:flutter/material.dart';

import '/core_ui/core_ui.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'modal_register_note_model.dart';

export 'modal_register_note_model.dart';

class ModalRegisterNoteWidget extends StatefulWidget {
  const ModalRegisterNoteWidget({
    super.key,
    required this.leadId,
    required this.btnAction,
  });

  final String? leadId;
  final Future Function(String inputNote)? btnAction;

  @override
  State<ModalRegisterNoteWidget> createState() =>
      _ModalRegisterNoteWidgetState();
}

class _ModalRegisterNoteWidgetState extends State<ModalRegisterNoteWidget> {
  late ModalRegisterNoteModel _model;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ModalRegisterNoteModel());
    _model.tFNotesTextController ??= TextEditingController();
    _model.tFNotesFocusNode ??= FocusNode();
  }

  @override
  void dispose() {
    _model.maybeDispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    if (_model.formKey.currentState == null ||
        !_model.formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await widget.btnAction?.call(_model.tFNotesTextController!.text);
      // Fecha a modal após salvar com sucesso. Usa o context da própria modal
      // para popar o navigator correto (o mesmo em que o showDialog empilhou).
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppModal(
      icon: Icons.sticky_note_2_outlined,
      title: 'Adicionar nota',
      description:
          'Registre informações importantes sobre este lead — visíveis para todo o time comercial.',
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
            label: 'Salvar nota',
            icon: Icons.check_rounded,
            busy: _busy,
            onPressed: _submit,
          ),
        ],
      ),
      child: Form(
        key: _model.formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: AppFormField(
          controller: _model.tFNotesTextController,
          focusNode: _model.tFNotesFocusNode,
          label: 'Nota',
          placeholder: 'Escreva aqui...',
          icon: Icons.edit_note_rounded,
          required: true,
          maxLines: 5,
          validator: (v) =>
              _model.tFNotesTextControllerValidator?.call(context, v),
        ),
      ),
    );
  }
}
