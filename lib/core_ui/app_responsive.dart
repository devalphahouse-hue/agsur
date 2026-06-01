/// Helpers de responsividade do painel.
///
/// O shell (menu lateral → Drawer) já troca em [kSidebarBreakpoint] = 1024
/// (ver `app_shell.dart`). Aqui ficam os breakpoints de CONTEÚDO, usados para
/// empilhar layouts horizontais quando a tela fica estreita (tablet retrato /
/// celular).
library;

import 'package:flutter/material.dart';

/// Abaixo desta largura, linhas de formulário com várias colunas viram coluna
/// única (campos empilhados). 768 = tablet retrato; acima disso ainda há
/// espaço para 2–3 colunas mesmo sem o menu lateral fixo.
const double kStackBreakpoint = 768;

/// `true` quando a viewport está estreita o bastante para empilhar conteúdo
/// que normalmente fica lado a lado.
bool isStackedWidth(BuildContext context) =>
    MediaQuery.sizeOf(context).width < kStackBreakpoint;

extension ResponsiveContext on BuildContext {
  /// Largura atual da viewport.
  double get screenWidth => MediaQuery.sizeOf(this).width;

  /// `true` em tablet retrato / celular (< [kStackBreakpoint]).
  bool get isStacked => screenWidth < kStackBreakpoint;
}

/// Drop-in para `Row` em linhas de campos lado a lado.
///
/// - **Tela larga** (≥ [breakpoint]): renderiza um `Row` idêntico ao original,
///   preservando os mesmos filhos (`Expanded`/`Flexible` continuam dividindo a
///   largura). Comportamento visual inalterado no desktop.
/// - **Tela estreita** (< [breakpoint]): desempacota cada `Expanded`/`Flexible`
///   e empilha os filhos numa `Column` de largura cheia, separados por
///   [spacing] vertical. Os separadores horizontais (SizedBox só com `width`,
///   típicos de `.divide(SizedBox(width: …))`) são descartados.
///
/// Uso: troque `Row(` por `ResponsiveRow(` numa linha de campos. Os parâmetros
/// `mainAxisSize`, `mainAxisAlignment` e `crossAxisAlignment` são aceitos e
/// repassados ao `Row` no modo largo, então a migração é só renomear o widget.
class ResponsiveRow extends StatelessWidget {
  const ResponsiveRow({
    super.key,
    required this.children,
    this.breakpoint = kStackBreakpoint,
    this.spacing = 16,
    this.mainAxisSize = MainAxisSize.max,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.stackCrossAxisAlignment = CrossAxisAlignment.start,
  });

  final List<Widget> children;
  final double breakpoint;
  final double spacing;
  final MainAxisSize mainAxisSize;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;

  /// Alinhamento horizontal dos campos quando empilhados.
  final CrossAxisAlignment stackCrossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    final stacked = MediaQuery.sizeOf(context).width < breakpoint;

    if (!stacked) {
      return Row(
        mainAxisSize: mainAxisSize,
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        children: children,
      );
    }

    final items = <Widget>[];
    for (final child in children) {
      // Separadores horizontais de `.divide(SizedBox(width: …))` não fazem
      // sentido na vertical — descarta.
      if (child is SizedBox && child.width != null && child.height == null) {
        continue;
      }
      // Expanded/Flexible não podem ir direto numa Column dentro de scroll
      // (altura ilimitada → erro). Desempacota para o filho real.
      final unwrapped = (child is Expanded || child is Flexible)
          ? (child as dynamic).child as Widget
          : child;
      if (items.isNotEmpty) {
        items.add(SizedBox(height: spacing));
      }
      items.add(unwrapped);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: stackCrossAxisAlignment,
      children: items,
    );
  }
}
