import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';

import '/auth/supabase_auth/auth_util.dart';
import '/backend/supabase/supabase.dart';
import '/core_ui/core_ui.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/security/access_control.dart';
import '/index.dart';
import 'menu_model.dart';

export 'menu_model.dart';

/// Menu lateral.
/// - Recebe `currentPath` do AppShell (fonte-de-verdade do destaque ativo).
/// - MenuModel intacto (campos user/avioes/vendas/mouseRegion*Hovered).
/// - Mesmas rotas / mesma lógica de gating por profile_type.
class MenuWidget extends StatefulWidget {
  const MenuWidget({super.key, this.currentPath = ''});

  /// Caminho atual da rota, vindo do AppShell.
  /// É a fonte-de-verdade do destaque ativo — o widget rebuilda
  /// sempre que esse valor muda. Default vazio é compatibilidade
  /// transitória para telas legadas (Drawer próprio) que ainda não
  /// foram migradas para o AppShell.
  final String currentPath;

  @override
  State<MenuWidget> createState() => _MenuWidgetState();
}

class _MenuWidgetState extends State<MenuWidget> {
  late MenuModel _model;
  bool _disposed = false;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => MenuModel());

    // Auto-expande grupos cuja rota é a inicial.
    _maybeAutoExpand(widget.currentPath);

    SchedulerBinding.instance.addPostFrameCallback((_) async {
      try {
        final user = await QueryCache.fetch<List<UsersRow>>(
          key: 'menu.currentUser:$currentUserUid',
          ttl: const Duration(minutes: 5),
          fetcher: () => UsersTable().queryRows(
            queryFn: (q) => q.eqOrNull('id', currentUserUid),
          ),
        );
        if (_disposed) return;
        _model.user = user;
        safeSetState(() {});
      } catch (_) {}
    });
  }

  @override
  void didUpdateWidget(covariant MenuWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentPath != oldWidget.currentPath) {
      _maybeAutoExpand(widget.currentPath);
    }
  }

  /// Mantém grupos expandidos quando a rota ativa pertence a um deles.
  /// Não recolhe se o usuário já tiver aberto manualmente.
  void _maybeAutoExpand(String path) {
    if (_isVendasRoute(path) && !_model.vendas) _model.vendas = true;
    if (_isAvioesRoute(path) && !_model.avioes) _model.avioes = true;
  }

  @override
  void dispose() {
    _disposed = true;
    _model.maybeDispose();
    super.dispose();
  }

  bool _isActive(String routePath) =>
      widget.currentPath.isNotEmpty && widget.currentPath == routePath;

  bool _isVendasRoute(String path) =>
      path == LeadsWidget.routePath ||
      path == ProposalsWidget.routePath ||
      path == ContractsWidget.routePath ||
      path == ClientsWidget.routePath;

  bool _isAvioesRoute(String path) =>
      path == AvailableAircraftsWidget.routePath ||
      path == CreateCategoryWidget.routePath ||
      path == RegistedAircraftWidget.routePath ||
      path == CreateAircraftWidget.routePath;

  @override
  Widget build(BuildContext context) {
    final user = _model.user?.firstOrNull;
    final role = AccessControl.roleOf(user);
    AccessControl.current = role;
    bool can(String r) => AccessControl.canView(role, r);
    final showFunil = can(LeadsWidget.routeName);
    final showPessoas = can(PilotsWidget.routeName) ||
        can(OficinaWidget.routeName) ||
        can(SellersWidget.routeName) ||
        can(EmployeesWidget.routeName);
    final showOperacao = can(TrackingsWidget.routeName) ||
        can(RegistedAircraftWidget.routeName) ||
        can(ServicesOfferingWidget.routeName) ||
        can(PartQuoteWidget.routeName) ||
        can(GuaranteesWidget.routeName) ||
        can(CertificatesWidget.routeName);
    final showConfig = can(ViewEditRatesWidget.routeName) ||
        can(ViewEditContractTermsWidget.routeName);

    return Container(
      color: const Color(0xFF1B1B1B),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(14, 18, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _MenuHeader(user: user),
            const SizedBox(height: 18),
            const _MenuSectionLabel(label: 'Geral'),
            _MenuItem(
              icon: Icons.dashboard_rounded,
              label: 'Dashboard',
              active: _isActive(HomePageWidget.routePath),
              onTap: () => context.pushNamed(HomePageWidget.routeName),
            ),
            _MenuItem(
              icon: Icons.forum_rounded,
              label: 'Chat',
              active: _isActive(ChatWidget.routePath) ||
                  _isActive(ChatDetailWidget.routePath),
              onTap: () => context.pushNamed(ChatWidget.routeName),
            ),
            // "Solicitações" (ProfileAnalysisWidget) oculto do menu a pedido.
            // A rota /profileAnalysis segue registrada e acessível por URL
            // direta; este era o único ponto de entrada pela UI.
            // if (can(ProfileAnalysisWidget.routeName))
            //   _MenuItem(
            //     icon: Icons.assignment_rounded,
            //     label: 'Solicitações',
            //     active: _isActive(ProfileAnalysisWidget.routePath),
            //     onTap: () =>
            //         context.pushNamed(ProfileAnalysisWidget.routeName),
            //   ),
            if (showFunil) ...[
              const SizedBox(height: 16),
              const _MenuSectionLabel(label: 'Funil de vendas'),
              _MenuExpandable(
                icon: Icons.point_of_sale_rounded,
                label: 'Vendas',
                expanded: _model.vendas,
                active: _isVendasRoute(widget.currentPath),
                onToggle: () =>
                    safeSetState(() => _model.vendas = !_model.vendas),
                children: [
                  _MenuSubItem(
                    icon: Icons.person_search_rounded,
                    label: 'Leads',
                    active: _isActive(LeadsWidget.routePath),
                    onTap: () => context.pushNamed(LeadsWidget.routeName),
                  ),
                  _MenuSubItem(
                    icon: Icons.request_quote_outlined,
                    label: 'Propostas',
                    active: _isActive(ProposalsWidget.routePath),
                    onTap: () => context.pushNamed(ProposalsWidget.routeName),
                  ),
                  _MenuSubItem(
                    icon: Icons.description_outlined,
                    label: 'Contratos',
                    active: _isActive(ContractsWidget.routePath),
                    onTap: () => context.pushNamed(ContractsWidget.routeName),
                  ),
                  _MenuSubItem(
                    icon: Icons.groups_outlined,
                    label: 'Clientes',
                    active: _isActive(ClientsWidget.routePath),
                    onTap: () => context.pushNamed(ClientsWidget.routeName),
                  ),
                ],
              ),
            ],
            if (showPessoas) ...[
              const SizedBox(height: 16),
              const _MenuSectionLabel(label: 'Pessoas'),
              if (can(PilotsWidget.routeName))
                _MenuItem(
                  icon: Icons.person_outline_rounded,
                  label: 'Pilotos',
                  active: _isActive(PilotsWidget.routePath),
                  onTap: () => context.pushNamed(PilotsWidget.routeName),
                ),
              if (can(OficinaWidget.routeName))
                _MenuItem(
                  icon: Icons.build_outlined,
                  label: 'Oficinas',
                  active: _isActive(OficinaWidget.routePath),
                  onTap: () => context.pushNamed(OficinaWidget.routeName),
                ),
              if (can(SellersWidget.routeName))
                _MenuItem(
                  icon: Icons.business_center_outlined,
                  label: 'Vendedores',
                  active: _isActive(SellersWidget.routePath),
                  onTap: () => context.pushNamed(SellersWidget.routeName),
                ),
              if (can(EmployeesWidget.routeName))
                _MenuItem(
                  icon: Icons.badge_outlined,
                  label: 'Colaboradores',
                  active: _isActive(EmployeesWidget.routePath),
                  onTap: () => context.pushNamed(EmployeesWidget.routeName),
                ),
            ],
            if (showOperacao) ...[
              const SizedBox(height: 16),
              const _MenuSectionLabel(label: 'Operação'),
              if (can(TrackingsWidget.routeName))
                _MenuItem(
                  icon: Icons.timeline_rounded,
                  label: 'Rastreamento',
                  active: _isActive(TrackingsWidget.routePath),
                  onTap: () => context.pushNamed(TrackingsWidget.routeName),
                ),
              if (can(RegistedAircraftWidget.routeName))
                _MenuExpandable(
                  icon: Icons.flight_outlined,
                  label: 'Aeronaves',
                  expanded: _model.avioes,
                  active: _isAvioesRoute(widget.currentPath),
                  onToggle: () =>
                      safeSetState(() => _model.avioes = !_model.avioes),
                  children: [
                  _MenuSubItem(
                    icon: Icons.menu_book_outlined,
                    label: 'Catálogo',
                    active: _isActive(RegistedAircraftWidget.routePath) ||
                        _isActive(CreateAircraftWidget.routePath),
                    onTap: () =>
                        context.pushNamed(RegistedAircraftWidget.routeName),
                  ),
                  _MenuSubItem(
                    icon: Icons.warehouse_outlined,
                    label: 'Estoque (unidades)',
                    active: _isActive(AvailableAircraftsWidget.routePath),
                    onTap: () =>
                        context.pushNamed(AvailableAircraftsWidget.routeName),
                  ),
                  _MenuSubItem(
                    icon: Icons.category_outlined,
                    label: 'Categorias',
                    active: _isActive(CreateCategoryWidget.routePath),
                    onTap: () =>
                        context.pushNamed(CreateCategoryWidget.routeName),
                  ),
                ],
              ),
              if (can(ServicesOfferingWidget.routeName))
                _MenuItem(
                  icon: Icons.miscellaneous_services_outlined,
                  label: 'Carta de serviços',
                  active: _isActive(ServicesOfferingWidget.routePath),
                  onTap: () =>
                      context.pushNamed(ServicesOfferingWidget.routeName),
                ),
              if (can(PartQuoteWidget.routeName))
                _MenuItem(
                  icon: Icons.precision_manufacturing_outlined,
                  label: 'Cotação de peças',
                  active: _isActive(PartQuoteWidget.routePath),
                  onTap: () => context.pushNamed(PartQuoteWidget.routeName),
                ),
              if (can(GuaranteesWidget.routeName))
                _MenuItem(
                  icon: Icons.verified_user_outlined,
                  label: 'Garantias',
                  active: _isActive(GuaranteesWidget.routePath),
                  onTap: () => context.pushNamed(GuaranteesWidget.routeName),
                ),
              if (can(CertificatesWidget.routeName))
                _MenuItem(
                  icon: Icons.workspace_premium_outlined,
                  label: 'Certificados',
                  active: _isActive(CertificatesWidget.routePath),
                  onTap: () => context.pushNamed(CertificatesWidget.routeName),
                ),
            ],
            if (showConfig) ...[
              const SizedBox(height: 16),
              const _MenuSectionLabel(label: 'Configurações'),
              if (can(ViewEditRatesWidget.routeName))
                _MenuItem(
                  icon: Icons.percent_rounded,
                  label: 'Taxas e juros',
                  active: _isActive(ViewEditRatesWidget.routePath),
                  onTap: () => context.pushNamed(ViewEditRatesWidget.routeName),
                ),
              if (can(ViewEditContractTermsWidget.routeName))
                _MenuItem(
                  icon: Icons.lan_outlined,
                  label: 'Termos e instruções',
                  active: _isActive(ViewEditContractTermsWidget.routePath),
                  onTap: () =>
                      context.pushNamed(ViewEditContractTermsWidget.routeName),
                ),
            ],
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 20),
            child: _LogoutItem(onLogout: _logout),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    AccessControl.current = PanelRole.none;
    GoRouter.of(context).prepareAuthEvent();
    QueryCache.clear();
    await authManager.signOut();
    GoRouter.of(context).clearRedirectLocation();
    if (!mounted) return;
    context.goNamedAuth(LoginWidget.routeName, context.mounted);
  }
}

// ─────────────────────── HEADER ───────────────────────
class _MenuHeader extends StatelessWidget {
  const _MenuHeader({required this.user});
  final UsersRow? user;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFC2D51C).withValues(alpha: 0.10),
            const Color(0xFFC2D51C).withValues(alpha: 0.0),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: const AppAssetImage(
              'assets/images/Logo_AEROTG_NEGATIVO_V.png',
              width: 56,
              height: 56,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AGSur Painel',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user?.fullname ?? 'Usuário',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.roboto(
                    fontSize: 11.5,
                    color: const Color(0xCCFFFFFF),
                  ),
                ),
                const SizedBox(height: 4),
                AppStatusBadge(
                  label: user?.profileType ?? '—',
                  tone: AppStatusTone.brand,
                  icon: Icons.shield_outlined,
                  dense: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────── SECTION LABEL ───────────────────────
class _MenuSectionLabel extends StatelessWidget {
  const _MenuSectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.6,
          color: const Color(0x66FFFFFF),
        ),
      ),
    );
  }
}

// ─────────────────────── ITEM ───────────────────────
class _MenuItem extends StatefulWidget {
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  State<_MenuItem> createState() => _MenuItemState();
}

class _MenuItemState extends State<_MenuItem> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final emphasized = widget.active || _hover;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: () {
          widget.onTap();
          closeAppShellDrawer();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: widget.active
                ? const Color(0x33C2D51C)
                : (_hover
                    ? const Color(0x22C2D51C)
                    : Colors.transparent),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.active
                  ? const Color(0x88C2D51C)
                  : (_hover
                      ? const Color(0x44C2D51C)
                      : Colors.transparent),
            ),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: emphasized
                      ? const Color(0x55C2D51C)
                      : Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  widget.icon,
                  size: 16,
                  color: emphasized ? const Color(0xFFC2D51C) : Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.label,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: widget.active
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: widget.active
                        ? const Color(0xFFC2D51C)
                        : Colors.white,
                  ),
                ),
              ),
              if (widget.active)
                Container(
                  width: 4,
                  height: 18,
                  decoration: BoxDecoration(
                    color: const Color(0xFFC2D51C),
                    borderRadius: BorderRadius.circular(2),
                  ),
                )
              else
                AnimatedSlide(
                  duration: const Duration(milliseconds: 180),
                  offset: _hover ? Offset.zero : const Offset(-0.4, 0),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 180),
                    opacity: _hover ? 1 : 0,
                    child: const Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: Color(0xFFC2D51C),
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

// ─────────────────────── EXPANDABLE ───────────────────────
class _MenuExpandable extends StatefulWidget {
  const _MenuExpandable({
    required this.icon,
    required this.label,
    required this.expanded,
    required this.onToggle,
    required this.children,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final bool expanded;
  final bool active;
  final VoidCallback onToggle;
  final List<Widget> children;

  @override
  State<_MenuExpandable> createState() => _MenuExpandableState();
}

class _MenuExpandableState extends State<_MenuExpandable> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.active;
    final emphasized = active || _hover;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hover = true),
          onExit: (_) => setState(() => _hover = false),
          child: GestureDetector(
            onTap: widget.onToggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.symmetric(vertical: 2),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              decoration: BoxDecoration(
                color: active
                    ? const Color(0x33C2D51C)
                    : _hover
                        ? const Color(0x14FFFFFF)
                        : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: active
                      ? const Color(0x88C2D51C)
                      : _hover
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.transparent,
                ),
              ),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: emphasized
                          ? const Color(0x55C2D51C)
                          : Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(
                      widget.icon,
                      size: 16,
                      color: emphasized
                          ? const Color(0xFFC2D51C)
                          : Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.label,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight:
                            active ? FontWeight.w700 : FontWeight.w500,
                        color: active
                            ? const Color(0xFFC2D51C)
                            : Colors.white,
                      ),
                    ),
                  ),
                  if (active)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Container(
                        width: 4,
                        height: 18,
                        decoration: BoxDecoration(
                          color: const Color(0xFFC2D51C),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  AnimatedRotation(
                    duration: const Duration(milliseconds: 220),
                    turns: widget.expanded ? 0.5 : 0,
                    child: Icon(
                      Icons.expand_more_rounded,
                      size: 18,
                      color: emphasized
                          ? const Color(0xCCC2D51C)
                          : const Color(0x99FFFFFF),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOut,
          child: widget.expanded
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(14, 4, 4, 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: widget.children,
                  ),
                )
              : const SizedBox(width: double.infinity, height: 0),
        ),
      ],
    );
  }
}

// ─────────────────────── SUB ITEM ───────────────────────
class _MenuSubItem extends StatefulWidget {
  const _MenuSubItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  State<_MenuSubItem> createState() => _MenuSubItemState();
}

class _MenuSubItemState extends State<_MenuSubItem> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final emphasized = widget.active || _hover;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: () {
          widget.onTap();
          closeAppShellDrawer();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.symmetric(vertical: 1),
          padding: const EdgeInsets.fromLTRB(14, 9, 12, 9),
          decoration: BoxDecoration(
            color: widget.active
                ? const Color(0x22C2D51C)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border(
              left: BorderSide(
                color: emphasized
                    ? const Color(0xFFC2D51C)
                    : Colors.white.withValues(alpha: 0.10),
                width: widget.active ? 3 : 2,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(
                widget.icon,
                size: 14,
                color: emphasized
                    ? const Color(0xFFC2D51C)
                    : const Color(0xCCFFFFFF),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.label,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    color: widget.active
                        ? const Color(0xFFC2D51C)
                        : (_hover ? Colors.white : const Color(0xCCFFFFFF)),
                    fontWeight: emphasized
                        ? FontWeight.w700
                        : FontWeight.w400,
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

// ─────────────────────── LOGOUT ───────────────────────
class _LogoutItem extends StatefulWidget {
  const _LogoutItem({required this.onLogout});
  final Future<void> Function() onLogout;

  @override
  State<_LogoutItem> createState() => _LogoutItemState();
}

class _LogoutItemState extends State<_LogoutItem> {
  bool _hover = false;
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: _busy
            ? null
            : () async {
                setState(() => _busy = true);
                try {
                  await widget.onLogout();
                } finally {
                  if (mounted) setState(() => _busy = false);
                }
              },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: _hover
                ? const Color(0x33FF5963)
                : const Color(0x14FF5963),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _hover
                  ? const Color(0x99FF5963)
                  : const Color(0x33FF5963),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0x33FF5963),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: _busy
                    ? const Padding(
                        padding: EdgeInsets.all(8),
                        child: CircularProgressIndicator(
                          strokeWidth: 1.6,
                          color: Color(0xFFFF7B82),
                        ),
                      )
                    : const Icon(
                        Icons.power_settings_new_rounded,
                        size: 16,
                        color: Color(0xFFFF7B82),
                      ),
              ),
              const SizedBox(width: 12),
              Text(
                _busy ? 'Saindo…' : 'Sair da conta',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFFF7B82),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
