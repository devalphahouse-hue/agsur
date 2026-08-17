// Implementação web — a única que importa `package:web` (web-only).
//
// Todo navegador de iOS e o Safari de macOS têm "Safari" no userAgent sem
// "Chrome"/"Chromium" (Chrome de iOS se identifica como "CriOS"). O Chrome
// real sempre inclui "Chrome" — mesma heurística usada pelo pacote printing.
import 'package:web/web.dart' as web;

bool get ehWebKit {
  final ua = web.window.navigator.userAgent;
  return ua.contains('Safari') &&
      !ua.contains('Chrome') &&
      !ua.contains('Chromium');
}
