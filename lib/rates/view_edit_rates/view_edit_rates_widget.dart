import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/backend/supabase/supabase.dart';
import '/core_ui/core_ui.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'view_edit_rates_model.dart';

export 'view_edit_rates_model.dart';

const _kRatesId = 'ce659e4b-caee-4b88-8d99-46f15c7e9b69';

class ViewEditRatesWidget extends StatefulWidget {
  const ViewEditRatesWidget({super.key});

  static String routeName = 'ViewEditRates';
  static String routePath = '/viewEditRates';

  @override
  State<ViewEditRatesWidget> createState() => _ViewEditRatesWidgetState();
}

class _ViewEditRatesWidgetState extends State<ViewEditRatesWidget> {
  late ViewEditRatesModel _model;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ViewEditRatesModel());
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
      title: 'Taxas de financiamento',
      description:
          'Taxas usadas no cálculo de propostas de financiamento de aeronaves.',
      actions: [
        _PrimaryAction(
          icon: Icons.tune_rounded,
          label: 'Atualizar taxas',
          onTap: () => context.pushNamed(
            CreateRatesWidget.routeName,
            queryParameters: {
              'idFinancialRate':
                  serializeParam(_kRatesId, ParamType.String),
            }.withoutNulls,
          ),
        ),
      ],
      body: FutureBuilder<List<FinancingRatesRow>>(
        future: FinancingRatesTable().querySingleRow(
          queryFn: (q) => q.eqOrNull('id', _kRatesId),
        ),
        builder: (context, snap) {
          if (!snap.hasData) {
            return Column(
              children: List.generate(
                4,
                (_) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AppSkeleton.box(height: 96),
                ),
              ),
            );
          }
          final row = snap.data!.isNotEmpty ? snap.data!.first : null;
          if (row == null) {
            return AppCard(
              child: AppEmptyState(
                icon: Icons.percent_rounded,
                title: 'Taxas não cadastradas',
                description:
                    'Use "Atualizar taxas" para configurar pela primeira vez.',
              ),
            );
          }
          final items = [
            _RateItem(
              label: 'SOFR',
              value: row.sofrRate,
              hint: 'Taxa base usada como referência.',
              icon: Icons.equalizer_rounded,
              tone: AppStatusTone.brand,
            ),
            _RateItem(
              label: 'Juros',
              value: row.interestRate,
              hint: 'Juros somados às propostas.',
              icon: Icons.percent_rounded,
              tone: AppStatusTone.success,
            ),
            _RateItem(
              label: 'Prêmio 5 anos',
              value: row.premiumRateFive,
              hint: 'Prêmio aplicado em planos de até 5 anos.',
              icon: Icons.timeline_rounded,
              tone: AppStatusTone.warning,
            ),
            _RateItem(
              label: 'Prêmio 7 anos',
              value: row.premiumRateSeven,
              hint: 'Prêmio aplicado em planos de até 7 anos.',
              icon: Icons.timeline_rounded,
              tone: AppStatusTone.teal,
            ),
          ];
          return Column(
            children: [
              for (int i = 0; i < items.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _RateRow(item: items[i]).appStagger(i),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _RateItem {
  const _RateItem({
    required this.label,
    required this.value,
    required this.hint,
    required this.icon,
    required this.tone,
  });

  final String label;
  final double value;
  final String hint;
  final IconData icon;
  final AppStatusTone tone;
}

class _RateRow extends StatelessWidget {
  const _RateRow({required this.item});
  final _RateItem item;

  Color get _bg => switch (item.tone) {
        AppStatusTone.brand => const Color(0x33C2D51C),
        AppStatusTone.success => const Color(0x33249689),
        AppStatusTone.warning => const Color(0x33F9CF58),
        AppStatusTone.danger => const Color(0x33FF5963),
        AppStatusTone.teal => const Color(0x3339D2C0),
        AppStatusTone.neutral => const Color(0x22FFFFFF),
      };

  Color get _fg => switch (item.tone) {
        AppStatusTone.brand => const Color(0xFFC2D51C),
        AppStatusTone.success => const Color(0xFF4FBFA9),
        AppStatusTone.warning => const Color(0xFFF9CF58),
        AppStatusTone.danger => const Color(0xFFFF7B82),
        AppStatusTone.teal => const Color(0xFF4FE0D0),
        AppStatusTone.neutral => Colors.white,
      };

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _bg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(item.icon, size: 20, color: _fg),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.label,
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.hint,
                  style: GoogleFonts.roboto(
                    fontSize: 11.5,
                    color: const Color(0x99FFFFFF),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Text(
            '${item.value.toStringAsFixed(2)}%',
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: _fg,
              letterSpacing: -0.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryAction extends StatefulWidget {
  const _PrimaryAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  State<_PrimaryAction> createState() => _PrimaryActionState();
}

class _PrimaryActionState extends State<_PrimaryAction> {
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
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFC2D51C), Color(0xFFAEC117)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFC2D51C)
                    .withValues(alpha: _hover ? 0.45 : 0.25),
                blurRadius: _hover ? 18 : 10,
                spreadRadius: -2,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 16, color: const Color(0xFF313131)),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF313131),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
