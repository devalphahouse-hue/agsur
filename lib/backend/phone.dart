/// Mirrors public.phone_to_e164. Existing masked Brazilian phone data is preserved.
String? toE164Br(String? input) {
  var v = (input ?? '').replaceAll(RegExp(r'[^0-9]'), '');
  if (v.startsWith('00')) v = v.substring(2);
  if (v.startsWith('0') && (v.length == 13 || v.length == 14)) {
    v = v.substring(3);
  }
  if (RegExp(r'^([0-9])\1+$').hasMatch(v)) return null;
  if (v.length == 10 || v.length == 11) v = '55$v';
  if ((v.length != 12 && v.length != 13) || !v.startsWith('55')) return null;
  if ((int.tryParse(v.substring(2, 4)) ?? 0) < 11) return null;
  if (v.length == 13 && v[4] != '9') return null;
  if (v.length == 12 && !'2345'.contains(v[4])) return null;
  return '+$v';
}

bool isLikelyWhatsApp(String? value) => toE164Br(value)?.length == 14;

String formatBrDisplay(String? input) {
  final phone = toE164Br(input);
  if (phone == null) return input ?? 'Sem telefone';
  final digits = phone.substring(3);
  final cut = digits.length - 4;
  return '+55 (${digits.substring(0, 2)}) ${digits.substring(2, cut)}-${digits.substring(cut)}';
}

String whatsappParameter(String note, {String subject = ''}) {
  final text = [if (subject.trim().isNotEmpty) subject.trim(), note.trim()]
      .join(' — ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  // PostgreSQL length counts Unicode code points, not UTF-16 code units.
  final runes = text.runes.toList();
  return runes.length > 860
      ? '${String.fromCharCodes(runes.take(859))}…'
      : text;
}

String whatsappPreview(String note, {String subject = ''}) =>
    'Olá! Este é um lembrete da Agsur sobre seu atendimento ou compromisso agendado: '
    '${whatsappParameter(note, subject: subject)}. '
    'Se precisar de ajuda ou reagendar, responda a esta mensagem.';
