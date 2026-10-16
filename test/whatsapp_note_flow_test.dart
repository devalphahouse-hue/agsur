import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:a_g_sur_back_office/pages/shared/modal_register_note/modal_register_note_widget.dart';
import 'package:a_g_sur_back_office/core_ui/app_form_field.dart';
import 'package:a_g_sur_back_office/backend/notes.dart';
import 'package:a_g_sur_back_office/components/reminder_notifications_widget.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final writes = <Map<String, dynamic>>[];
  var notificationRead = false;
  String? noteRpcErrorCode;
  final legacyWrites = <Map<String, dynamic>>[];
  const lead = '22222222-2222-2222-2222-222222222222';
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    GoogleFonts.config.allowRuntimeFetching = false;
    // Typography is not under test: supply a local font for each Inter weight.
    final font = ByteData.sublistView(
        await File('assets/fonts/Roboto-Regular.ttf').readAsBytes());
    final names = ['Regular', 'Medium', 'SemiBold', 'Bold'];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', (message) async {
      final key = utf8.decode(message!.buffer
          .asUint8List(message.offsetInBytes, message.lengthInBytes));
      if (key == 'AssetManifest.bin') {
        return const StandardMessageCodec().encodeMessage({
          for (final family in ['Inter', 'Roboto'])
            for (final name in names)
              '$family-$name.ttf': [
                {'asset': '$family-$name.ttf'}
              ]
        });
      }
      return font;
    });
    await Supabase.initialize(
        url: 'https://whatsapp-test.invalid',
        anonKey: 'unit-test',
        debug: false,
        authOptions: const FlutterAuthClientOptions(
            autoRefreshToken: false,
            detectSessionInUri: false,
            authFlowType: AuthFlowType.implicit,
            localStorage: EmptyLocalStorage()),
        httpClient: MockClient((request) async {
          if (request.url.path.endsWith('/rpc/whatsapp_reminder_recipients')) {
            return http.Response(
                jsonEncode([
                  {
                    'id': lead,
                    'name': 'Cliente teste',
                    'phone': '(11) 98765-4321'
                  }
                ]),
                200,
                request: request,
                headers: {'content-type': 'application/json'});
          }
          if (request.url.path.endsWith('/rpc/my_reminder_notifications')) {
            return http.Response(
                jsonEncode([
                  {
                    'id': lead,
                    'lead_name': 'Cliente teste',
                    'subject': 'Reunião de acompanhamento',
                    'message': 'Confirmar atendimento pelo sistema',
                    'scheduled_at': DateTime.now().toUtc().toIso8601String(),
                    'status': 'Falha',
                    'read_at': notificationRead
                        ? DateTime.now().toUtc().toIso8601String()
                        : null,
                    'unread_count': notificationRead ? 0 : 1,
                  }
                ]),
                200,
                request: request,
                headers: {'content-type': 'application/json'});
          }
          if (request.url.path
              .endsWith('/rpc/mark_reminder_notification_read')) {
            notificationRead = true;
            return http.Response('', 204, request: request);
          }
          if (request.url.path.endsWith('/rest/v1/notes')) {
            legacyWrites.add(
                Map<String, dynamic>.from(jsonDecode(request.body) as Map));
            return http.Response(jsonEncode({'id': lead}), 201,
                request: request,
                headers: {'content-type': 'application/json'});
          }
          if (request.url.path.endsWith('/rpc/create_lead_note')) {
            if (noteRpcErrorCode != null) {
              return http.Response(
                  jsonEncode(
                      {'code': noteRpcErrorCode, 'message': 'RPC unavailable'}),
                  404,
                  request: request,
                  headers: {'content-type': 'application/json'});
            }
            writes.add(
                Map<String, dynamic>.from(jsonDecode(request.body) as Map));
            return http.Response(
                jsonEncode('66666666-6666-6666-6666-666666666666'), 200,
                request: request,
                headers: {'content-type': 'application/json'});
          }
          return http.Response('[]', 200, request: request, headers: {
            'content-type': 'application/json',
            'content-range': '0-0/0'
          });
        }));
    final expires =
        DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/
            1000;
    String encode(Map<String, dynamic> value) =>
        base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
    final accessToken = '${encode({'alg': 'HS256', 'typ': 'JWT'})}.${encode({
          'exp': expires,
          'sub': '11111111-1111-1111-1111-111111111111',
          'aud': 'authenticated'
        })}.test';
    await Supabase.instance.client.auth.recoverSession(jsonEncode({
      'access_token': accessToken,
      'refresh_token': 'unit-test',
      'token_type': 'bearer',
      'expires_at': expires,
      'expires_in': 3600,
      'user': {
        'id': '11111111-1111-1111-1111-111111111111',
        'aud': 'authenticated',
        'app_metadata': {},
        'user_metadata': {},
        'created_at': DateTime.now().toUtc().toIso8601String()
      },
    }));
  });
  tearDownAll(() async => Supabase.instance.dispose());
  setUp(() {
    writes.clear();
    legacyWrites.clear();
    noteRpcErrorCode = null;
    notificationRead = false;
  });

  Future<void> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1400, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
        theme: ThemeData.dark(),
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
            child: child!),
        home: Scaffold(
            body: Builder(
                builder: (context) => TextButton(
                    onPressed: () => showDialog<void>(
                        context: context,
                        builder: (_) => Dialog(
                            child: ModalRegisterNoteWidget(
                                leadId: lead, onSaved: () async {}))),
                    child: const Text('Abrir nota'))))));
    await tester.tap(find.text('Abrir nota'));
    await tester.pumpAndSettle();
  }

  testWidgets('nota simples continua salvando sem lembrete', (tester) async {
    await open(tester);
    await tester.enterText(
        find.descendant(
            of: find.byType(AppFormField).first,
            matching: find.byType(TextField)),
        'Observação interna');
    await tester.tap(find.text('Salvar nota'));
    await tester.runAsync(
        () async => Future<void>.delayed(const Duration(milliseconds: 300)));
    await tester.pumpAndSettle();
    expect(writes.single['p_note'], 'Observação interna');
    expect(writes.single['p_reminder'], null);
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(ModalRegisterNoteWidget), findsNothing,
        reason: find
            .byType(Text)
            .evaluate()
            .map((e) => (e.widget as Text).data)
            .join(' | '));
  });

  testWidgets(
      'agendamento exige autorização e data, apresenta prévia e grava UTC',
      (tester) async {
    await open(tester);
    await tester.enterText(
        find.descendant(
            of: find.byType(AppFormField).first,
            matching: find.byType(TextField)),
        'Reunião\n de acompanhamento');
    await tester.tap(find.byType(Switch));
    await tester.runAsync(
        () async => Future<void>.delayed(const Duration(milliseconds: 300)));
    await tester.pumpAndSettle();
    expect(find.textContaining('agendado: Reunião de acompanhamento.'),
        findsOneWidget);
    await tester.tap(find.text('Salvar nota'));
    await tester.runAsync(
        () async => Future<void>.delayed(const Duration(milliseconds: 300)));
    await tester.pumpAndSettle();
    expect(writes, isEmpty);
    await tester.tap(find.text('Escolher data e horário'));
    await tester.pumpAndSettle();
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    if (tomorrow.month != DateTime.now().month) {
      await tester.tap(find.byTooltip('Next month'));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('${tomorrow.day}').last);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.keyboard_outlined));
    await tester.pumpAndSettle();
    final timeFields = find.descendant(
        of: find.byType(TimePickerDialog), matching: find.byType(TextField));
    await tester.enterText(timeFields.at(0), '14');
    await tester.enterText(timeFields.at(1), '05');
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Checkbox).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salvar nota'));
    await tester.runAsync(
        () async => Future<void>.delayed(const Duration(milliseconds: 300)));
    await tester.pumpAndSettle();
    expect(writes, hasLength(1),
        reason: find
            .byType(Text)
            .evaluate()
            .map((e) => (e.widget as Text).data)
            .join(' | '));
    final reminder = writes.single['p_reminder'] as Map;
    expect(reminder['recipient_type'], 'cliente');
    expect(reminder['recipient_ids'], [lead]);
    expect(reminder['consent'], true);
    final expected =
        DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 14, 5).toUtc();
    expect(DateTime.parse(reminder['scheduled_at'] as String), expected);
  });

  testWidgets(
      'alerta no painel aparece mesmo com falha WhatsApp e permite marcar como lido',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
            body: Center(
                child: SizedBox(
                    width: 300,
                    height: 400,
                    child: ReminderNotificationsWidget())))));
    await tester.runAsync(
        () async => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pumpAndSettle();
    expect(find.text('Lembretes (1 não lidos)'), findsOneWidget);
    expect(find.text('WhatsApp: Falha'), findsOneWidget);
    expect(find.text('Confirmar atendimento pelo sistema'), findsOneWidget);
    await tester.tap(find.text('Marcar como lido'));
    await tester.runAsync(
        () async => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pumpAndSettle();
    expect(notificationRead, true);
    expect(find.text('Lembretes (0 não lidos)'), findsOneWidget);
    expect(find.text('Marcar como lido'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  test(
      'nota simples preserva o INSERT anterior somente quando a RPC não existe',
      () async {
    noteRpcErrorCode = 'PGRST202';
    await createLeadNote(leadId: lead, note: '  Nota comum  ', requestId: lead);
    expect(legacyWrites, hasLength(1));
    expect(legacyWrites.single, {
      'lead_id': lead,
      'note': 'Nota comum',
      'created_by': '11111111-1111-1111-1111-111111111111',
    });
  });

  test('lembretes e falhas diferentes não fazem INSERT alternativo', () async {
    noteRpcErrorCode = 'PGRST202';
    await expectLater(
        createLeadNote(
            leadId: lead,
            note: 'Lembrete',
            requestId: lead,
            reminder: {'consent': true}),
        throwsA(isA<PostgrestException>()));
    for (final code in ['42501', '23505', 'PGRST500']) {
      noteRpcErrorCode = code;
      await expectLater(
          createLeadNote(leadId: lead, note: 'Nota', requestId: lead),
          throwsA(isA<PostgrestException>()));
    }
    expect(legacyWrites, isEmpty);
  });
}
