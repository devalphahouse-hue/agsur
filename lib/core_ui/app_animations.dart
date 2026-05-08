import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Helpers de animação consistentes em todo o painel.
extension AppFlutterAnimate on Widget {
  /// Fade + slide-up sutil. Use em qualquer elemento que entra na tela.
  Widget appFade({
    Duration delay = Duration.zero,
    Duration duration = const Duration(milliseconds: 380),
  }) {
    return animate(delay: delay)
        .fadeIn(duration: duration, curve: Curves.easeOutCubic)
        .moveY(
          begin: 8,
          end: 0,
          duration: duration,
          curve: Curves.easeOutCubic,
        );
  }

  /// Stagger de N elementos: passa o índice e o widget se anima com 60ms*i.
  Widget appStagger(int index, {Duration step = const Duration(milliseconds: 60)}) {
    return appFade(delay: step * index);
  }
}

/// Curva padrão de "ease out expressivo" — mais cinematográfica.
const Cubic kAppEase = Cubic(0.22, 1, 0.36, 1);
