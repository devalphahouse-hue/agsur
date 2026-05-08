import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Dropdown padronizado do redesign.
/// Visual idêntico ao [AppFormField] — label + container com focus glow.
/// Quando tocado, abre um bottom sheet com a lista (e busca opcional).
class AppDropdown<T> extends StatefulWidget {
  const AppDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.labelOf,
    required this.onChanged,
    this.placeholder = 'Selecione...',
    this.icon,
    this.helper,
    this.required = false,
    this.searchable = false,
    this.errorText,
    this.enabled = true,
  });

  final String label;
  final T? value;
  final List<T> options;
  final String Function(T) labelOf;
  final ValueChanged<T> onChanged;
  final String placeholder;
  final IconData? icon;
  final String? helper;
  final bool required;
  final bool searchable;
  final String? errorText;
  final bool enabled;

  @override
  State<AppDropdown<T>> createState() => _AppDropdownState<T>();
}

class _AppDropdownState<T> extends State<AppDropdown<T>> {
  bool _hover = false;

  Future<void> _open() async {
    final result = await showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _OptionsSheet<T>(
        title: widget.label,
        options: widget.options,
        labelOf: widget.labelOf,
        searchable: widget.searchable,
        current: widget.value,
      ),
    );
    if (result != null) widget.onChanged(result);
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;
    final selected = widget.value != null;
    final text = selected ? widget.labelOf(widget.value as T) : widget.placeholder;
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
        MouseRegion(
          cursor: widget.enabled
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic,
          onEnter: (_) => setState(() => _hover = true),
          onExit: (_) => setState(() => _hover = false),
          child: GestureDetector(
            onTap: widget.enabled ? _open : null,
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
                boxShadow: _hover && !hasError
                    ? [
                        BoxShadow(
                          color: const Color(0xFFC2D51C)
                              .withValues(alpha: 0.12),
                          blurRadius: 12,
                          spreadRadius: -2,
                        ),
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  if (widget.icon != null) ...[
                    Icon(
                      widget.icon,
                      size: 16,
                      color: hasError
                          ? const Color(0xFFFF7B82)
                          : selected
                              ? const Color(0xFFC2D51C)
                              : const Color(0x99FFFFFF),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      text,
                      style: GoogleFonts.roboto(
                        fontSize: 13.5,
                        color: selected
                            ? Colors.white
                            : const Color(0x66FFFFFF),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: _hover
                        ? const Color(0xFFC2D51C)
                        : const Color(0x99FFFFFF),
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
              Expanded(
                child: Text(
                  widget.errorText!,
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
  }
}

class _OptionsSheet<T> extends StatefulWidget {
  const _OptionsSheet({
    required this.title,
    required this.options,
    required this.labelOf,
    required this.searchable,
    required this.current,
  });

  final String title;
  final List<T> options;
  final String Function(T) labelOf;
  final bool searchable;
  final T? current;

  @override
  State<_OptionsSheet<T>> createState() => _OptionsSheetState<T>();
}

class _OptionsSheetState<T> extends State<_OptionsSheet<T>> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final filtered = _query.isEmpty
        ? widget.options
        : widget.options
            .where((o) => widget
                .labelOf(o)
                .toLowerCase()
                .contains(_query.toLowerCase()))
            .toList();
    final maxH = MediaQuery.sizeOf(context).height * 0.7;
    return Container(
      constraints: BoxConstraints(maxHeight: maxH),
      decoration: const BoxDecoration(
        color: Color(0xFF2A2A2A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.1,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded,
                        size: 18, color: Color(0xCCFFFFFF)),
                  ),
                ],
              ),
            ),
            if (widget.searchable)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: TextField(
                  autofocus: true,
                  onChanged: (v) => setState(() => _query = v),
                  style: GoogleFonts.roboto(
                    color: Colors.white,
                    fontSize: 13.5,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Buscar...',
                    hintStyle: GoogleFonts.roboto(
                      color: const Color(0x66FFFFFF),
                      fontSize: 13.5,
                    ),
                    prefixIcon: const Icon(Icons.search_rounded,
                        size: 18, color: Color(0x99FFFFFF)),
                    isDense: true,
                    filled: true,
                    fillColor: const Color(0x14FFFFFF),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                          color: Color(0xFFC2D51C), width: 1.2),
                    ),
                  ),
                ),
              ),
            Flexible(
              child: filtered.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Text(
                          'Nenhum resultado',
                          style: GoogleFonts.roboto(
                            color: const Color(0x99FFFFFF),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 4),
                      itemBuilder: (ctx, i) {
                        final opt = filtered[i];
                        final selected = opt == widget.current;
                        return _OptionTile(
                          label: widget.labelOf(opt),
                          selected: selected,
                          onTap: () => Navigator.of(context).pop(opt),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionTile extends StatefulWidget {
  const _OptionTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_OptionTile> createState() => _OptionTileState();
}

class _OptionTileState extends State<_OptionTile> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: widget.selected
                ? const Color(0x33C2D51C)
                : _hover
                    ? const Color(0x14FFFFFF)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: widget.selected
                  ? const Color(0x88C2D51C)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.label,
                  style: GoogleFonts.roboto(
                    fontSize: 13.5,
                    color: widget.selected
                        ? const Color(0xFFC2D51C)
                        : const Color(0xEEFFFFFF),
                    fontWeight:
                        widget.selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
              if (widget.selected)
                const Icon(Icons.check_rounded,
                    size: 16, color: Color(0xFFC2D51C)),
            ],
          ),
        ),
      ),
    );
  }
}
