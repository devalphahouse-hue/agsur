import 'package:flutter/material.dart';

import '/core_ui/core_ui.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'alert_dialog_model.dart';

export 'alert_dialog_model.dart';

class AlertDialogWidget extends StatefulWidget {
  const AlertDialogWidget({
    super.key,
    required this.confirmBtnAction,
    required this.title,
    Color? iconColor,
    Color? btnColor,
  })  : iconColor = iconColor ?? const Color(0xFFC2D51C),
        btnColor = btnColor ?? const Color(0xFFFF5963);

  final Future Function()? confirmBtnAction;
  final String? title;
  final Color iconColor;
  final Color btnColor;

  @override
  State<AlertDialogWidget> createState() => _AlertDialogWidgetState();
}

class _AlertDialogWidgetState extends State<AlertDialogWidget> {
  late AlertDialogModel _model;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AlertDialogModel());
  }

  @override
  void dispose() {
    _model.maybeDispose();
    super.dispose();
  }

  bool get _isDanger {
    final c = widget.btnColor;
    return c.r > 0.7 && c.b < 0.5 && c.g < 0.5;
  }

  Future<void> _confirm() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await widget.confirmBtnAction?.call();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tone = _isDanger ? AppModalTone.danger : AppModalTone.brand;
    return AppModal(
      icon: _isDanger
          ? Icons.warning_amber_rounded
          : Icons.help_outline_rounded,
      title: widget.title ?? 'Deseja confirmar esta ação?',
      iconTone: tone,
      maxWidth: 460,
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          AppSecondaryButton(
            label: 'Cancelar',
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: 10),
          AppPrimaryButton(
            label: _isDanger ? 'Confirmar exclusão' : 'Confirmar',
            icon: Icons.check_rounded,
            busy: _busy,
            onPressed: _confirm,
          ),
        ],
      ),
      child: const SizedBox(height: 4),
    );
  }
}
