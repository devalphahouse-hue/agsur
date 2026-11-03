import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:a_g_sur_back_office/backend/contact_timeline.dart';
import 'package:a_g_sur_back_office/pages/shared/contact_timeline/contact_timeline_widget.dart';

const leadA = '11111111-1111-1111-1111-111111111111';
const leadB = '22222222-2222-2222-2222-222222222222';
const noteA = '33333333-3333-3333-3333-333333333333';
const noteInternal = '44444444-4444-4444-4444-444444444444';
const time = '2026-10-28T15:00:00Z';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final requests = <http.Request>[];
  var failHistory = false;
  var manyRecipients = false;
  var delivery = 'delivered';
  var dispatchStatus = 'Enviado';
  String? errorCode;
  http.Response response(http.Request request, Object data, int total) =>
      http.Response(jsonEncode(data), 200, request: request, headers: {
        'content-type': 'application/json',
        'content-range': '0-${total == 0 ? 0 : total - 1}/$total'
      });
  Map<String, dynamic> dispatch(int i) => {
        'id': 'dispatch-$i',
        'note_id': noteA,
        'lead_id': leadA,
        'reminder_id': 'reminder',
        'recipient_name': 'Felter Teste',
        'recipient_type': 'cliente',
        'subject': 'Retorno comercial',
        'scheduled_at': time,
        'sent_at': time,
        'status': dispatchStatus,
        'error_code': errorCode,
        'delivery_status': delivery,
        'delivery_updated_at': time,
        'attempt_count': 1,
        'provider': 'meta'
      };
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    GoogleFonts.config.allowRuntimeFetching = false;
    final font = ByteData.sublistView(
        await File('assets/fonts/Roboto-Regular.ttf').readAsBytes());
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', (message) async {
      final key = utf8.decode(message!.buffer
          .asUint8List(message.offsetInBytes, message.lengthInBytes));
      if (key == 'AssetManifest.bin') {
        return const StandardMessageCodec().encodeMessage({
          for (final family in ['Inter', 'Roboto'])
            for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold'])
              '$family-$weight.ttf': [
                {'asset': '$family-$weight.ttf'}
              ]
        });
      }
      return font;
    });
    await Supabase.initialize(
        url: 'https://timeline-test.invalid',
        anonKey: 'unit-test',
        debug: false,
        authOptions: const FlutterAuthClientOptions(
            autoRefreshToken: false,
            detectSessionInUri: false,
            localStorage: EmptyLocalStorage()),
        httpClient: MockClient((request) async {
          requests.add(request);
          if (request.url.path.endsWith('/leads')) {
            return response(request, {'wa_opt_out': false}, 1);
          }
          if (request.url.path.endsWith('/set_whatsapp_opt_out')) {
            return http.Response('', 204, request: request);
          }
          if (request.url.path.endsWith('/vw_notes_details')) {
            final person = request.url.queryParameters['lead_id'];
            final notes = person == 'eq.$leadB'
                ? [
                    {
                      'id': 'other-note',
                      'lead_id': leadB,
                      'note': 'Contato do outro cadastro',
                      'created_at': time,
                      'created_by_name': 'Ana'
                    }
                  ]
                : [
                    {
                      'id': noteA,
                      'lead_id': leadA,
                      'note': 'Contato com Felter',
                      'created_at': time,
                      'created_by_name': 'Vicente'
                    },
                    {
                      'id': noteInternal,
                      'lead_id': leadA,
                      'note': 'Observacao somente interna',
                      'created_at': time,
                      'created_by_name': 'Ana'
                    },
                  ];
            return response(request, notes, notes.length);
          }
          if (request.url.path.endsWith('/vw_reminder_dispatches')) {
            if (failHistory) {
              return http.Response(
                  '{"message":"unavailable","code":"PGRST205"}', 404,
                  headers: {'content-type': 'application/json'});
            }
            if (request.url.queryParameters['lead_id'] == 'eq.$leadB') {
              return response(request, [], 0);
            }
            if (manyRecipients) {
              final offset =
                  int.parse(request.url.queryParameters['offset'] ?? '0');
              return response(
                  request,
                  List.generate(
                      offset == 0 ? 500 : 1, (i) => dispatch(offset + i)),
                  501);
            }
            return response(request, [dispatch(0)], 1);
          }
          return response(request, [], 0);
        }));
  });
  tearDownAll(() async => Supabase.instance.dispose());
  setUp(() {
    requests.clear();
    failHistory = false;
    manyRecipients = false;
    delivery = 'delivered';
    dispatchStatus = 'Enviado';
    errorCode = null;
  });

  Future<void> open(WidgetTester tester, String id) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SingleChildScrollView(
                child: ContactTimelineWidget(leadId: id)))));
    await tester.pumpAndSettle();
  }

  test(
      'server queries scope notes AND dispatches to the same lead and visible note ids',
      () async {
    final page = await loadContactTimeline(leadA, page: 2, perPage: 10);
    final notes = requests.first.url.queryParameters;
    expect(notes['lead_id'], 'eq.$leadA');
    expect(notes['offset'], '10');
    expect(notes['limit'], '10');
    expect(notes['order'], contains('created_at.desc'));
    final related = requests.last.url.queryParameters;
    expect(related['lead_id'], 'eq.$leadA');
    expect(related['note_id'], contains(noteA));
    expect(related['note_id'], contains(noteInternal));
    expect(page.dispatches[noteA]!.length, 1);
    expect(page.dispatches[noteInternal], isNull);
  });
  test('team delivery history paginates beyond the backend row limit',
      () async {
    manyRecipients = true;
    final page = await loadContactTimeline(leadA);
    expect(page.dispatches[noteA]!.length, 501);
    expect(requests.last.url.queryParameters['offset'], '500');
  });
  test(
      'simulation never claims delivery and known delivery overrides accepted status',
      () {
    expect(
        contactDeliveryLabel({'status': 'Enviado', 'delivery_status': 'read'}),
        'Lido');
    expect(
        contactDeliveryLabel(
            {'status': 'Enviado', 'delivery_status': 'delivered'}),
        'Entregue');
    expect(
        contactDeliveryLabel({
          'status': 'Enviado',
          'provider': 'dryrun',
          'delivery_status': 'delivered'
        }),
        contains('não enviado'));
    expect(
        contactDeliveryLabel(
            {'status': 'Falha', 'delivery_status': 'accepted'}),
        'Falha no envio');
  });
  testWidgets(
      'internal notes, author and delivery are embedded in the mobile timeline',
      (tester) async {
    await open(tester, leadA);
    expect(find.text('Linha do tempo'), findsOneWidget);
    expect(find.text('Contato com Felter'), findsOneWidget);
    expect(find.text('Observacao somente interna'), findsOneWidget);
    expect(find.text('Registrado por Vicente'), findsOneWidget);
    expect(find.text('Entregue'), findsOneWidget);
    expect(find.text('Adicionar registro'), findsOneWidget);
    expect(find.text('Histórico de lembretes WhatsApp'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
      'failed history preserves internal notes and shows a retryable warning',
      (tester) async {
    failHistory = true;
    await open(tester, leadA);
    expect(find.text('Observacao somente interna'), findsOneWidget);
    expect(find.textContaining('temporariamente indisponível'), findsOneWidget);
    expect(find.text('Entregue'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
      'changing person reloads the scoped timeline and removes previous person data',
      (tester) async {
    await open(tester, leadA);
    await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
            body: SingleChildScrollView(
                child: ContactTimelineWidget(leadId: leadB)))));
    await tester.pumpAndSettle();
    expect(find.text('Contato com Felter'), findsNothing);
    expect(find.text('Contato do outro cadastro'), findsOneWidget);
    expect(requests.last.url.queryParameters['lead_id'], 'eq.$leadB');
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
      'periodic refresh updates delivery without opening a separate history',
      (tester) async {
    delivery = 'accepted';
    await open(tester, leadA);
    expect(find.text('Enviado · aceito pela Meta'), findsOneWidget);
    delivery = 'read';
    await tester.pump(const Duration(seconds: 31));
    await tester.pumpAndSettle();
    expect(find.text('Lido'), findsOneWidget);
    expect(find.text('Enviado · aceito pela Meta'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('uncertain sends cannot be blindly retried from the timeline',
      (tester) async {
    dispatchStatus = 'Falha';
    delivery = 'failed';
    errorCode = 'dispatch_outcome_unknown';
    await open(tester, leadA);
    expect(find.textContaining('Resultado incerto'), findsOneWidget);
    expect(find.text('Tentar novamente'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
      'adding a record stays in the contact timeline without a separate history link',
      (tester) async {
    await open(tester, leadA);
    await tester.tap(find.text('Adicionar registro'));
    await tester.pumpAndSettle();
    expect(find.text('Adicionar registro'), findsNWidgets(2));
    expect(find.text('Histórico de lembretes'), findsNothing);
    expect(find.text('Salvar nota'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
      'contact preference is reachable in the timeline and only changes after confirmation',
      (tester) async {
    await open(tester, leadA);
    await tester.tap(find.byTooltip('Preferências de contato'));
    await tester.pumpAndSettle();
    expect(find.text('Suspender mensagens do cliente?'), findsOneWidget);
    expect(requests.where((r) => r.url.path.endsWith('/set_whatsapp_opt_out')),
        isEmpty);
    await tester.tap(find.text('Voltar'));
    await tester.pumpAndSettle();
    expect(requests.where((r) => r.url.path.endsWith('/set_whatsapp_opt_out')),
        isEmpty);
    await tester.tap(find.byTooltip('Preferências de contato'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirmar'));
    await tester.pumpAndSettle();
    final write = requests
        .singleWhere((r) => r.url.path.endsWith('/set_whatsapp_opt_out'));
    expect(jsonDecode(write.body), {'p_lead_id': leadA, 'p_opt_out': true});
    expect(find.text('Preferência atualizada.'), findsOneWidget);
  });
}
