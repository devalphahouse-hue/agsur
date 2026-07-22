// Helper compartilhado por generate_proposal_pdf.dart e
// generate_contract_pdf.dart. NÃO é uma action FlutterFlow (não entra no
// index.dart) — é importado direto pelas duas.

import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:printing/printing.dart';
import 'package:web/web.dart' as web;

/// Entrega o PDF gerado do jeito que o navegador aguenta.
///
/// `Printing.layoutPdf` (diálogo de impressão com preview) funciona no
/// Chrome/Edge/Firefox de desktop, mas não em WebKit: no Safari desktop o
/// print sai de um iframe oculto e vem em branco; no iOS (Safari e também
/// Chrome/Firefox de iOS, que são WebKit) o pacote cai num `click()` com
/// `target=_blank` DEPOIS da geração assíncrona — o gesto do usuário já
/// expirou e o bloqueador de popup engole a aba sem erro nenhum.
///
/// Em WebKit, portanto, o PDF é baixado via `Printing.sharePdf` (âncora com
/// atributo `download`, que não passa pelo bloqueador de popup). Nos demais
/// navegadores o fluxo continua o de sempre.
Future<void> abrirPdfGerado(Uint8List bytes, String nomeArquivo) async {
  if (kIsWeb && _ehWebKit) {
    await Printing.sharePdf(bytes: bytes, filename: nomeArquivo);
    return;
  }
  await Printing.layoutPdf(onLayout: (_) async => bytes);
}

// Todo navegador de iOS e o Safari de macOS têm "Safari" no userAgent sem
// "Chrome"/"Chromium" (Chrome de iOS se identifica como "CriOS"). O Chrome
// real sempre inclui "Chrome" — mesma heurística usada pelo pacote printing.
bool get _ehWebKit {
  final ua = web.window.navigator.userAgent;
  return ua.contains('Safari') &&
      !ua.contains('Chrome') &&
      !ua.contains('Chromium');
}
