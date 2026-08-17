// Helper compartilhado por generate_proposal_pdf.dart e
// generate_contract_pdf.dart. NÃO é uma action FlutterFlow (não entra no
// index.dart) — é importado direto pelas duas.

import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:printing/printing.dart';

// `package:web` é web-only e quebra o build de Android/iOS. A detecção de
// WebKit fica atrás de import condicional: no mobile entra o stub que
// devolve false (e nem chega a ser consultado, porque kIsWeb é false).
import 'webkit_detect_io.dart'
    if (dart.library.js_interop) 'webkit_detect_web.dart';

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
///
/// No mobile (app das lojas) `kIsWeb` é false e o fluxo cai direto no
/// `Printing.layoutPdf`, que abre o diálogo nativo de impressão/compartilhar
/// do Android e do iOS.
Future<void> abrirPdfGerado(Uint8List bytes, String nomeArquivo) async {
  if (kIsWeb && ehWebKit) {
    await Printing.sharePdf(bytes: bytes, filename: nomeArquivo);
    return;
  }
  await Printing.layoutPdf(onLayout: (_) async => bytes);
}
