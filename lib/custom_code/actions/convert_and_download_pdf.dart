// Automatic FlutterFlow imports
import '/flutter_flow/flutter_flow_util.dart';
// Imports other custom actions
// Imports custom functions
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'dart:convert';

Future<void> convertAndDownloadPdf(
    String base64String, String proposalIdRef) async {
  // Converte Base64 pra bytes
  final pdfBytes = base64Decode(base64String);

  // Faz o download
  await downloadFile(pdfBytes, proposalIdRef);
}

dynamic downloadFile(Uint8List pdfBytes, String proposalIdRef) {
  return downloadFile(
    pdfBytes,
    'Proposta_${proposalIdRef}.pdf',
  );
}
// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the green button on the right!
