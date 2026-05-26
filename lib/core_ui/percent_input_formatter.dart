import 'package:flutter/services.dart';

/// Máscara de porcentagem: mantém o sufixo "%" fixo e deixa o usuário digitar
/// o número literal (1 -> "1%", 10 -> "10%", 5.5 -> "5.5%"). Não divide por 10.
/// O cursor fica sempre antes do "%".
class PercentInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Normaliza vírgula para ponto e remove tudo que não for dígito/ponto.
    final raw = newValue.text.replaceAll(',', '.');
    final buffer = StringBuffer();
    var dotUsed = false;
    for (final ch in raw.split('')) {
      if (RegExp(r'[0-9]').hasMatch(ch)) {
        buffer.write(ch);
      } else if (ch == '.' && !dotUsed && buffer.isNotEmpty) {
        dotUsed = true;
        buffer.write(ch);
      }
    }
    final clean = buffer.toString();
    if (clean.isEmpty) {
      return const TextEditingValue(text: '');
    }
    final text = '$clean%';
    return TextEditingValue(
      text: text,
      // Cursor antes do "%".
      selection: TextSelection.collapsed(offset: clean.length),
    );
  }
}
