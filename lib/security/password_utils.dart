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
