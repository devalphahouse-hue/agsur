import '../database.dart';

class ChatParticipantsTable extends SupabaseTable<ChatParticipantsRow> {
  @override
  String get tableName => 'chat_participants';

  @override
  ChatParticipantsRow createRow(Map<String, dynamic> data) =>
      ChatParticipantsRow(data);
}

class ChatParticipantsRow extends SupabaseDataRow {
  ChatParticipantsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => ChatParticipantsTable();

  String get threadId => getField<String>('thread_id')!;
  set threadId(String value) => setField<String>('thread_id', value);

  String get userId => getField<String>('user_id')!;
  set userId(String value) => setField<String>('user_id', value);

  DateTime get lastReadAt => getField<DateTime>('last_read_at')!;
  set lastReadAt(DateTime value) => setField<DateTime>('last_read_at', value);

  DateTime get createdAt => getField<DateTime>('created_at')!;
  set createdAt(DateTime value) => setField<DateTime>('created_at', value);
}
