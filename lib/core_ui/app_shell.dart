import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '/pages/shared/menu/menu_widget.dart';

/// Largura mínima para exibir o menu lateral fixo. Abaixo disso vira Drawer.
const double kSidebarBreakpoint = 1024;
const double kSidebarWidth = 260;

/// Drawer-key global para que telas internas consigam abrir o Drawer
/// (ex.: botão hambúrguer do AppListScaffold em mobile).
final GlobalKey<ScaffoldState> appShellScaffoldKey =
    GlobalKey<ScaffoldState>();

/// Shell persistente: menu fixo à esquerda + child à direita.
/// Em mobile vira Scaffold com Drawer; em desktop o menu é uma coluna
/// fixa que NÃO é destruída ao trocar de rota — ShellRoute reconstrói
/// só o `child`.
///
/// Lê a rota ativa diretamente do `GoRouter.routeInformationProvider`,
/// que é a fonte canônica da URL atual. Tentativas anteriores de ler
/// via `GoRouterState.of(context)` ou via `state.uri.path` no
/// `ShellRoute.builder` falharam porque devolvem o estado do shell
/// (a rota stub), não da rota filha — o que travava o destaque do menu.
class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  GoRouter? _router;
  String _currentPath = '/';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final router = GoRouter.of(context);
    if (!identical(_router, router)) {
      _router?.routeInformationProvider.removeListener(_syncPath);
      _router = router;
      _router!.routeInformationProvider.addListener(_syncPath);
      _syncPath();
    }
  }

  void _syncPath() {
    final uri = _router?.routeInformationProvider.value.uri;
    final next = (uri == null || uri.path.isEmpty) ? '/' : uri.path;
    if (next != _currentPath && mounted) {
      setState(() => _currentPath = next);
    }
  }

  @override
  void dispose() {
    _router?.routeInformationProvider.removeListener(_syncPath);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= kSidebarBreakpoint;
    final routeKey = _currentPath;

    final menu = MenuWidget(currentPath: routeKey);

    final animatedChild = AnimatedSwitcher(
      duration: const Duration(milliseconds: 160),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      // layoutBuilder simples: mostra só o atual, sem empilhar com o velho.
      layoutBuilder: (currentChild, previousChildren) =>
          currentChild ?? const SizedBox.shrink(),
      transitionBuilder: (child, animation) =>
          FadeTransition(opacity: animation, child: child),
      child: KeyedSubtree(
        key: ValueKey(routeKey),
        child: widget.child,
      ),
    );

    return Scaffold(
      key: appShellScaffoldKey,
      backgroundColor: const Color(0xFF313131),
      drawer: wide ? null : Drawer(elevation: 16.0, child: menu),
      // SafeArea aqui e não nas telas: são 42 usando AppListScaffold/
      // AppDetailsScaffold, e todas desenhavam o topo POR BAIXO da barra de
      // status no iOS — o título saía escrito por cima do relógio. No web é
      // no-op (não há inset), por isso o bug só apareceu ao rodar no device.
      body: SafeArea(
        child: wide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: kSidebarWidth,
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border(
                          right: BorderSide(
                            color: Colors.white.withValues(alpha: 0.06),
                          ),
                        ),
                      ),
                      child: menu,
                    ),
                  ),
                  Expanded(child: animatedChild),
                ],
              )
            : animatedChild,
      ),
    );
  }
}

/// Abre o Drawer global do AppShell (usado pelo botão hambúrguer
/// das telas internas em mobile).
void openAppShellDrawer() {
  appShellScaffoldKey.currentState?.openDrawer();
}

/// Fecha o Drawer global se estiver aberto (no-op no desktop, onde o menu
/// é coluna fixa). Usado pelos itens do menu para sumir o Drawer ao navegar
/// em mobile.
void closeAppShellDrawer() {
  final state = appShellScaffoldKey.currentState;
  if (state?.isDrawerOpen ?? false) {
    state!.closeDrawer();
  }
}
