import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/auth/supabase_auth/auth_util.dart';
import '/backend/supabase/supabase.dart';
import '/core_ui/core_ui.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/pages/chat/chat_detail/chat_detail_widget.dart';

/// Chat interno do painel (DM 1:1 entre usuários do painel).
/// - **Desktop (≥ [kSidebarBreakpoint]):** layout em duas colunas estilo
///   WhatsApp Web — lista de conversas à esquerda, conversa selecionada à
///   direita (inline, sem navegar).
/// - **Mobile:** lista única; tocar numa conversa empurra a rota de detalhe.
class ChatWidget extends StatefulWidget {
  const ChatWidget({super.key});

  static String routeName = 'Chat';
  static String routePath = '/chat';

  @override
  State<ChatWidget> createState() => _ChatWidgetState();
}

class _ChatWidgetState extends State<ChatWidget> {
  Future<List<VwChatMyThreadsRow>>? _future;

  // Conversa selecionada (apenas no layout de duas colunas).
  String? _selThreadId;
  String? _selName;
  String? _selProfile;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<VwChatMyThreadsRow>> _load() => VwChatMyThreadsTable().queryRows(
        queryFn: (q) => q.order('last_message_at', ascending: false),
      );

  void _refresh() => safeSetState(() => _future = _load());

  String _displayName(VwChatMyThreadsRow t) {
    final parts = [t.otherName ?? '', t.otherLastname ?? '']
        .where((p) => p.trim().isNotEmpty)
        .join(' ')
        .trim();
    return parts.isEmpty ? 'Usuário' : parts;
  }

  /// Abre uma conversa: inline (duas colunas) ou via push (mobile).
  Future<void> _openThread(
    String threadId,
    String name,
    String? profile, {
    required bool twoPane,
  }) async {
    if (twoPane) {
      setState(() {
        _selThreadId = threadId;
        _selName = name;
        _selProfile = profile;
      });
      _refresh(); // atualiza prévia / não-lidas da lista
      return;
    }
    await context.pushNamed(
      ChatDetailWidget.routeName,
      queryParameters: {
        'threadId': serializeParam(threadId, ParamType.String),
        'otherName': serializeParam(name, ParamType.String),
        'otherProfile': serializeParam(profile, ParamType.String),
      }.withoutNulls,
    );
    _refresh();
  }

  Future<void> _newConversation({required bool twoPane}) async {
    final picked = await showDialog<UsersRow>(
      context: context,
      builder: (dialogContext) => Dialog(
        elevation: 0,
        insetPadding: EdgeInsets.zero,
        backgroundColor: Colors.transparent,
        alignment: Alignment.center,
        child: const _NewConversationModal(),
      ),
    );
    if (picked == null) return;
    try {
      final res = await SupaFlow.client.rpc(
        'chat_get_or_create_dm',
        params: {'p_other_user': picked.id},
      );
      final threadId = res as String;
      final name = [picked.name, picked.lastname ?? '']
          .where((p) => p.trim().isNotEmpty)
          .join(' ')
          .trim();
      if (!mounted) return;
      await _openThread(
        threadId,
        name.isEmpty ? 'Usuário' : name,
        picked.profileType,
        twoPane: twoPane,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível abrir a conversa.'),
          backgroundColor: Color(0xFF5A2A2D),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final twoPane = MediaQuery.sizeOf(context).width >= kSidebarBreakpoint;
    return twoPane ? _buildTwoPane() : _buildSinglePane();
  }

  // ─────────── Mobile / estreito: lista única + push ───────────
  Widget _buildSinglePane() {
    return AppListScaffold(
      eyebrow: 'Comunicação',
      title: 'Chat',
      description: 'Converse com os outros usuários do painel.',
      actions: [
        AppPrimaryButton(
          label: 'Nova conversa',
          icon: Icons.add_comment_rounded,
          onPressed: () => _newConversation(twoPane: false),
        ),
      ],
      body: _threadListBody(twoPane: false),
    );
  }

  // ─────────── Desktop: duas colunas (lista | conversa) ───────────
  Widget _buildTwoPane() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: 360,
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ListPaneHeader(
                  onNewConversation: () => _newConversation(twoPane: true),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                    child: _threadListBody(twoPane: true),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: _selThreadId == null
              ? const AppEmptyState(
                  icon: Icons.forum_outlined,
                  title: 'Selecione uma conversa',
                  description:
                      'Escolha uma conversa à esquerda ou inicie uma nova.',
                )
              : ChatConversationView(
                  key: ValueKey(_selThreadId),
                  threadId: _selThreadId,
                  otherName: _selName,
                  otherProfile: _selProfile,
                ),
        ),
      ],
    );
  }

  Widget _threadListBody({required bool twoPane}) {
    return FutureBuilder<List<VwChatMyThreadsRow>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return Column(
            children: [
              for (var i = 0; i < 4; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: AppSkeleton.box(height: 72),
                ),
            ],
          );
        }
        final threads = snap.data ?? [];
        if (threads.isEmpty) {
          return const Padding(
            padding: EdgeInsets.only(top: 40),
            child: AppEmptyState(
              icon: Icons.forum_outlined,
              title: 'Nenhuma conversa',
              description:
                  'Toque em "Nova conversa" para falar com outro usuário do painel.',
            ),
          );
        }
        return Column(
          children: [
            for (final t in threads)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ThreadCard(
                  thread: t,
                  name: _displayName(t),
                  selected: twoPane && t.threadId == _selThreadId,
                  onTap: () => _openThread(
                    t.threadId,
                    _displayName(t),
                    t.otherProfileType,
                    twoPane: twoPane,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ListPaneHeader extends StatelessWidget {
  const _ListPaneHeader({required this.onNewConversation});
  final VoidCallback onNewConversation;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 14, 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'COMUNICAÇÃO',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.6,
                    color: const Color(0x66FFFFFF),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Chat',
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.4,
                  ),
                ),
              ],
            ),
          ),
          _CircleIconButton(
            icon: Icons.add_comment_rounded,
            onTap: onNewConversation,
            tooltip: 'Nova conversa',
          ),
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.icon,
    required this.onTap,
    this.tooltip,
  });
  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final btn = MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFC2D51C), Color(0xFFAEC117)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 18, color: const Color(0xFF313131)),
        ),
      ),
    );
    return tooltip != null ? Tooltip(message: tooltip!, child: btn) : btn;
  }
}

class _ThreadCard extends StatelessWidget {
  const _ThreadCard({
    required this.thread,
    required this.name,
    required this.onTap,
    this.selected = false,
  });

  final VwChatMyThreadsRow thread;
  final String name;
  final VoidCallback onTap;
  final bool selected;

  String _preview() {
    if ((thread.lastBody ?? '').isNotEmpty) return thread.lastBody!;
    if (thread.lastAttachmentKind == 'image') return '📷 Imagem';
    if (thread.lastAttachmentKind == 'pdf') return '📄 Documento';
    return 'Conversa iniciada';
  }

  @override
  Widget build(BuildContext context) {
    final unread = thread.unreadCount ?? 0;
    return AppCard(
      onTap: onTap,
      background: selected ? const Color(0x22C2D51C) : null,
      border: selected
          ? Border.all(color: const Color(0x66C2D51C))
          : null,
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0x33C2D51C),
              borderRadius: BorderRadius.circular(23),
            ),
            alignment: Alignment.center,
            child: Text(
              name.isNotEmpty ? name.characters.first.toUpperCase() : '?',
              style: GoogleFonts.inter(
                fontSize: 18,
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
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    if ((thread.otherProfileType ?? '').isNotEmpty)
                      AppStatusBadge(
                        label: thread.otherProfileType!,
                        tone: AppStatusTone.neutral,
                        dense: true,
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  _preview(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.roboto(
                    fontSize: 12.5,
                    color: unread > 0
                        ? Colors.white
                        : const Color(0x99FFFFFF),
                    fontWeight:
                        unread > 0 ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          if (unread > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFC2D51C),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                unread > 99 ? '99+' : '$unread',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF313131),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Modal de seleção de usuário do painel (Admin Master / Admin / Vendedor)
/// para iniciar uma nova conversa. Retorna o [UsersRow] escolhido.
class _NewConversationModal extends StatefulWidget {
  const _NewConversationModal();

  @override
  State<_NewConversationModal> createState() => _NewConversationModalState();
}

class _NewConversationModalState extends State<_NewConversationModal> {
  late Future<List<UsersRow>> _future;
  String _query = '';

  static const _panelProfiles = ['Admin Master', 'Admin', 'Vendedor'];

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<UsersRow>> _load() => UsersTable().queryRows(
        queryFn: (q) => q
            .inFilter('profile_type', _panelProfiles)
            .neqOrNull('id', currentUserUid)
            .eqOrNull('is_deleted', false)
            .order('name'),
      );

  String _name(UsersRow u) {
    final n = [u.name, u.lastname ?? '']
        .where((p) => p.trim().isNotEmpty)
        .join(' ')
        .trim();
    return n.isEmpty ? (u.email) : n;
  }

  @override
  Widget build(BuildContext context) {
    return AppModal(
      icon: Icons.add_comment_rounded,
      title: 'Nova conversa',
      description: 'Escolha um usuário do painel para conversar.',
      maxWidth: 520,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppSearchInput(
            value: _query,
            placeholder: 'Buscar usuário…',
            width: double.infinity,
            onChanged: (v) => setState(() => _query = v.toLowerCase()),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 360,
            child: FutureBuilder<List<UsersRow>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFFC2D51C),
                      ),
                    ),
                  );
                }
                final all = snap.data ?? [];
                final users = _query.isEmpty
                    ? all
                    : all
                        .where((u) =>
                            _name(u).toLowerCase().contains(_query) ||
                            u.email.toLowerCase().contains(_query))
                        .toList();
                if (users.isEmpty) {
                  return const AppEmptyState(
                    icon: Icons.person_off_outlined,
                    title: 'Nenhum usuário',
                    description: 'Nenhum usuário do painel encontrado.',
                    compact: true,
                  );
                }
                return ListView.separated(
                  itemCount: users.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final u = users[i];
                    return AppPersonCard(
                      name: _name(u),
                      subtitle: u.profileType,
                      avatarUrl: u.profilePhotoUrl,
                      isActive: true,
                      onTap: () => Navigator.of(context).pop(u),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
