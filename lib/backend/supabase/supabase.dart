import 'package:supabase_flutter/supabase_flutter.dart' hide Provider;

export 'database/database.dart';
export 'storage/storage.dart';

// Build-time overrides via --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
// Os valores hardcoded permanecem como fallback (anon key é pública por design;
// mover para env é hygiene, não secret management).
const String _kSupabaseUrlEnv =
    String.fromEnvironment('SUPABASE_URL', defaultValue: '');
const String _kSupabaseAnonKeyEnv =
    String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

const String _kSupabaseUrlFallback = 'https://bkzybtmxxzpxtztesdye.supabase.co';
const String _kSupabaseAnonKeyFallback =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJrenlidG14eHpweHR6dGVzZHllIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzcxMDg0NTUsImV4cCI6MjA1MjY4NDQ1NX0.e7SinKEtbHF7zWAQRpkiLMOS7IncJP6nzT-QpJcPXwk';

String get _kSupabaseUrl =>
    _kSupabaseUrlEnv.isNotEmpty ? _kSupabaseUrlEnv : _kSupabaseUrlFallback;
String get _kSupabaseAnonKey => _kSupabaseAnonKeyEnv.isNotEmpty
    ? _kSupabaseAnonKeyEnv
    : _kSupabaseAnonKeyFallback;

class SupaFlow {
  SupaFlow._();

  static SupaFlow? _instance;
  static SupaFlow get instance => _instance ??= SupaFlow._();

  final _supabase = Supabase.instance.client;
  static SupabaseClient get client => instance._supabase;

  static Future initialize() => Supabase.initialize(
        url: _kSupabaseUrl,
        headers: {
          'X-Client-Info': 'agsur-painel',
        },
        anonKey: _kSupabaseAnonKey,
        debug: false,
        authOptions:
            FlutterAuthClientOptions(authFlowType: AuthFlowType.implicit),
      );
}
