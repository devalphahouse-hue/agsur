import '../database.dart';

class VwChatMyThreadsTable extends SupabaseTable<VwChatMyThreadsRow> {
  @override
  String get tableName => 'vw_chat_my_threads';

  @override
  VwChatMyThreadsRow createRow(Map<String, dynamic> data) =>
      VwChatMyThreadsRow(data);
}

class VwChatMyThreadsRow extends SupabaseDataRow {
  VwChatMyThreadsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => VwChatMyThreadsTable();

  String get threadId => getField<String>('thread_id')!;
  set threadId(String value) => setField<String>('thread_id', value);

  DateTime? get lastMessageAt => getField<DateTime>('last_message_at');
  set lastMessageAt(DateTime? value) =>
      setField<DateTime>('last_message_at', value);

  String get otherUserId => getField<String>('other_user_id')!;
  set otherUserId(String value) => setField<String>('other_user_id', value);

  String? get otherName => getField<String>('other_name');
  set otherName(String? value) => setField<String>('other_name', value);

  String? get otherLastname => getField<String>('other_lastname');
  set otherLastname(String? value) =>
      setField<String>('other_lastname', value);

  String? get otherProfileType => getField<String>('other_profile_type');
  set otherProfileType(String? value) =>
      setField<String>('other_profile_type', value);

  DateTime? get myLastReadAt => getField<DateTime>('my_last_read_at');
  set myLastReadAt(DateTime? value) =>
      setField<DateTime>('my_last_read_at', value);

  String? get lastBody => getField<String>('last_body');
  set lastBody(String? value) => setField<String>('last_body', value);

  String? get lastAttachmentKind => getField<String>('last_attachment_kind');
  set lastAttachmentKind(String? value) =>
      setField<String>('last_attachment_kind', value);

  int? get unreadCount => getField<int>('unread_count');
  set unreadCount(int? value) => setField<int>('unread_count', value);
}
