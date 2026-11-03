import 'package:flutter/material.dart';
import '/backend/supabase/supabase.dart';
import '/backend/phone.dart';
import '/security/write_guard.dart';

Future<void> manageWhatsAppTeam(BuildContext context) async {
  try {
    final rows = List<Map<String, dynamic>>.from(
        await SupaFlow.client.rpc('list_whatsapp_team_members'));
    if (!context.mounted) return;
    final pending = <String>{};
    await showDialog<void>(
        context: context,
        builder: (dialog) => StatefulBuilder(
            builder: (dialog, update) => AlertDialog(
                  title: const Text('Equipe de notificações'),
                  content: SizedBox(
                      width: 500,
                      height: 360,
                      child: Column(children: [
                        const Text(
                            'Habilite somente pessoas que autorizaram o recebimento de avisos pelo WhatsApp.'),
                        Expanded(
                            child: ListView(children: [
                          for (final row in rows)
                            SwitchListTile(
                                title: Text(row['name'] as String),
                                subtitle: Text(
                                    formatBrDisplay(row['phone'] as String?)),
                                value: row['enabled'] == true,
                                onChanged: pending.contains(row['id'])
                                    ? null
                                    : (value) async {
                                        final id = row['id'] as String;
                                        update(() => pending.add(id));
                                        try {
                                          await SupaFlow.client.rpc(
                                              'set_whatsapp_team_member',
                                              params: {
                                                'p_user_id': id,
                                                'p_enabled': value
                                              });
                                          if (dialog.mounted) {
                                            update(
                                                () => row['enabled'] = value);
                                          }
                                        } catch (_) {
                                          if (dialog.mounted) {
                                            showWriteError(dialog,
                                                'Não foi possível atualizar a equipe. Confira telefone e permissões.');
                                          }
                                        } finally {
                                          if (dialog.mounted) {
                                            update(() => pending.remove(id));
                                          }
                                        }
                                      })
                        ]))
                      ])),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(dialog),
                        child: const Text('Fechar'))
                  ],
                )));
  } catch (_) {
    if (context.mounted) {
      showWriteError(context, 'Não foi possível carregar a equipe.');
    }
  }
}

Future<void> editWhatsAppPreference(BuildContext context, String leadId) async {
  try {
    final row = await SupaFlow.client
        .from('leads')
        .select('wa_opt_out')
        .eq('id', leadId)
        .single();
    if (!context.mounted) return;
    final blocked = row['wa_opt_out'] == true;
    final confirm = await showDialog<bool>(
        context: context,
        builder: (dialog) => AlertDialog(
              title: Text(blocked
                  ? 'Reativar mensagens do cliente?'
                  : 'Suspender mensagens do cliente?'),
              content: Text(blocked
                  ? 'Reative somente se o cliente autorizou receber mensagens no WhatsApp.'
                  : 'Os envios pendentes para o cliente serão cancelados antes do próximo disparo. Os avisos internos continuam independentes.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(dialog, false),
                    child: const Text('Voltar')),
                TextButton(
                    onPressed: () => Navigator.pop(dialog, true),
                    child: const Text('Confirmar'))
              ],
            ));
    if (confirm != true) return;
    await SupaFlow.client.rpc('set_whatsapp_opt_out',
        params: {'p_lead_id': leadId, 'p_opt_out': !blocked});
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Preferência atualizada.')));
    }
  } catch (_) {
    if (context.mounted) {
      showWriteError(context, 'Não foi possível atualizar a preferência.');
    }
  }
}
