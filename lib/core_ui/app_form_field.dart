import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Input padronizado do redesign — fundo escuro translúcido, focus com
/// borda verde-limão e glow, label/placeholder limpos.
class AppFormField extends StatefulWidget {
  const AppFormField({
    super.key,
    this.controller,
    this.focusNode,
    required this.label,
    this.placeholder,
    this.icon,
    this.helper,
    this.required = false,
    this.obscureText = false,
    this.maxLines = 1,
    this.keyboardType,
    this.inputFormatters,
    this.onChanged,
    this.suffix,
    this.enabled = true,
    this.autofillHints,
    this.validator,
    this.autovalidateMode,
    this.textInputAction,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String label;
  final String? placeholder;
  final IconData? icon;
  final String? helper;
  final bool required;
  final bool obscureText;
  final int maxLines;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final Widget? suffix;
  final bool enabled;
  final Iterable<String>? autofillHints;
  final FormFieldValidator<String>? validator;
  final AutovalidateMode? autovalidateMode;
  final TextInputAction? textInputAction;

  @override
  State<AppFormField> createState() => _AppFormFieldState();
}

class _AppFormFieldState extends State<AppFormField> {
  FocusNode? _ownedNode;
  late FocusNode _node;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    if (widget.focusNode != null) {
      _node = widget.focusNode!;
    } else {
      _ownedNode = FocusNode();
      _node = _ownedNode!;
    }
    _node.addListener(_onFocus);
  }

  void _onFocus() {
    if (_focused != _node.hasFocus) {
      setState(() => _focused = _node.hasFocus);
    }
  }

  @override
  void didUpdateWidget(AppFormField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      _node.removeListener(_onFocus);
      _ownedNode?.dispose();
      _ownedNode = null;
      if (widget.focusNode != null) {
        _node = widget.focusNode!;
      } else {
        _ownedNode = FocusNode();
        _node = _ownedNode!;
      }
      _node.addListener(_onFocus);
    }
  }

  @override
  void dispose() {
    _node.removeListener(_onFocus);
    _ownedNode?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      initialValue: widget.controller?.text ?? '',
      validator: widget.validator,
      autovalidateMode: widget.autovalidateMode ??
          (widget.validator != null
              ? AutovalidateMode.onUserInteraction
              : AutovalidateMode.disabled),
      builder: (state) {
        final hasError = state.hasError;
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
                children: [
                  if (widget.required)
                    const TextSpan(
                      text: ' *',
                      style: TextStyle(color: Color(0xFFFF7B82)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              decoration: BoxDecoration(
                color: const Color(0x14FFFFFF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: hasError
                      ? const Color(0xFFFF7B82).withValues(alpha: 0.85)
                      : _focused
                          ? const Color(0xFFC2D51C).withValues(alpha: 0.7)
                          : const Color(0x22FFFFFF),
                  width: 1.4,
                ),
                boxShadow: _focused && !hasError
                    ? [
                        BoxShadow(
                          color: const Color(0xFFC2D51C)
                              .withValues(alpha: 0.18),
                          blurRadius: 14,
                          spreadRadius: -2,
                        ),
                      ]
                    : hasError
                        ? [
                            BoxShadow(
                              color: const Color(0xFFFF5963)
                                  .withValues(alpha: 0.16),
                              blurRadius: 12,
                              spreadRadius: -2,
                            ),
                          ]
                        : null,
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(
                        widget.icon,
                        size: 16,
                        color: hasError
                            ? const Color(0xFFFF7B82)
                            : _focused
                                ? const Color(0xFFC2D51C)
                                : const Color(0x99FFFFFF),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: TextField(
                        controller: widget.controller,
                        focusNode: _node,
                        enabled: widget.enabled,
                        obscureText: widget.obscureText,
                        maxLines: widget.obscureText ? 1 : widget.maxLines,
                        keyboardType: widget.keyboardType,
                        inputFormatters: widget.inputFormatters,
                        autofillHints: widget.autofillHints,
                        textInputAction: widget.textInputAction,
                        style: GoogleFonts.roboto(
                          color: Colors.white,
                          fontSize: 13.5,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          hintText: widget.placeholder,
                          hintStyle: GoogleFonts.roboto(
                            color: const Color(0x66FFFFFF),
                            fontSize: 13.5,
                          ),
                          border: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onChanged: (val) {
                          state.didChange(val);
                          widget.onChanged?.call(val);
                        },
                      ),
                    ),
                    if (widget.suffix != null) widget.suffix!,
                  ],
                ),
              ),
            ),
            if (hasError) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    size: 13,
                    color: Color(0xFFFF7B82),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      state.errorText ?? '',
                      style: GoogleFonts.roboto(
                        fontSize: 11.5,
                        color: const Color(0xFFFF7B82),
                        height: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            ] else if (widget.helper != null && widget.helper!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                widget.helper!,
                style: GoogleFonts.roboto(
                  fontSize: 11.5,
                  color: const Color(0x99FFFFFF),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
