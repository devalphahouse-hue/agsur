import 'package:flutter/material.dart';

import '/flutter_flow/flutter_flow_util.dart';
import 'switch_component_model.dart';

export 'switch_component_model.dart';

/// Switch ativo/inativo customizado — substitui Switch.adaptive (que ficava
/// invisível sobre fundo escuro). Track e thumb visíveis com transição.
/// Mantém a mesma assinatura: initialValue + activeAction + disableAction.
class SwitchComponentWidget extends StatefulWidget {
  const SwitchComponentWidget({
    super.key,
    required this.activeAction,
    required this.disableAction,
    required this.initialValue,
  });

  final Future Function()? activeAction;
  final Future Function()? disableAction;
  final bool? initialValue;

  @override
  State<SwitchComponentWidget> createState() => _SwitchComponentWidgetState();
}

class _SwitchComponentWidgetState extends State<SwitchComponentWidget> {
  late SwitchComponentModel _model;
  bool _busy = false;
  bool _hover = false;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => SwitchComponentModel());
    _model.switchValue = widget.initialValue ?? true;
    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.maybeDispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_busy) return;
    final newValue = !(_model.switchValue ?? false);
    safeSetState(() {
      _model.switchValue = newValue;
      _busy = true;
    });
    try {
      if (newValue) {
        await widget.activeAction?.call();
      } else {
        await widget.disableAction?.call();
      }
    } finally {
      if (mounted) safeSetState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final on = _model.switchValue ?? false;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: _toggle,
        child: Tooltip(
          message: on ? 'Desativar' : 'Ativar',
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            width: 44,
            height: 24,
            padding: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              color: on
                  ? const Color(0xFFC2D51C)
                  : const Color(0x55FFFFFF),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: on
                    ? const Color(0xFFC2D51C)
                    : const Color(0x55FFFFFF),
                width: 1,
              ),
              boxShadow: [
                if (on)
                  BoxShadow(
                    color: const Color(0xFFC2D51C).withValues(
                        alpha: _hover ? 0.45 : 0.22),
                    blurRadius: _hover ? 12 : 6,
                    spreadRadius: -1,
                  ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedAlign(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  alignment:
                      on ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: on
                          ? const Color(0xFF313131)
                          : Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: _busy
                        ? Padding(
                            padding: const EdgeInsets.all(4),
                            child: CircularProgressIndicator(
                              strokeWidth: 1.4,
                              color: on
                                  ? const Color(0xFFC2D51C)
                                  : const Color(0xFF313131),
                            ),
                          )
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
