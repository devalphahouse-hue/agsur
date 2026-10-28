import 'package:flutter/material.dart';

/// Local theme: the legacy app theme is light while the panel shell is dark.
class CommercialTheme extends StatelessWidget {
  const CommercialTheme({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Theme(
      data: ThemeData.dark(useMaterial3: true).copyWith(
        colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFC2D51C), brightness: Brightness.dark),
        cardTheme: const CardThemeData(color: Color(0xFF404040)),
      ),
      child: child);
}
