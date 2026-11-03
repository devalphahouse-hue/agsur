import '/backend/paged_query.dart';
import '/backend/supabase/supabase.dart';

class ContactTimelinePage {
  const ContactTimelinePage(
      {required this.notes,
      required this.dispatches,
      this.historyUnavailable = false});
  final PagedResult<Map<String, dynamic>> notes;
  final Map<String, List<Map<String, dynamic>>> dispatches;
  final bool historyUnavailable;
}

/// Both queries are scoped on the server to the person opened in the panel.
/// Notes remain readable if the optional delivery history cannot be loaded.
Future<ContactTimelinePage> loadContactTimeline(String leadId,
    {int page = 1, int perPage = 10}) async {
  final result = await SupaFlow.client
      .from('vw_notes_details')
      .select('id,lead_id,note,created_at,created_by,created_by_name')
      .eq('lead_id', leadId)
      .order('created_at', ascending: false)
      .order('id')
      .range((page - 1) * perPage, page * perPage - 1)
      .count(CountOption.exact);
  final notes = List<Map<String, dynamic>>.from(result.data);
  final grouped = <String, List<Map<String, dynamic>>>{};
  var unavailable = false;
  if (notes.isNotEmpty) {
    try {
      final ids = notes.map((n) => n['id'] as String).toList();
      // Team messages can exceed PostgREST's row limit; paginate the related
      // dispatches too, rather than silently losing recipients after 1000 rows.
      var offset = 0;
      while (true) {
        final history = await SupaFlow.client
            .from('vw_reminder_dispatches')
            .select(
                'id,note_id,lead_id,reminder_id,subject,recipient_name,recipient_type,scheduled_at,sent_at,status,delivery_status,delivery_updated_at,error_code,attempt_count,next_attempt_at,provider')
            .eq('lead_id', leadId)
            .inFilter('note_id', ids)
            .order('created_at')
            .order('id')
            .range(offset, offset + 499)
            .count(CountOption.exact);
        for (final row in history.data) {
          grouped
              .putIfAbsent(row['note_id'] as String, () => [])
              .add(Map<String, dynamic>.from(row));
        }
        offset += history.data.length;
        if (offset >= history.count || history.data.isEmpty) break;
      }
    } catch (_) {
      unavailable = true;
      grouped.clear();
    }
  }
  return ContactTimelinePage(
    notes: PagedResult(
        items: notes, total: result.count, page: page, perPage: perPage),
    dispatches: grouped,
    historyUnavailable: unavailable,
  );
}

String contactDeliveryLabel(Map<String, dynamic> row) {
  if (row['provider'] == 'dryrun') return 'Simulação — não enviado';
  if (row['status'] == 'Cancelado') return 'Cancelado';
  if (row['delivery_status'] == 'failed' || row['status'] == 'Falha') {
    return 'Falha no envio';
  }
  return const {
        'accepted': 'Enviado · aceito pela Meta',
        'sent': 'Enviado',
        'delivered': 'Entregue',
        'read': 'Lido'
      }[row['delivery_status']] ??
      row['status']?.toString() ??
      'Aguardando atualização';
}

String contactFailureMessage(String? code) {
  switch (code) {
    case 'dispatch_outcome_unknown':
      return 'Resultado incerto. Confira se houve envio antes de tentar novamente.';
    case '190':
      return 'A conexão com o WhatsApp precisa ser renovada pelo administrador.';
    case '131026':
      return 'Não foi possível entregar. Confira o telefone do destinatário.';
    case '131042':
      return 'O administrador precisa revisar a configuração da conta WhatsApp.';
    default:
      return 'Não foi possível concluir o envio. Verifique o destinatário e a conexão.';
  }
}
