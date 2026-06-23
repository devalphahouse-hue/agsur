import 'dart:math';

/// Utilitários de senha para os formulários de criação de usuário.
///
/// O servidor (GoTrue/Supabase) exige senha forte: mínimo de 8 caracteres
/// **mais** checagem contra vazamentos conhecidos (HIBP/"pwned"). Esse "pwned"
/// só é verificável no servidor, então a única forma de garantir que o cadastro
/// nunca caia no erro 422 `weak_password` é enviar uma senha aleatória longa —
/// que na prática nunca aparece no corpus de vazamentos. Daí o gerador abaixo.

/// Texto único da regra de senha, exibido nos formulários (helper) para casar
/// com o que [strongPasswordValidator] exige. Mantenha os dois em sincronia.
const String kPasswordRuleHint =
    'Mínimo de 8 caracteres, com letras e números.';

// Classes de caracteres sem ambíguos (sem l/I/1, O/0) para a senha ser
// legível caso o admin precise comunicá-la ao piloto/cliente.
const String _lower = 'abcdefghijkmnpqrstuvwxyz';
const String _upper = 'ABCDEFGHJKLMNPQRSTUVWXYZ';
const String _digits = '23456789';
const String _symbols = '!@#\$%&*?-_';

/// Gera uma senha aleatória forte (16 caracteres, com ao menos uma minúscula,
/// uma maiúscula, um dígito e um símbolo). Usa [Random.secure].
String generateStrongPassword({int length = 16}) {
  final rng = Random.secure();
  const all = _lower + _upper + _digits + _symbols;
  // Garante uma de cada classe; completa o restante aleatoriamente.
  final chars = <String>[
    _lower[rng.nextInt(_lower.length)],
    _upper[rng.nextInt(_upper.length)],
    _digits[rng.nextInt(_digits.length)],
    _symbols[rng.nextInt(_symbols.length)],
  ];
  while (chars.length < length) {
    chars.add(all[rng.nextInt(all.length)]);
  }
  chars.shuffle(rng);
  return chars.join();
}

/// Validador client-side de senha forte para usar nos formulários. Não substitui
/// a checagem do servidor (pwned), mas reduz os casos que chegam a falhar:
/// exige ao menos 8 caracteres, com letra e número.
String? strongPasswordValidator(String? val) {
  if (val == null || val.isEmpty) {
    return 'Campo obrigatório';
  }
  if (val.length < 8) {
    return 'A senha deve conter o mínimo de 8 caracteres';
  }
  final hasLetter = val.contains(RegExp(r'[A-Za-z]'));
  final hasNumber = val.contains(RegExp(r'[0-9]'));
  if (!hasLetter || !hasNumber) {
    return 'A senha deve conter letras e números';
  }
  return null;
}

/// Detecta, a partir do corpo de erro do GoTrue, se a falha foi por senha fraca
/// (mínimo de caracteres ou senha vazada/pwned). O corpo deve vir em minúsculas.
bool isWeakPasswordError(String errBodyLower) {
  return errBodyLower.contains('weak_password') ||
      errBodyLower.contains('known to be weak') ||
      errBodyLower.contains('password should be at least');
}

/// Resultado da avaliação de força de senha, consumido pelo medidor visual.
class PasswordStrength {
  const PasswordStrength({
    required this.score,
    required this.label,
    required this.meetsMinLength,
    required this.meetsLetterAndNumber,
  });

  /// 0..4 — quantidade de barras preenchidas no medidor.
  final int score;

  /// Rótulo exibido ('Fraca' / 'Média' / 'Forte'); vazio quando sem senha.
  final String label;

  /// Atende ao mínimo de 8 caracteres.
  final bool meetsMinLength;

  /// Contém letras e números.
  final bool meetsLetterAndNumber;

  /// Atende aos requisitos obrigatórios (os mesmos de [strongPasswordValidator]).
  bool get acceptable => meetsMinLength && meetsLetterAndNumber;
}

/// Avalia a força da senha enquanto o usuário digita. Os requisitos
/// obrigatórios (8+ caracteres, letras e números) batem com
/// [strongPasswordValidator]; comprimento >= 12 e símbolos somam força extra.
PasswordStrength evaluatePasswordStrength(String v) {
  final hasLetter = v.contains(RegExp(r'[A-Za-z]'));
  final hasNumber = v.contains(RegExp(r'[0-9]'));
  final hasSymbol = v.contains(RegExp(r'[^A-Za-z0-9]'));
  final meetsMinLength = v.length >= 8;
  final meetsLetterAndNumber = hasLetter && hasNumber;

  var score = 0;
  if (v.isNotEmpty) {
    if (meetsMinLength) score++;
    if (v.length >= 12) score++;
    if (meetsLetterAndNumber) score++;
    if (hasSymbol) score++;
  }

  String label;
  if (v.isEmpty) {
    label = '';
  } else if (!meetsMinLength || !meetsLetterAndNumber || score <= 1) {
    label = 'Fraca';
  } else if (score == 2) {
    label = 'Média';
  } else {
    label = 'Forte';
  }

  return PasswordStrength(
    score: score,
    label: label,
    meetsMinLength: meetsMinLength,
    meetsLetterAndNumber: meetsLetterAndNumber,
  );
}
