import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '/backend/notes.dart';
import '/backend/phone.dart';
import '/flutter_flow/flutter_flow_theme.dart';

import '/backend/supabase/supabase.dart';
import '/security/write_guard.dart';

import '/core_ui/core_ui.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'modal_register_note_model.dart';
import 'whatsapp_reminder_history.dart';

export 'modal_register_note_model.dart';

class ModalRegisterNoteWidget extends StatefulWidget {
  const ModalRegisterNoteWidget({
    super.key,
    required this.leadId,
    required this.onSaved,
  });

  final String? leadId;

  /// Refresh the parent after the atomic backend save.
  final Future<void> Function()? onSaved;

  @override
  State<ModalRegisterNoteWidget> createState() =>
      _ModalRegisterNoteWidgetState();
}

class _ModalRegisterNoteWidgetState extends State<ModalRegisterNoteWidget> {
  late ModalRegisterNoteModel _model;
  bool _busy = false;
  bool _reminder = false;
  bool _consent = false;
  bool _loadingRecipients = false;
  String _recipientType = 'cliente';
  List<Map<String, dynamic>> _recipients = [];
  final Set<String> _selected = {};
  DateTime? _scheduledAt;
  int _recipientRequest = 0;
  final _requestId = const Uuid().v4();
  final _subject = TextEditingController();

  Future<void> _loadRecipients() async {
    final request = ++_recipientRequest;
    setState(() {
      _loadingRecipients = true;
      _selected.clear();
      _recipients = [];
    });
    try {
      final result = await SupaFlow.client.rpc(
        'whatsapp_reminder_recipients',
        params: {'p_lead_id': widget.leadId, 'p_type': _recipientType},
      );
      if (!mounted || request != _recipientRequest) return;
      setState(() {
        _recipients = (result as List)
            .map((r) => Map<String, dynamic>.from(r as Map))
            .toList();
        if (_recipientType != 'equipe' && _recipients.length == 1) {
          _selected.add(_recipients.first['id'] as String);
        }
      });
    } catch (_) {
      if (mounted && request == _recipientRequest) {
        showWriteError(context, 'Não foi possível carregar os destinatários.');
      }
    } finally {
      if (mounted && request == _recipientRequest) {
        setState(() => _loadingRecipients = false);
      }
    }
  }

  Future<void> _pickSchedule() async {
    final now = DateTime.now();
    final day = await showDatePicker(
      context: context,
      initialDate: now,
      builder: (context, child) => Theme(
          data: ThemeData.dark().copyWith(
              colorScheme: ColorScheme.dark(
                  primary: FlutterFlowTheme.of(context).primary)),
          child: child!),
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 730)),
    );
    if (day == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) => Theme(
          data: ThemeData.dark().copyWith(
              colorScheme: ColorScheme.dark(
                  primary: FlutterFlowTheme.of(context).primary)),
          child: child!),
    );
    if (time == null || !mounted) return;
    setState(
      () => _scheduledAt = DateTime(
        day.year,
        day.month,
        day.day,
        time.hour,
        time.minute,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ModalRegisterNoteModel());
    _model.tFNotesTextController ??= TextEditingController();
    _model.tFNotesFocusNode ??= FocusNode();
  }

  @override
  void dispose() {
    _subject.dispose();
    _model.maybeDispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    if (_model.formKey.currentState == null ||
        !_model.formKey.currentState!.validate()) {
      return;
    }
    if (_reminder &&
        (_loadingRecipients ||
            _selected.isEmpty ||
            !_consent ||
            _scheduledAt == null ||
            !_scheduledAt!.isAfter(DateTime.now()))) {
      showWriteError(
        context,
        'Selecione destinatários, uma data futura e confirme a autorização para WhatsApp.',
      );
      return;
    }
    setState(() => _busy = true);
    try {
      await createLeadNote(
        leadId: widget.leadId!,
        note: _model.tFNotesTextController!.text,
        requestId: _requestId,
        reminder: _reminder
            ? {
                'subject': _subject.text,
                'recipient_type': _recipientType,
                'recipient_ids': _selected.toList(),
                'scheduled_at': _scheduledAt!.toUtc().toIso8601String(),
                'consent': _consent,
              }
            : null,
      );
      try {
        await widget.onSaved?.call();
      } catch (_) {
        if (mounted) {
          showWriteError(
              context, 'Nota salva. Reabra a página para atualizar a lista.');
        }
      }
      // Fecha a modal após salvar com sucesso. Usa o context da própria modal
      // para popar o navigator correto (o mesmo em que o showDialog empilhou).
      if (mounted) Navigator.of(context).pop();
    } on PostgrestException catch (error) {
      if (mounted) {
        showWriteError(
            context,
            error.code == 'PGRST202'
                ? 'Os lembretes ainda não estão disponíveis. Fale com o administrador.'
                : error.code == 'P0001'
                    ? error.message
                    : 'Não foi possível salvar. Verifique seus dados e permissões.');
      }
    } catch (_) {
      if (mounted) {
        showWriteError(
          context,
          'Não foi possível salvar. Verifique os telefones, a data e suas permissões.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppModal(
      icon: Icons.sticky_note_2_outlined,
      title: 'Adicionar nota',
      description:
          'Registre informações importantes sobre este lead — visíveis para todo o time comercial.',
      maxWidth: 540,
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          AppSecondaryButton(
            label: 'Cancelar',
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: 10),
          AppPrimaryButton(
            label: 'Salvar nota',
            icon: Icons.check_rounded,
            busy: _busy,
            onPressed: _submit,
          ),
        ],
      ),
      child: Form(
        key: _model.formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppFormField(
              controller: _model.tFNotesTextController,
              focusNode: _model.tFNotesFocusNode,
              label: 'Nota',
              placeholder: 'Escreva aqui...',
              icon: Icons.edit_note_rounded,
              required: true,
              maxLines: 5,
              onChanged: (_) => setState(() {}),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Campo obrigatório';
                return null;
              },
            ),
            TextButton.icon(
              onPressed: _busy || widget.leadId == null
                  ? null
                  : () => showWhatsappReminderHistory(context, widget.leadId!),
              icon: const Icon(Icons.history),
              label: const Text('Histórico de lembretes'),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Lembrete por WhatsApp'),
              value: _reminder,
              onChanged: _busy
                  ? null
                  : (v) {
                      setState(() => _reminder = v);
                      if (v) _loadRecipients();
                    },
            ),
            if (_reminder) ...[
              AppFormField(
                  controller: _subject,
                  label: 'Assunto',
                  placeholder: 'Ex.: reunião de acompanhamento',
                  onChanged: (_) => setState(() {}),
                  validator: (v) => (v?.length ?? 0) > 100
                      ? 'Use até 100 caracteres.'
                      : null),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: _recipientType,
                decoration: const InputDecoration(labelText: 'Destinatário'),
                items: const [
                  DropdownMenuItem(value: 'cliente', child: Text('Cliente')),
                  DropdownMenuItem(
                    value: 'vendedor',
                    child: Text('Vendedor responsável'),
                  ),
                  DropdownMenuItem(
                    value: 'equipe',
                    child: Text('Equipe (selecione os membros)'),
                  ),
                ],
                onChanged: _busy
                    ? null
                    : (v) {
                        if (v == null) return;
                        setState(() {
                          _recipientType = v;
                          _consent = false;
                        });
                        _loadRecipients();
                      },
              ),
              if (_loadingRecipients)
                const LinearProgressIndicator()
              else if (_recipients.isEmpty)
                TextButton(
                  onPressed: _loadRecipients,
                  child: const Text(
                    'Sem destinatários: confira a autorização do cliente, o vendedor ou os membros habilitados na equipe. Tentar novamente',
                  ),
                )
              else
                SizedBox(
                  height: _recipientType == 'equipe' ? 160 : 70,
                  child: ListView(
                    children: _recipients
                        .map(
                          (r) => CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(r['name'] as String),
                            subtitle: Text(
                              '${formatBrDisplay(r['phone'] as String?)}${toE164Br(r['phone'] as String?) == null ? ' · Corrija o telefone' : !isLikelyWhatsApp(r['phone'] as String?) ? ' · Confirme que o número fixo usa WhatsApp' : ''}',
                            ),
                            value: _selected.contains(r['id']),
                            onChanged: _busy
                                ? null
                                : (v) => setState(() {
                                      if (v == true) {
                                        _selected.add(r['id'] as String);
                                      } else {
                                        _selected.remove(r['id']);
                                      }
                                    }),
                          ),
                        )
                        .toList(),
                  ),
                ),
              TextButton.icon(
                onPressed: _busy ? null : _pickSchedule,
                icon: const Icon(Icons.event),
                label: Text(
                  _scheduledAt == null
                      ? 'Escolher data e horário'
                      : dateTimeFormat('dd/MM/yyyy HH:mm', _scheduledAt),
                ),
              ),
              Text(
                'Horário deste dispositivo (${DateTime.now().timeZoneName}).',
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _consent,
                title: const Text(
                  'Confirmo que os destinatários autorizaram receber mensagens no WhatsApp.',
                ),
                onChanged:
                    _busy ? null : (v) => setState(() => _consent = v ?? false),
              ),
              const SizedBox(height: 12),
              const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Prévia da mensagem')),
              Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: const Color(0xFF404040),
                      borderRadius: BorderRadius.circular(8)),
                  child: Text(whatsappPreview(
                      _model.tFNotesTextController!.text,
                      subject: _subject.text))),
              const Text(
                  'A prévia mostra exatamente o conteúdo do template. Quebras de linha viram espaços; textos longos são limitados ao tamanho permitido.'),
            ],
          ],
        ),
      ),
    );
  }
}
