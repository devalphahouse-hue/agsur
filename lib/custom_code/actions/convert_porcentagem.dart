// Automatic FlutterFlow imports
// Imports other custom actions
// Imports custom functions
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

Future<String> convertPorcentagem(String valor) async {
  try {
    // Parse the string value to double
    double valorDecimal = double.parse(valor);

    // Convert to percentage by multiplying by 100
    double porcentagem = valorDecimal * 100;

    // Return as string with appropriate formatting
    return porcentagem.toString();
  } catch (e) {
    // Handle parsing errors by returning the original value
    return valor;
  }
}
