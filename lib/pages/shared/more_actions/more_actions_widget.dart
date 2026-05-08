import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'more_actions_model.dart';
export 'more_actions_model.dart';

/// Popup de ações da tela "Solicitações" — aprovar, recusar ou bloquear
/// um usuário. É montado dentro de um AnimatedContainer pelo widget que
/// abre o popup (profile_analysis), então aqui renderizamos apenas o
/// menu redondo, sem overlay próprio.
class MoreActionsWidget extends StatefulWidget {
  const MoreActionsWidget({super.key, required this.userID});

  final String? userID;

  @override
  State<MoreActionsWidget> createState() => _MoreActionsWidgetState();
}

class _MoreActionsWidgetState extends State<MoreActionsWidget> {
  late MoreActionsModel _model;
  String? _busy; // 'approve' | 'refuse' | 'block'

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => MoreActionsModel());
  }

  @override
  void dispose() {
    _model.maybeDispose();
    super.dispose();
  }

  Future<void> _apply(String status, String key) async {
    if (_busy != null) return;
    setState(() => _busy = key);
    try {
      HapticFeedback.selectionClick();
      await UsersTable().update(
        data: {'status': status},
        matchingRows: (rows) => rows.eqOrNull('id', widget.userID),
      );
      if (!mounted) return;
      Navigator.pop(context, status);
    } catch (_) {
      if (mounted) setState(() => _busy = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 196, maxWidth: 220),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.55),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
                child: Row(
                  children: [
                    Icon(
                      Icons.tune_rounded,
                      size: 14,
                      color: Colors.white.withValues(alpha: 0.55),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'AÇÕES',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.6,
                        color: const Color(0x77FFFFFF),
                      ),
                    ),
                  ],
                ),
              ),
              _ActionTile(
                icon: Icons.verified_rounded,
                label: 'Aprovar usuário',
                tone: const Color(0xFF4FBFA9),
                busy: _busy == 'approve',
                onTap: () => _apply('approved', 'approve'),
              ),
              _ActionTile(
                icon: Icons.block_rounded,
                label: 'Recusar usuário',
                tone: const Color(0xFFF9CF58),
                busy: _busy == 'refuse',
                onTap: () => _apply('refused', 'refuse'),
              ),
              _ActionTile(
                icon: Icons.do_not_disturb_on_rounded,
                label: 'Bloquear usuário',
                tone: const Color(0xFFFF7B82),
                busy: _busy == 'block',
                onTap: () => _apply('blocked', 'block'),
                last: true,
              ),
              const SizedBox(height: 6),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionTile extends StatefulWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.tone,
    required this.onTap,
    required this.busy,
    this.last = false,
  });

  final IconData icon;
  final String label;
  final Color tone;
  final VoidCallback onTap;
  final bool busy;
  final bool last;

  @override
  State<_ActionTile> createState() => _ActionTileState();
}

class _ActionTileState extends State<_ActionTile> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.busy
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.busy ? null : widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          margin: EdgeInsets.fromLTRB(8, 2, 8, widget.last ? 2 : 2),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            color: _hover
                ? widget.tone.withValues(alpha: 0.14)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _hover
                  ? widget.tone.withValues(alpha: 0.45)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 26,
                height: 26,
                child: widget.busy
                    ? Padding(
                        padding: const EdgeInsets.all(5),
                        child: CircularProgressIndicator(
                          strokeWidth: 1.6,
                          color: widget.tone,
                        ),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          color: widget.tone.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(widget.icon, size: 14, color: widget.tone),
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.label,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: _hover
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.86),
                  ),
                ),
              ),
              AnimatedSlide(
                duration: const Duration(milliseconds: 160),
                offset: _hover ? Offset.zero : const Offset(-0.4, 0),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 160),
                  opacity: _hover ? 1 : 0,
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 14,
                    color: widget.tone,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
