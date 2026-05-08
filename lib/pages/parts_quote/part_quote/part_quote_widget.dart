import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/auth/supabase_auth/auth_util.dart';
import '/backend/supabase/supabase.dart';
import '/core_ui/core_ui.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'part_quote_model.dart';

export 'part_quote_model.dart';

class PartQuoteWidget extends StatefulWidget {
  const PartQuoteWidget({super.key});

  static String routeName = 'PartQuote';
  static String routePath = '/partQuote';

  @override
  State<PartQuoteWidget> createState() => _PartQuoteWidgetState();
}

class _PartQuoteWidgetState extends State<PartQuoteWidget> {
  late PartQuoteModel _model;
  String _query = '';
  String _status = 'all';

  static const _statusOptions = [
    MapEntry('all', 'Todos'),
    MapEntry('Em análise', 'Em análise'),
    MapEntry('Aprovado', 'Aprovado'),
    MapEntry('Negado', 'Negado'),
  ];

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => PartQuoteModel());
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppListScaffold(
      eyebrow: 'Configurações',
      title: 'Cotação de peças',
      description:
          'Solicitações de peças vinculadas às suas garantias e cotações.',
      search: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          AppSearchInput(
            value: _query,
            placeholder: 'Buscar por peça, aeronave ou ID...',
            onChanged: (v) => setState(() => _query = v),
          ),
          _FilterChips(
            label: 'Status',
            options: _statusOptions,
            value: _status,
            onChanged: (v) => setState(() => _status = v),
          ),
        ],
      ),
      body: FutureBuilder<List<GuaranteeRow>>(
        future: GuaranteeTable().queryRows(
          queryFn: (q) => q
              .eqOrNull('user_id', currentUserUid)
              .eqOrNull('deleted', false)
              .order('created_at', ascending: false),
        ),
        builder: (context, snap) {
          if (!snap.hasData) {
            return Column(
              children: List.generate(
                4,
                (_) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AppSkeleton.box(height: 86),
                ),
              ),
            );
          }
          final all = snap.data!;
          final list = all.where((g) {
            if (_status != 'all' && g.status != _status) return false;
            if (_query.isEmpty) return true;
            final q = _query.toLowerCase();
            return g.partDescription.toLowerCase().contains(q) ||
                g.partNumber.toLowerCase().contains(q) ||
                g.nameAircraft.toLowerCase().contains(q) ||
                g.idRef.toLowerCase().contains(q);
          }).toList();
          if (list.isEmpty) {
            return AppCard(
              child: AppEmptyState(
                icon: Icons.precision_manufacturing_outlined,
                title: _query.isEmpty
                    ? 'Nenhuma cotação ainda'
                    : 'Nenhuma cotação encontrada',
                description: _query.isEmpty
                    ? 'Solicitações de peças aparecem aqui.'
                    : 'Tente outro termo de busca.',
              ),
            );
          }
          return Column(
            children: [
              for (int i = 0; i < list.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _PartQuoteRow(item: list[i]).appStagger(i),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _PartQuoteRow extends StatelessWidget {
  const _PartQuoteRow({required this.item});
  final GuaranteeRow item;

  AppStatusTone get _statusTone {
    final s = item.status.toLowerCase();
    if (s.contains('aprov')) return AppStatusTone.success;
    if (s.contains('negad') || s.contains('reje')) return AppStatusTone.danger;
    if (s.contains('andam') || s.contains('anál') || s.contains('analise')) {
      return AppStatusTone.warning;
    }
    return AppStatusTone.brand;
  }

  IconData get _statusIcon {
    final s = item.status.toLowerCase();
    if (s.contains('aprov')) return Icons.check_circle_outline;
    if (s.contains('negad')) return Icons.cancel_outlined;
    return Icons.hourglass_empty_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0x33C2D51C),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(Icons.precision_manufacturing_outlined,
                color: Color(0xFFC2D51C), size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      'ID #${item.idRef}',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: Color(0x55FFFFFF),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        item.partDescription,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          color: const Color(0xCCFFFFFF),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    if (item.partNumber.isNotEmpty)
                      _Meta(Icons.tag_rounded, 'P/N ${item.partNumber}'),
                    if (item.nameAircraft.isNotEmpty)
                      _Meta(Icons.flight_outlined, item.nameAircraft),
                    if (item.mechanicShopName.isNotEmpty)
                      _Meta(Icons.build_outlined, item.mechanicShopName),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          AppStatusBadge(
            label: item.status.isEmpty ? '—' : item.status,
            icon: _statusIcon,
            tone: _statusTone,
            dense: true,
          ),
        ],
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta(this.icon, this.text);
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: const Color(0x99FFFFFF)),
        const SizedBox(width: 4),
        Text(
          text,
          style: GoogleFonts.roboto(
            fontSize: 11.5,
            color: const Color(0x99FFFFFF),
          ),
        ),
      ],
    );
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<MapEntry<String, String>> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0x14FFFFFF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0x22FFFFFF)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label:',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: const Color(0x99FFFFFF),
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(width: 8),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isDense: true,
              dropdownColor: const Color(0xFF2A2A2A),
              icon: const Icon(Icons.expand_more_rounded,
                  color: Color(0xFFC2D51C), size: 18),
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              items: [
                for (final opt in options)
                  DropdownMenuItem(value: opt.key, child: Text(opt.value)),
              ],
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
            ),
          ),
        ],
      ),
    );
  }
}
