import 'package:aligned_dialog/aligned_dialog.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/backend/supabase/supabase.dart';
import '/core_ui/core_ui.dart';
import '/pages/shared/more_actions/more_actions_widget.dart';
import 'profile_analysis_model.dart';

export 'profile_analysis_model.dart';

class ProfileAnalysisWidget extends StatefulWidget {
  const ProfileAnalysisWidget({super.key});

  static String routeName = 'ProfileAnalysis';
  static String routePath = '/profileAnalysis';

  @override
  State<ProfileAnalysisWidget> createState() => _ProfileAnalysisWidgetState();
}

class _ProfileAnalysisWidgetState extends State<ProfileAnalysisWidget> {
  late ProfileAnalysisModel _model;
  String _status = 'pending';
  int _refreshKey = 0;

  @override
  void initState() {
    super.initState();
    _model = ProfileAnalysisModel();
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  Future<List<UsersRow>> _fetch() {
    return UsersTable().queryRows(
      queryFn: (q) => q
          .eqOrNull('is_deleted', false)
          .neqOrNull('status', 'approved')
          .eqOrNull('status', _status)
          .order('created_at'),
    );
  }

  void _setStatus(String s) {
    if (_status == s) return;
    setState(() {
      _status = s;
      _refreshKey++;
    });
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'blocked':
        return 'Bloqueado';
      case 'refused':
        return 'Rejeitado';
      default:
        return 'Pendente';
    }
  }

  AppStatusTone _statusTone(String s) {
    switch (s) {
      case 'blocked':
        return AppStatusTone.danger;
      case 'refused':
        return AppStatusTone.warning;
      default:
        return AppStatusTone.brand;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppListScaffold(
      eyebrow: 'Pessoas',
      title: 'Análise de perfil',
      description:
          'Solicitações de cadastro recebidas. Filtre por status e aprove, recuse ou bloqueie cada perfil.',
      actions: [
        _StatusFilter(
          current: _status,
          onChanged: _setStatus,
        ),
      ],
      body: FutureBuilder<List<UsersRow>>(
        key: ValueKey('profile_analysis_$_status$_refreshKey'),
        future: _fetch(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return Column(
              children: List.generate(
                3,
                (_) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AppSkeleton.box(height: 96),
                ),
              ),
            );
          }
          final items = snap.data!;
          if (items.isEmpty) {
            return AppCard(
              child: AppEmptyState(
                icon: Icons.inbox_outlined,
                title:
                    'Nenhuma solicitação ${_statusLabel(_status).toLowerCase()}',
                description: _status == 'pending'
                    ? 'Quando um cliente se cadastrar pelo app, ele aparece aqui para análise.'
                    : 'Não há registros nesse status no momento.',
              ),
            );
          }
          return Column(
            children: [
              for (var i = 0; i < items.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _RequestCard(
                    user: items[i],
                    statusLabel: _statusLabel(items[i].status ?? 'pending'),
                    statusTone: _statusTone(items[i].status ?? 'pending'),
                  ).appStagger(i),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _StatusFilter extends StatelessWidget {
  const _StatusFilter({required this.current, required this.onChanged});

  final String current;
  final ValueChanged<String> onChanged;

  static const _options = [
    ('pending', 'Pendentes', Icons.schedule_rounded),
    ('refused', 'Recusados', Icons.do_not_disturb_alt_rounded),
    ('blocked', 'Bloqueados', Icons.block_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0x14FFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final opt in _options)
            _StatusChip(
              icon: opt.$3,
              label: opt.$2,
              active: current == opt.$1,
              onTap: () => onChanged(opt.$1),
            ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatefulWidget {
  const _StatusChip({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  State<_StatusChip> createState() => _StatusChipState();
}

class _StatusChipState extends State<_StatusChip> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.active;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: active
                ? const Color(0x33C2D51C)
                : _hover
                    ? const Color(0x14C2D51C)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: active
                  ? const Color(0x88C2D51C)
                  : Colors.white.withValues(alpha: 0.04),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 13,
                color: active
                    ? const Color(0xFFC2D51C)
                    : const Color(0xCCFFFFFF),
              ),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  color: active
                      ? const Color(0xFFC2D51C)
                      : const Color(0xCCFFFFFF),
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({
    required this.user,
    required this.statusLabel,
    required this.statusTone,
  });

  final UsersRow user;
  final String statusLabel;
  final AppStatusTone statusTone;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 720;
    return AppCard(
      padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
      child: wide ? _wide(context) : _narrow(context),
    );
  }

  Widget _wide(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _Avatar(name: user.name),
        const SizedBox(width: 14),
        Expanded(
          flex: 3,
          child: _PrimaryInfo(
            name: user.name,
            createdAt: user.createdAt,
          ),
        ),
        Expanded(
          flex: 4,
          child: Wrap(
            spacing: 18,
            runSpacing: 6,
            children: [
              _Field(label: 'CPF', value: user.cpf),
              _Field(label: 'E-mail', value: user.email),
              _Field(label: 'Telefone', value: user.phone),
            ],
          ),
        ),
        const SizedBox(width: 12),
        AppStatusBadge(label: statusLabel, tone: statusTone),
        const SizedBox(width: 8),
        _MoreButton(userID: user.id),
      ],
    );
  }

  Widget _narrow(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _Avatar(name: user.name),
            const SizedBox(width: 12),
            Expanded(
              child: _PrimaryInfo(
                name: user.name,
                createdAt: user.createdAt,
              ),
            ),
            AppStatusBadge(label: statusLabel, tone: statusTone),
            const SizedBox(width: 4),
            _MoreButton(userID: user.id),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 18,
          runSpacing: 8,
          children: [
            _Field(label: 'CPF', value: user.cpf),
            _Field(label: 'E-mail', value: user.email),
            _Field(label: 'Telefone', value: user.phone),
          ],
        ),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name});
  final String name;

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    final first = parts.first.characters.first;
    final last = parts.length > 1 ? parts.last.characters.first : '';
    return (first + last).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0x55C2D51C), Color(0x33AEC117)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0x55C2D51C)),
      ),
      child: Center(
        child: Text(
          _initials,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: const Color(0xFFC2D51C),
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

class _PrimaryInfo extends StatelessWidget {
  const _PrimaryInfo({required this.name, required this.createdAt});

  final String name;
  final DateTime? createdAt;

  String _formatDate(DateTime? d) {
    if (d == null) return '—';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          name.isEmpty ? '—' : name,
          style: GoogleFonts.inter(
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: -0.1,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            const Icon(Icons.event_outlined,
                size: 12, color: Color(0x99FFFFFF)),
            const SizedBox(width: 4),
            Text(
              'Solicitado em ${_formatDate(createdAt)}',
              style: GoogleFonts.roboto(
                fontSize: 11.5,
                color: const Color(0x99FFFFFF),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
            color: const Color(0x88FFFFFF),
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value.isEmpty ? '—' : value,
          style: GoogleFonts.roboto(
            fontSize: 12.5,
            color: const Color(0xCCFFFFFF),
          ),
        ),
      ],
    );
  }
}

class _MoreButton extends StatefulWidget {
  const _MoreButton({required this.userID});
  final String userID;

  @override
  State<_MoreButton> createState() => _MoreButtonState();
}

class _MoreButtonState extends State<_MoreButton> {
  bool _hover = false;

  Future<void> _open() async {
    await showAlignedDialog(
      barrierColor: Colors.transparent,
      context: context,
      isGlobal: false,
      avoidOverflow: false,
      targetAnchor: AlignmentDirectional(-2.0, 0.0)
          .resolve(Directionality.of(context)),
      followerAnchor: AlignmentDirectional(1.0, 0.0)
          .resolve(Directionality.of(context)),
      builder: (dialogContext) {
        return Material(
          color: Colors.transparent,
          child: GestureDetector(
            onTap: () {
              FocusScope.of(dialogContext).unfocus();
              FocusManager.instance.primaryFocus?.unfocus();
            },
            child: MoreActionsWidget(userID: widget.userID),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: _open,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: _hover
                ? const Color(0x22C2D51C)
                : Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: _hover
                  ? const Color(0x55C2D51C)
                  : Colors.white.withValues(alpha: 0.06),
            ),
          ),
          child: Icon(
            Icons.more_horiz_rounded,
            size: 16,
            color: _hover ? const Color(0xFFC2D51C) : const Color(0xCCFFFFFF),
          ),
        ),
      ),
    );
  }
}
