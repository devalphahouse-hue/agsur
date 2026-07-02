import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/auth/supabase_auth/auth_util.dart';
import '/backend/supabase/supabase.dart';
import '/core_ui/core_ui.dart';
import '/flutter_flow/upload_data.dart';

/// Rota de conversa (usada no mobile, via push). No desktop a conversa é
/// renderizada inline pela [ChatWidget] usando [ChatConversationView].
class ChatDetailWidget extends StatelessWidget {
  const ChatDetailWidget({
    super.key,
    required this.threadId,
    this.otherName,
    this.otherProfile,
  });

  final String? threadId;
  final String? otherName;
  final String? otherProfile;

  static String routeName = 'ChatDetail';
  static String routePath = '/chatDetail';

  @override
  Widget build(BuildContext context) {
    return ChatConversationView(
      threadId: threadId,
      otherName: otherName,
      otherProfile: otherProfile,
      showBackButton: true,
    );
  }
}

/// Conteúdo da conversa 1:1 (cabeçalho + mensagens em realtime + composer).
/// Reutilizado pela rota mobile e pelo painel de detalhe do desktop.
/// Layout próprio (não usa AppDetailsScaffold porque precisa de uma área de
/// mensagens com scroll independente + input fixo no rodapé).
class ChatConversationView extends StatefulWidget {
  const ChatConversationView({
    super.key,
    required this.threadId,
    this.otherName,
    this.otherProfile,
    this.showBackButton = false,
  });

  final String? threadId;
  final String? otherName;
  final String? otherProfile;
  final bool showBackButton;

  @override
  State<ChatConversationView> createState() => _ChatConversationViewState();
}

class _ChatConversationViewState extends State<ChatConversationView> {
  final TextEditingController _input = TextEditingController();
  final FocusNode _inputFocus = FocusNode();
  late final Stream<List<ChatMessagesRow>> _messages;
  bool _sending = false;
  String? _lastReadMarkedId;

  @override
  void initState() {
    super.initState();
    _messages = SupaFlow.client
        .from('chat_messages')
        .stream(primaryKey: ['id'])
        .eq('thread_id', widget.threadId ?? '')
        .order('created_at', ascending: false)
        .map((rows) => rows.map((r) => ChatMessagesRow(r)).toList());
    _markRead();
  }

  @override
  void dispose() {
    _input.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  Future<void> _markRead() async {
    if (widget.threadId == null) return;
    try {
      await ChatParticipantsTable().update(
        data: {'last_read_at': DateTime.now().toUtc().toIso8601String()},
        matchingRows: (rows) => rows
            .eq('thread_id', widget.threadId!)
            .eq('user_id', currentUserUid),
      );
    } catch (_) {
      // marcação de leitura é best-effort; não bloqueia o chat.
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF5A2A2D),
      ),
    );
  }

  Future<void> _sendText() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending || widget.threadId == null) return;
    setState(() => _sending = true);
    try {
      await ChatMessagesTable().insert({
        'thread_id': widget.threadId,
        'sender_id': currentUserUid,
        'body': text,
      });
      _input.clear();
    } catch (_) {
      _showError('Não foi possível enviar a mensagem.');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _sendAttachment() async {
    if (_sending || widget.threadId == null) return;
    final files = await selectFiles(
      storageFolderPath: widget.threadId,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'gif', 'webp', 'heic', 'pdf'],
      multiFile: false,
    );
    if (files == null || files.isEmpty) return;
    setState(() => _sending = true);
    try {
      final urls = await uploadSupabaseStorageFiles(
        bucketName: 'chat-attachments',
        selectedFiles: files,
        maxBytes: 20 * 1024 * 1024,
      );
      final file = files.first;
      final ext = file.storagePath.split('.').last.toLowerCase();
      final kind = ext == 'pdf' ? 'pdf' : 'image';
      final name = file.originalFilename.isNotEmpty
          ? file.originalFilename
          : (kind == 'pdf' ? 'Documento.pdf' : 'Imagem');
      await ChatMessagesTable().insert({
        'thread_id': widget.threadId,
        'sender_id': currentUserUid,
        'attachment_url': urls.first,
        'attachment_name': name,
        'attachment_kind': kind,
      });
    } on StorageUploadException catch (e) {
      _showError(e.message);
    } catch (_) {
      _showError('Falha ao enviar o anexo.');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  /// Marca lido quando chega mensagem nova do outro participante.
  void _maybeMarkRead(List<ChatMessagesRow> msgs) {
    if (msgs.isEmpty) return;
    final newest = msgs.first; // lista é desc (mais nova primeiro)
    if (newest.senderId == currentUserUid) return;
    if (newest.id == _lastReadMarkedId) return;
    _lastReadMarkedId = newest.id;
    WidgetsBinding.instance.addPostFrameCallback((_) => _markRead());
  }

  @override
  Widget build(BuildContext context) {
    final title = (widget.otherName ?? '').trim().isEmpty
        ? 'Conversa'
        : widget.otherName!.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ChatHeader(
          title: title,
          subtitle: widget.otherProfile,
          showBackButton: widget.showBackButton,
        ),
        Expanded(
          child: StreamBuilder<List<ChatMessagesRow>>(
            stream: _messages,
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Center(
                  child: SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFFC2D51C),
                    ),
                  ),
                );
              }
              final msgs = snap.data!;
              _maybeMarkRead(msgs);
              if (msgs.isEmpty) {
                return const AppEmptyState(
                  icon: Icons.forum_outlined,
                  title: 'Nenhuma mensagem ainda',
                  description: 'Envie a primeira mensagem para iniciar a conversa.',
                );
              }
              return ListView.builder(
                reverse: true,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                itemCount: msgs.length,
                itemBuilder: (context, i) {
                  final m = msgs[i];
                  final mine = m.senderId == currentUserUid;
                  return _MessageBubble(message: m, mine: mine);
                },
              );
            },
          ),
        ),
        _Composer(
          controller: _input,
          focusNode: _inputFocus,
          sending: _sending,
          onSend: _sendText,
          onAttach: _sendAttachment,
        ),
      ],
    );
  }
}

// ─────────────────────── HEADER ───────────────────────
class _ChatHeader extends StatelessWidget {
  const _ChatHeader({
    required this.title,
    required this.subtitle,
    required this.showBackButton,
  });

  final String title;
  final String? subtitle;
  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
      ),
      child: Row(
        children: [
          if (showBackButton) ...[
            _CircleButton(
              icon: Icons.arrow_back_rounded,
              onTap: () => Navigator.of(context).maybePop(),
            ),
            const SizedBox(width: 12),
          ],
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0x33C2D51C),
              borderRadius: BorderRadius.circular(20),
            ),
            alignment: Alignment.center,
            child: Text(
              title.isNotEmpty ? title.characters.first.toUpperCase() : '?',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFC2D51C),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                if ((subtitle ?? '').isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: GoogleFonts.roboto(
                      fontSize: 12,
                      color: const Color(0xAAFFFFFF),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: Icon(icon, size: 18, color: Colors.white),
        ),
      ),
    );
  }
}

// ─────────────────────── BUBBLE ───────────────────────
class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.mine});
  final ChatMessagesRow message;
  final bool mine;

  String _time(DateTime dt) {
    final l = dt.toLocal();
    final h = l.hour.toString().padLeft(2, '0');
    final m = l.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final hasAttachment = (message.attachmentUrl ?? '').isNotEmpty;
    final isImage = message.attachmentKind == 'image';
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.72,
        ),
        decoration: BoxDecoration(
          color: mine ? const Color(0x33C2D51C) : const Color(0x14FFFFFF),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(mine ? 14 : 4),
            bottomRight: Radius.circular(mine ? 4 : 14),
          ),
          border: Border.all(
            color: mine
                ? const Color(0x55C2D51C)
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasAttachment && isImage) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 220),
                  child: GestureDetector(
                    onTap: () => openStorageDoc(message.attachmentUrl!),
                    child: SignedNetworkImage(
                      message.attachmentUrl!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
            ] else if (hasAttachment) ...[
              _FileChip(
                name: message.attachmentName ?? 'Documento.pdf',
                onTap: () => openStorageDoc(message.attachmentUrl!),
              ),
              const SizedBox(height: 6),
            ],
            if ((message.body ?? '').isNotEmpty)
              Text(
                message.body!,
                style: GoogleFonts.roboto(
                  fontSize: 13.5,
                  color: Colors.white,
                  height: 1.35,
                ),
              ),
            const SizedBox(height: 4),
            Text(
              _time(message.createdAt),
              style: GoogleFonts.roboto(
                fontSize: 10.5,
                color: const Color(0x88FFFFFF),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FileChip extends StatelessWidget {
  const _FileChip({required this.name, required this.onTap});
  final String name;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.picture_as_pdf_rounded,
                  size: 18, color: Color(0xFFFF7B82)),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.roboto(
                    fontSize: 12.5,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.open_in_new_rounded,
                  size: 14, color: Color(0x99FFFFFF)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────── COMPOSER ───────────────────────
class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.focusNode,
    required this.sending,
    required this.onSend,
    required this.onAttach,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool sending;
  final VoidCallback onSend;
  final VoidCallback onAttach;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _CircleButton(
            icon: Icons.attach_file_rounded,
            onTap: sending ? () {} : onAttach,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 120),
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                minLines: 1,
                maxLines: 5,
                textInputAction: TextInputAction.newline,
                style: GoogleFonts.roboto(color: Colors.white, fontSize: 13.5),
                decoration: InputDecoration(
                  hintText: 'Escreva uma mensagem…',
                  hintStyle: GoogleFonts.roboto(
                    color: const Color(0x66FFFFFF),
                    fontSize: 13.5,
                  ),
                  filled: true,
                  fillColor: const Color(0x14FFFFFF),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.10),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.10),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xAAC2D51C)),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _SendButton(sending: sending, onTap: onSend),
        ],
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({required this.sending, required this.onTap});
  final bool sending;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: sending ? null : onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFC2D51C), Color(0xFFAEC117)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: sending
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF313131),
                  ),
                )
              : const Icon(Icons.send_rounded,
                  size: 18, color: Color(0xFF313131)),
        ),
      ),
    );
  }
}
