import 'package:flutter/material.dart';

import '/core_ui/core_ui.dart';

/// Valida formato básico de e-mail (regra única para as telas do funil).
bool isValidEmailFormat(String email) =>
    RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email);

/// Diálogo padrão de edição de e-mail do funil (lead / cliente).
///
/// [onSave] persiste o novo e-mail (já `trim()` + minúsculas) e devolve
/// `true` para fechar o diálogo. Devolvendo `false` ele permanece aberto —
/// o erro (bloqueio de RLS, e-mail em uso, etc.) deve ser sinalizado pelo
/// próprio [onSave] (guardWrite/snackbar). E-mail sem alteração NÃO chama
/// [onSave]. Retorna o e-mail confirmado (alterado ou não), ou `null` se
/// cancelado.
Future<String?> showEditEmailDialog(
  BuildContext context, {
  required String initialEmail,
  required Future<bool> Function(String newEmail) onSave,
  String title = 'Editar e-mail',
  String? description,
  String saveLabel = 'Salvar',
}) {
  return showDialog<String>(
    context: context,
    builder: (dialogContext) => Dialog(
      elevation: 0,
      insetPadding: EdgeInsets.zero,
      backgroundColor: Colors.transparent,
      alignment: AlignmentDirectional(0.0, 0.0)
          .resolve(Directionality.of(dialogContext)),
      child: _EditEmailDialog(
        initialEmail: initialEmail,
        onSave: onSave,
        title: title,
        description: description,
        saveLabel: saveLabel,
      ),
    ),
  );
}

class _EditEmailDialog extends StatefulWidget {
  const _EditEmailDialog({
    required this.initialEmail,
    required this.onSave,
    required this.title,
    this.description,
    this.saveLabel = 'Salvar',
  });

  final String initialEmail;
  final Future<bool> Function(String newEmail) onSave;
  final String title;
  final String? description;
  final String saveLabel;

  @override
  State<_EditEmailDialog> createState() => _EditEmailDialogState();
}

class _EditEmailDialogState extends State<_EditEmailDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialEmail.trim());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final email = _controller.text.trim().toLowerCase();
    if (email == widget.initialEmail.trim().toLowerCase()) {
      // Sem alteração = confirmação: devolve o e-mail sem persistir.
      Navigator.of(context).pop(email);
      return;
    }
    setState(() => _busy = true);
    final ok = await widget.onSave(email);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(email);
    } else {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppModal(
      icon: Icons.alternate_email_rounded,
      title: widget.title,
      description: widget.description,
      maxWidth: 480,
      child: Form(
        key: _formKey,
        child: AppFormField(
          controller: _controller,
          label: 'E-mail',
          icon: Icons.mail_outline_rounded,
          required: true,
          enabled: !_busy,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          validator: (value) {
            final v = (value ?? '').trim();
            if (v.isEmpty) return 'Informe o e-mail.';
            if (!isValidEmailFormat(v)) return 'Informe um e-mail válido.';
            return null;
          },
        ),
      ),
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          AppSecondaryButton(
            label: 'Cancelar',
            onPressed: _busy ? null : () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: 10),
          AppPrimaryButton(
            label: widget.saveLabel,
            icon: Icons.check_rounded,
            busy: _busy,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}
