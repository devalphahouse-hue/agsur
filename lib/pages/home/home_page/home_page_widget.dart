import 'dart:async';

import 'package:aligned_dialog/aligned_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import '/auth/supabase_auth/auth_util.dart';
import '/backend/supabase/supabase.dart';
import '/components/notificaoes_widget.dart';
import '/core_ui/core_ui.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'home_page_model.dart';

export 'home_page_model.dart';

/// Home / Dashboard — redesenhado.
/// Contrato externo preservado:
/// - routeName / routePath idênticos
/// - HomePageModel intacto (menuModel + notificationCount)
/// - Drawer continua usando MenuWidget via wrapWithModel
/// - Mesmas queries: UsersTable, VwHomepageDashboardTable, VwContractDataTable,
///   VwAllTrackingTable (notificações)
/// - Mesma navegação para ProfileAnalysisWidget
class HomePageWidget extends StatefulWidget {
  const HomePageWidget({super.key});

  static String routeName = 'HomePage';
  static String routePath = '/homePage';

  @override
  State<HomePageWidget> createState() => _HomePageWidgetState();
}

class _HomePageWidgetState extends State<HomePageWidget> {
  late HomePageModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => HomePageModel());

    SchedulerBinding.instance.addPostFrameCallback((_) async {
      try {
        // Cache 30s — listagem de tracking pendente (notificações)
        final allTracking = await QueryCache.fetch<List<VwAllTrackingRow>>(
          key: 'home.notificationsCount',
          ttl: const Duration(seconds: 30),
          fetcher: () => VwAllTrackingTable().queryRows(
            queryFn: (q) =>
                q.eqOrNull('isCheck', false).order('user_aircraft_id'),
          ),
        );
        final uniqueAircrafts = <String>{};
        for (final row in allTracking) {
          final key = row.userAircraftId ?? '';
          if (key.isNotEmpty) uniqueAircrafts.add(key);
        }
        if (_disposed) return;
        safeSetState(() {
          _model.notificationCount = uniqueAircrafts.length;
        });
      } catch (_) {
        // Falha silenciosa — mantém badge em 0
      }
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<UsersRow>>(
      future: QueryCache.fetch<List<UsersRow>>(
        key: 'home.currentUser:$currentUserUid',
        ttl: const Duration(minutes: 5),
        fetcher: () => UsersTable().querySingleRow(
          queryFn: (q) => q.eqOrNull('id', currentUserUid),
        ),
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const _HomeLoadingScaffold();
        }
        final users = snapshot.data!;
        final user = users.isNotEmpty ? users.first : null;
        final isAdminMaster = user?.profileType == 'Admin Master';

        final wide =
            MediaQuery.sizeOf(context).width >= kSidebarBreakpoint;

        return GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
            FocusManager.instance.primaryFocus?.unfocus();
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!wide)
                  _MobileTopBar(
                    onOpenDrawer: openAppShellDrawer,
                    onOpenNotifications: (ctx) => _showNotifications(ctx),
                    notificationCount: _model.notificationCount,
                  ),
                AppPageHeader(
                  eyebrow: 'Dashboard',
                  title: 'Olá, ${_firstName(user?.fullname)} 👋',
                  description: isAdminMaster
                      ? 'Visão geral do funil de vendas, contratos em andamento e desempenho da operação.'
                      : 'Acompanhe seus indicadores e fluxos de trabalho.',
                  actions: [
                    if (wide)
                      Builder(
                        builder: (btnCtx) => _IconBubble(
                          icon: FontAwesomeIcons.solidBell,
                          tooltip: 'Notificações',
                          badge: _model.notificationCount,
                          onTap: () => _showNotifications(btnCtx),
                        ),
                      ),
                  ],
                ),
                if (isAdminMaster) ...[
                  const _DashboardKpis(),
                  const SizedBox(height: 24),
                  const _LatestContracts(),
                ] else
                  const _NonAdminWelcome(),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showNotifications(BuildContext anchorContext) async {
    await showAlignedDialog(
      barrierColor: const Color(0x7A000000),
      context: anchorContext,
      isGlobal: false,
      avoidOverflow: true,
      targetAnchor: const AlignmentDirectional(-1.0, 1.0)
          .resolve(Directionality.of(anchorContext)),
      followerAnchor: const AlignmentDirectional(-1.0, -1.0)
          .resolve(Directionality.of(anchorContext)),
      builder: (dialogContext) {
        return Material(
          color: Colors.transparent,
          child: GestureDetector(
            onTap: () {
              FocusScope.of(dialogContext).unfocus();
              FocusManager.instance.primaryFocus?.unfocus();
            },
            child: const NotificaoesWidget(),
          ),
        );
      },
    );
  }

  String _firstName(String? full) {
    if (full == null || full.trim().isEmpty) return 'usuário';
    return full.trim().split(' ').first;
  }
}

// ─────────────────────── MOBILE TOPBAR ───────────────────────
/// Topbar usada apenas em telas estreitas (< [kSidebarBreakpoint]).
/// Em desktop o sino é uma action do AppPageHeader.
class _MobileTopBar extends StatelessWidget {
  const _MobileTopBar({
    required this.onOpenDrawer,
    required this.onOpenNotifications,
    required this.notificationCount,
  });

  final VoidCallback onOpenDrawer;
  final void Function(BuildContext anchorContext) onOpenNotifications;
  final int notificationCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
      ),
      child: Row(
        children: [
          _IconBubble(
            icon: Icons.menu_rounded,
            tooltip: 'Abrir menu',
            onTap: onOpenDrawer,
          ),
          const Spacer(),
          Builder(
            builder: (btnCtx) => _IconBubble(
              icon: FontAwesomeIcons.solidBell,
              tooltip: 'Notificações',
              badge: notificationCount,
              onTap: () => onOpenNotifications(btnCtx),
            ),
          ),
        ],
      ),
    ).appFade();
  }
}

class _IconBubble extends StatefulWidget {
  const _IconBubble({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.badge = 0,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final int badge;

  @override
  State<_IconBubble> createState() => _IconBubbleState();
}

class _IconBubbleState extends State<_IconBubble> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _hover
                  ? const Color(0x22C2D51C)
                  : Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _hover
                    ? const Color(0x55C2D51C)
                    : Colors.white.withValues(alpha: 0.06),
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  widget.icon,
                  size: 18,
                  color: _hover ? const Color(0xFFC2D51C) : Colors.white,
                ),
                if (widget.badge > 0)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 2),
                      constraints:
                          const BoxConstraints(minWidth: 16, minHeight: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF5963),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                            color: const Color(0xFF313131), width: 1.5),
                      ),
                      child: Text(
                        widget.badge > 99 ? '99+' : '${widget.badge}',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1.0,
                        ),
                      ),
                    )
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .scale(
                          begin: const Offset(1, 1),
                          end: const Offset(1.18, 1.18),
                          duration: 1100.ms,
                          curve: Curves.easeInOut,
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


// ─────────────────────── KPIs DASHBOARD ───────────────────────
class _DashboardKpis extends StatelessWidget {
  const _DashboardKpis();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 4, 28, 0),
      child: FutureBuilder<List<VwHomepageDashboardRow>>(
        future: QueryCache.fetch<List<VwHomepageDashboardRow>>(
          key: 'home.dashboard',
          ttl: const Duration(minutes: 1),
          fetcher: () => VwHomepageDashboardTable().querySingleRow(
            queryFn: (q) => q,
          ),
        ),
        builder: (context, snap) {
          if (!snap.hasData) return const _KpiSkeletonGrid();
          final row = snap.data!.isNotEmpty ? snap.data!.first : null;
          final items = _buildKpis(row);

          final width = MediaQuery.sizeOf(context).width;
          int cols;
          if (width >= 1400) {
            cols = 4;
          } else if (width >= 1024) {
            cols = 3;
          } else if (width >= 640) {
            cols = 2;
          } else {
            cols = 1;
          }

          return LayoutBuilder(
            builder: (context, c) {
              const spacing = 16.0;
              final tileWidth = (c.maxWidth - spacing * (cols - 1)) / cols;
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  for (int i = 0; i < items.length; i++)
                    SizedBox(
                      width: tileWidth,
                      child: _KpiCard(item: items[i]).appStagger(i),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  List<_KpiItem> _buildKpis(VwHomepageDashboardRow? r) {
    String fmt(num? v) => v == null
        ? '0'
        : formatNumber(v,
            formatType: FormatType.decimal,
            decimalType: DecimalType.automatic);
    // A view devolve pontos percentuais (-50.00 = -50%), mas
    // FormatType.percent usa NumberFormat.percentPattern, que multiplica por
    // 100 — sem o /100 um crescimento de 12% saía como "1.200%".
    String pct(num? v) => v == null
        ? '0,00%'
        : formatNumber(v / 100, formatType: FormatType.percent);
    String money(num? v) => v == null
        ? r'$ 0'
        : formatNumber(v,
            formatType: FormatType.decimal,
            decimalType: DecimalType.periodDecimal,
            currency: r'$ ');

    return [
      _KpiItem(
        label: 'Prospects / Leads',
        value: fmt(r?.leadsCurrent),
        delta: pct(r?.leadsGrowthPercentage),
        icon: Icons.people_outline_rounded,
        tone: AppStatusTone.brand,
      ),
      _KpiItem(
        label: 'Vendas realizadas',
        value: fmt(r?.salesCurrent),
        delta: pct(r?.salesGrowthPercentage),
        icon: Icons.shopping_bag_outlined,
        tone: AppStatusTone.success,
      ),
      _KpiItem(
        label: 'Aeronaves entregues',
        value: fmt(r?.deliveredCurrent),
        delta: pct(r?.deliveredGrowthPercentage),
        icon: Icons.flight_takeoff_rounded,
        tone: AppStatusTone.teal,
      ),
      _KpiItem(
        label: 'Aeronaves disponíveis',
        value: fmt(r?.availableCurrent),
        delta: pct(r?.availableGrowthPercentage),
        icon: Icons.inventory_2_outlined,
        tone: AppStatusTone.warning,
      ),
      _KpiItem(
        label: 'Propostas ativas',
        value: fmt(r?.proposalsCurrent),
        delta: pct(r?.proposalsGrowthPercentage),
        icon: Icons.request_quote_outlined,
        tone: AppStatusTone.neutral,
      ),
      _KpiItem(
        label: 'Comissão AGSur',
        value: money(r?.companyCommissionCurrent),
        delta: pct(r?.companyCommissionGrowthPercentage),
        icon: Icons.account_balance_wallet_outlined,
        tone: AppStatusTone.brand,
        emphasized: true,
      ),
      _KpiItem(
        label: 'Comissão vendedores',
        value: money(r?.sellerCommissionCurrent),
        delta: pct(r?.sellerCommissionGrowthPercentage),
        icon: Icons.handshake_outlined,
        tone: AppStatusTone.teal,
      ),
      _KpiItem(
        label: 'Faturamento AGSur',
        value: money(r?.revenueCurrent),
        delta: pct(r?.revenueGrowthPercentage),
        icon: Icons.trending_up_rounded,
        tone: AppStatusTone.success,
        emphasized: true,
      ),
    ];
  }
}

class _KpiItem {
  const _KpiItem({
    required this.label,
    required this.value,
    required this.delta,
    required this.icon,
    required this.tone,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final String delta;
  final IconData icon;
  final AppStatusTone tone;
  final bool emphasized;
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.item});
  final _KpiItem item;

  @override
  Widget build(BuildContext context) {
    final isPositive = !item.delta.startsWith('-');

    return AppCard(
      glow: item.emphasized,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _toneBg(item.tone),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(item.icon, size: 18, color: _toneFg(item.tone)),
              ),
              const Spacer(),
              AppStatusBadge(
                label: item.delta,
                icon: isPositive
                    ? Icons.trending_up_rounded
                    : Icons.trending_down_rounded,
                tone: isPositive ? AppStatusTone.success : AppStatusTone.danger,
                dense: true,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            item.label,
            style: GoogleFonts.roboto(
              fontSize: 12.5,
              color: const Color(0xAAFFFFFF),
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

  static Color _toneBg(AppStatusTone t) => switch (t) {
        AppStatusTone.brand => const Color(0x33C2D51C),
        AppStatusTone.success => const Color(0x33249689),
        AppStatusTone.warning => const Color(0x33F9CF58),
        AppStatusTone.danger => const Color(0x33FF5963),
        AppStatusTone.teal => const Color(0x3339D2C0),
        AppStatusTone.neutral => const Color(0x22FFFFFF),
      };

  static Color _toneFg(AppStatusTone t) => switch (t) {
        AppStatusTone.brand => const Color(0xFFD4E657),
        AppStatusTone.success => const Color(0xFF4FBFA9),
        AppStatusTone.warning => const Color(0xFFF9CF58),
        AppStatusTone.danger => const Color(0xFFFF7B82),
        AppStatusTone.teal => const Color(0xFF4FE0D0),
        AppStatusTone.neutral => Colors.white,
      };
}

class _KpiSkeletonGrid extends StatelessWidget {
  const _KpiSkeletonGrid();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    int cols;
    if (width >= 1400) {
      cols = 4;
    } else if (width >= 1024) {
      cols = 3;
    } else if (width >= 640) {
      cols = 2;
    } else {
      cols = 1;
    }
    return LayoutBuilder(
      builder: (context, c) {
        const spacing = 16.0;
        final w = (c.maxWidth - spacing * (cols - 1)) / cols;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: List.generate(
            8,
            (_) => SizedBox(width: w, child: AppSkeleton.box(height: 124)),
          ),
        );
      },
    );
  }
}

// ─────────────────────── ÚLTIMOS CONTRATOS ───────────────────────
class _LatestContracts extends StatelessWidget {
  const _LatestContracts();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 4, 28, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Últimos contratos',
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0x22C2D51C),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'top 5',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFC2D51C),
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () =>
                    context.pushNamed(ContractsWidget.routeName),
                icon: const Icon(Icons.arrow_forward_rounded,
                    size: 14, color: Color(0xFFC2D51C)),
                label: Text(
                  'ver todos',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFC2D51C),
                  ),
                ),
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<VwContractDataRow>>(
            future: QueryCache.fetch<List<VwContractDataRow>>(
              key: 'home.latestContracts',
              ttl: const Duration(minutes: 1),
              fetcher: () => VwContractDataTable().queryRows(
                queryFn: (q) => q.order('created_at'),
              ),
            ),
            builder: (context, snap) {
              if (!snap.hasData) {
                return Column(
                  children: List.generate(
                    3,
                    (i) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: AppSkeleton.box(height: 88),
                    ),
                  ),
                );
              }
              final list = snap.data!.take(5).toList();
              if (list.isEmpty) {
                return const AppCard(
                  child: AppEmptyState(
                    icon: Icons.description_outlined,
                    title: 'Nenhum contrato ainda',
                    description:
                        'Quando uma proposta vira contrato, ela aparece aqui.',
                  ),
                );
              }
              return Column(
                children: [
                  for (int i = 0; i < list.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ContractRow(item: list[i]).appStagger(i),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ContractRow extends StatelessWidget {
  const _ContractRow({required this.item});
  final VwContractDataRow item;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () => context.pushNamed(ContractsWidget.routeName),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFC2D51C), Color(0xFF8FA113)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFC2D51C).withValues(alpha: 0.25),
                  blurRadius: 12,
                  spreadRadius: -2,
                ),
              ],
            ),
            child:
                const Icon(Icons.description_outlined, color: Color(0xFF313131)),
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
                      'ID #${item.idRef ?? '0000000'}',
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
                        item.aircraftModel ?? 'Modelo não informado',
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          color: const Color(0xCCFFFFFF),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.business_outlined,
                        size: 12, color: Color(0x99FFFFFF)),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        item.companyName ?? 'Empresa',
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.roboto(
                          fontSize: 11.5,
                          color: const Color(0x99FFFFFF),
                        ),
                      ),
                    ),
                    if (item.createdByName != null &&
                        item.createdByName!.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.person_outline_rounded,
                          size: 12, color: Color(0x99FFFFFF)),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          item.createdByName!,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.roboto(
                            fontSize: 11.5,
                            color: const Color(0x99FFFFFF),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _money(item.fullprice),
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              AppStatusBadge(
                label: (item.isContract ?? false) ? 'Contrato' : 'Proposta',
                icon: (item.isContract ?? false)
                    ? Icons.verified_outlined
                    : Icons.edit_note_rounded,
                tone: (item.isContract ?? false)
                    ? AppStatusTone.success
                    : AppStatusTone.brand,
                dense: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _money(num? v) {
    if (v == null) return r'$ 0';
    return formatNumber(v,
        formatType: FormatType.decimal,
        decimalType: DecimalType.periodDecimal,
        currency: r'$ ');
  }
}

// ─────────────────────── NÃO ADMIN ───────────────────────
class _NonAdminWelcome extends StatelessWidget {
  const _NonAdminWelcome();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 8, 28, 0),
      child: AppCard(
        padding: const EdgeInsets.all(28),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0x22C2D51C),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.dashboard_rounded,
                  color: Color(0xFFC2D51C), size: 28),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Painel pronto',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Use o menu lateral para acessar suas áreas. Os indicadores gerais ficam disponíveis para administradores.',
                    style: GoogleFonts.roboto(
                      fontSize: 13,
                      color: const Color(0xAAFFFFFF),
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ).appFade(),
    );
  }
}

// ─────────────────────── LOADING SCAFFOLD ───────────────────────
class _HomeLoadingScaffold extends StatelessWidget {
  const _HomeLoadingScaffold();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF313131),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppSkeleton.box(height: 56, width: 320),
              const SizedBox(height: 16),
              AppSkeleton.text(width: 200),
              const SizedBox(height: 24),
              const Expanded(child: _KpiSkeletonGrid()),
            ],
          ),
        ),
      ),
    );
  }
}
