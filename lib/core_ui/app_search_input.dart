import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Input de busca com debounce. Notifica `onChanged` somente após
/// `debounce` (default 280ms) sem digitação — evita N requests.
class AppSearchInput extends StatefulWidget {
  const AppSearchInput({
    super.key,
    required this.value,
    required this.onChanged,
    this.placeholder = 'Buscar...',
    this.debounce = const Duration(milliseconds: 280),
    this.width = 320,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final String placeholder;
  final Duration debounce;
  final double width;

  @override
  State<AppSearchInput> createState() => _AppSearchInputState();
}

class _AppSearchInputState extends State<AppSearchInput> {
  late final TextEditingController _controller;
  Timer? _debouncer;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant AppSearchInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value &&
        widget.value != _controller.text) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _debouncer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String v) {
    _debouncer?.cancel();
    _debouncer = Timer(widget.debounce, () {
      if (mounted) widget.onChanged(v);
    });
  }

  void _clear() {
    _controller.clear();
    widget.onChanged('');
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      child: Focus(
        onFocusChange: (f) => setState(() => _focused = f),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: const Color(0x14FFFFFF),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _focused
                  ? const Color(0xFFC2D51C).withValues(alpha: 0.6)
                  : const Color(0x22FFFFFF),
              width: 1.4,
            ),
            boxShadow: _focused
                ? [
                    BoxShadow(
                      color: const Color(0xFFC2D51C).withValues(alpha: 0.15),
                      blurRadius: 12,
                      spreadRadius: -2,
                    ),
                  ]
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(
                  Icons.search_rounded,
                  size: 18,
                  color: _focused
                      ? const Color(0xFFC2D51C)
                      : const Color(0x99FFFFFF),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    onChanged: _onChanged,
                    style: GoogleFonts.roboto(
                      color: Colors.white,
                      fontSize: 13.5,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: widget.placeholder,
                      hintStyle: GoogleFonts.roboto(
                        color: const Color(0x99FFFFFF),
                        fontSize: 13.5,
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                if (_controller.text.isNotEmpty)
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: _clear,
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(
                        Icons.close_rounded,
                        size: 14,
                        color: Color(0x99FFFFFF),
                      ),
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
