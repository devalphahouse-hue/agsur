import '/backend/supabase/supabase.dart';

/// Decimal text goes to PostgreSQL numeric without a floating-point calculation.
String? commercialDecimal(String input, {int decimals = 2}) {
  final value = input.trim().replaceAll(',', '.');
  if (!RegExp('^[0-9]{1,12}(\\.[0-9]{1,$decimals})?\$').hasMatch(value)) {
    return null;
  }
  return value;
}

Future<Map<String, dynamic>> commissionStatement({
  required DateTime from,
  required DateTime until,
  String status = 'all',
  String? beneficiary,
  int page = 0,
}) async =>
    Map<String, dynamic>.from(await SupaFlow.client.rpc(
      'commission_statement',
      params: {
        'p_from': from.toUtc().toIso8601String(),
        'p_until': until.toUtc().toIso8601String(),
        'p_status': status,
        'p_beneficiary': beneficiary,
        'p_page': page,
      },
    ) as Map);

String commercialError(Object error) {
  if (error is PostgrestException) {
    if (error.code == 'PGRST202' || error.code == '42P01') {
      return 'Este módulo aguarda a publicação da atualização do banco.';
    }
    if (['23514', '23502', '22003', '22P02'].contains(error.code)) {
      return 'Verifique os valores e os campos obrigatórios.';
    }
    if (error.code == '42501') return 'Seu perfil não permite esta operação.';
    // Only messages deliberately raised by our RPCs are shown to the user.
    if (error.code == 'P0001') return error.message;
    if (error.code == '23505') {
      return 'Já existe um registro para esta operação.';
    }
  }
  return 'Não foi possível confirmar a operação. Atualize a tela antes de tentar novamente.';
}
