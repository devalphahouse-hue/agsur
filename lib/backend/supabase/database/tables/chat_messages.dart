import '../database.dart';

class ChatMessagesTable extends SupabaseTable<ChatMessagesRow> {
  @override
  String get tableName => 'chat_messages';

  @override
  ChatMessagesRow createRow(Map<String, dynamic> data) => ChatMessagesRow(data);
}

class ChatMessagesRow extends SupabaseDataRow {
  ChatMessagesRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => ChatMessagesTable();

  String get id => getField<String>('id')!;
  set id(String value) => setField<String>('id', value);

  String get threadId => getField<String>('thread_id')!;
  set threadId(String value) => setField<String>('thread_id', value);

  String? get senderId => getField<String>('sender_id');
  set senderId(String? value) => setField<String>('sender_id', value);

  String? get body => getField<String>('body');
  set body(String? value) => setField<String>('body', value);

  String? get attachmentUrl => getField<String>('attachment_url');
  set attachmentUrl(String? value) => setField<String>('attachment_url', value);

  String? get attachmentName => getField<String>('attachment_name');
  set attachmentName(String? value) =>
      setField<String>('attachment_name', value);

  String? get attachmentKind => getField<String>('attachment_kind');
  set attachmentKind(String? value) =>
      setField<String>('attachment_kind', value);

  DateTime get createdAt => getField<DateTime>('created_at')!;
  set createdAt(DateTime value) => setField<DateTime>('created_at', value);
}
