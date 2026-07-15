import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';

import '/auth/supabase_auth/auth_util.dart';
import '/backend/api_requests/api_calls.dart';
import '/backend/schema/structs/index.dart';
import '/backend/supabase/supabase.dart';
import '/core_ui/core_ui.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/pages/modal_tracking/modal_tracking_widget.dart';
import '/pages/shared/alert_dialog/alert_dialog_widget.dart';
import '/security/access_control.dart';
import 'view_tracking_model.dart';

export 'view_tracking_model.dart';

class ViewTrackingWidget extends StatefulWidget {
  const ViewTrackingWidget({
    super.key,
    required this.userAircraftId,
  });

  final String? userAircraftId;

  static String routeName = 'ViewTracking';
  static String routePath = '/viewTracking';

  @override
  State<ViewTrackingWidget> createState() => _ViewTrackingWidgetState();
}

class _ViewTrackingWidgetState extends State<ViewTrackingWidget> {
  late ViewTrackingModel _model;

  @override
  void initState() {
    super.initState();
    _model = ViewTrackingModel();

    SchedulerBinding.instance.addPostFrameCallback((_) async {
      _model.user = await UsersTable().queryRows(
        queryFn: (q) => q.eqOrNull('id', currentUserUid),
      );
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() {
      _model.apiRequestCompleter = null;
      _model.extrasFuture = null;
    });
    await _model.waitForApiRequestCompleted();
  }

  /// Carrega os dados preenchidos de todas as etapas desta aeronave numa
  /// leitura só (memoizado em `_model.extrasFuture`): `tracking_details`
  /// indexado por `tracking_id` + a linha `user_aircraft`.
  Future<TrackingExtras> _loadExtras() async {
    final aircraftId = widget.userAircraftId;
    if (aircraftId == null || aircraftId.isEmpty) {
      return TrackingExtras(<String, TrackingDetailsRow>{}, null);
    }
    final trackingRows = await TrackingTable().queryRows(
      queryFn: (q) => q.eqOrNull('user_aircraft', aircraftId),
    );
    final ids = trackingRows.map((t) => t.id).toList();
    final details = ids.isEmpty
        ? <TrackingDetailsRow>[]
        : await TrackingDetailsTable().queryRows(
            queryFn: (q) => q.inFilter('tracking_id', ids),
          );
    final byId = <String, TrackingDetailsRow>{
      for (final d in details) d.trackingId: d,
    };
    final aircraftRows = await UserAircraftTable().queryRows(
      queryFn: (q) => q.eqOrNull('id', aircraftId),
    );
    return TrackingExtras(byId, aircraftRows.firstOrNull);
  }

  // Só master e documentação editam/checam etapas. Vendedor vê em modo
  // somente-leitura (view-only); recepção nem acessa a tela.
  bool get _isAdmin => AccessControl.canEditTracking(
      AccessControl.roleOf(_model.user?.firstOrNull));

  @override
  Widget build(BuildContext context) {
    return AppListScaffold(
      eyebrow: 'Operação',
      title: 'Rastreamento da aeronave',
      description:
          'Acompanhe as 21 etapas do processo de importação. Configure ou confirme cada etapa para liberar a próxima.',
      body: FutureBuilder<ApiCallResponse>(
        future: (_model.apiRequestCompleter ??= Completer<ApiCallResponse>()
              ..complete(GetTrackingCall.call(
                pAircraftId: widget.userAircraftId,
              )))
            .future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return _LoadingGrid();
          }
          final data = snapshot.data!;
          final tracking =
              GetTrackingStruct.maybeFromMap(data.jsonBody)?.tracking ?? [];
          if (tracking.isEmpty) {
            return AppCard(
              child: AppEmptyState(
                icon: Icons.flight_takeoff_rounded,
                title: 'Nada em rastreamento',
                description:
                    'As etapas vão aparecer aqui assim que a aeronave for cadastrada.',
              ),
            );
          }
          final clientName = GetTrackingStruct.maybeFromMap(data.jsonBody)
                  ?.trackCompany
                  ?.companyName ??
              'Cliente não cadastrado';
          final refId = GetTrackingStruct.maybeFromMap(data.jsonBody)
                  ?.trackProposal
                  ?.idRef ??
              '#000000';

          final completed =
              tracking.where((t) => t.isCheck == true).length;
          final progress =
              tracking.isEmpty ? 0.0 : completed / tracking.length;

          _model.extrasFuture ??= _loadExtras();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ProgressHeader(
                clientName: clientName,
                refId: refId,
                completed: completed,
                total: tracking.length,
                progress: progress,
              ).appFade(),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, c) {
                  final crossAxis = c.maxWidth > 1200
                      ? 3
                      : c.maxWidth > 760
                          ? 2
                          : 1;
                  const spacing = 16.0;
                  return FutureBuilder<TrackingExtras>(
                    future: _model.extrasFuture,
                    builder: (context, extrasSnap) {
                      final extras = extrasSnap.data;
                      // Grade manual em linhas de ALTURA IGUAL: dentro de cada
                      // linha os cards esticam para a altura do mais alto
                      // (IntrinsicHeight + stretch), pra não sobrar espaço vazio
                      // embaixo do card mais curto.
                      Widget cell(int index) {
                        if (index >= tracking.length) {
                          return const SizedBox.shrink();
                        }
                        return _TrackingCard(
                          item: tracking[index],
                          refId: refId,
                          clientName: clientName,
                          isAdmin: _isAdmin,
                          userAircraftId: widget.userAircraftId,
                          onChanged: _refresh,
                          details:
                              extras?.detailsByTrackingId[tracking[index].id],
                          aircraft: extras?.aircraft,
                        ).appStagger(index);
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (var row = 0;
                              row < tracking.length;
                              row += crossAxis) ...[
                            if (row > 0) const SizedBox(height: spacing),
                            IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  for (var col = 0; col < crossAxis; col++) ...[
                                    if (col > 0)
                                      const SizedBox(width: spacing),
                                    Expanded(child: cell(row + col)),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LoadingGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSkeleton.box(height: 96),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, c) {
            final crossAxis = c.maxWidth > 1200
                ? 3
                : c.maxWidth > 760
                    ? 2
                    : 1;
            const spacing = 16.0;
            final width =
                (c.maxWidth - (crossAxis - 1) * spacing) / crossAxis;
            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: List.generate(
                6,
                (_) => SizedBox(
                  width: width,
                  child: AppSkeleton.box(height: 220),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({
    required this.clientName,
    required this.refId,
    required this.completed,
    required this.total,
    required this.progress,
  });

  final String clientName;
  final String refId;
  final int completed;
  final int total;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final pct = (progress * 100).round();
    return AppCard(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0x33C2D51C),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.flight_takeoff_rounded,
              color: Color(0xFFC2D51C),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  clientName,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Proposta $refId · $completed de $total etapas concluídas',
                  style: GoogleFonts.roboto(
                    fontSize: 12,
                    color: const Color(0xAAFFFFFF),
                  ),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LayoutBuilder(
                    builder: (context, constraints) => Stack(
                      children: [
                        Container(
                          height: 6,
                          color: Colors.white.withValues(alpha: 0.06),
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeOutCubic,
                          height: 6,
                          width: (progress.clamp(0, 1) * constraints.maxWidth)
                              .toDouble(),
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFFC2D51C), Color(0xFFAEC117)],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0x33C2D51C),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0x55C2D51C)),
            ),
            child: Text(
              '$pct%',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: const Color(0xFFC2D51C),
                letterSpacing: 0.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

IconData _iconForOrder(int order) {
  switch (order) {
    case 0:
    case 8:
    case 11:
    case 13:
    case 16:
    case 17:
      return Icons.list_alt_rounded;
    case 1:
      return Icons.airplanemode_active_rounded;
    case 2:
      return Icons.border_color_rounded;
    case 3:
      return Icons.laptop_chromebook_rounded;
    case 4:
    case 5:
    case 12:
      return Icons.monetization_on_outlined;
    case 6:
    case 10:
      return Icons.library_books_outlined;
    case 7:
      return Icons.history_rounded;
    case 9:
      return Icons.numbers_rounded;
    case 14:
      return Icons.link_rounded;
    case 15:
      return Icons.public_rounded;
    default:
      return Icons.check_rounded;
  }
}

const _kConfigurableOrders = {
  '1', '2', '3', '4', '5', '6', '7', '8', '9', '10',
  '11', '12', '13', '14', '15', '16', '17', '18', '19', '20',
};

class _TrackingCard extends StatelessWidget {
  const _TrackingCard({
    required this.item,
    required this.refId,
    required this.clientName,
    required this.isAdmin,
    required this.userAircraftId,
    required this.onChanged,
    this.details,
    this.aircraft,
  });

  final TrackingStruct item;
  final String refId;
  final String clientName;
  final bool isAdmin;
  final String? userAircraftId;
  final Future<void> Function() onChanged;
  final TrackingDetailsRow? details;
  final UserAircraftRow? aircraft;

  bool get _checked => item.isCheck == true;
  int get _orderInt => int.tryParse(item.order ?? '') ?? -1;
  bool get _isConfigurable =>
      _kConfigurableOrders.contains(item.order?.toString() ?? '');

  // ---- Dados preenchidos exibidos no card ---------------------------------

  /// Campos "de valor" preenchidos naquela etapa (só os não-vazios). As etapas
  /// de checklist (16/18) não entram aqui — elas usam [_checklist].
  List<_FieldKV> get _valueFields {
    final d = details;
    final a = aircraft;
    String? t(String? v) =>
        (v != null && v.trim().isNotEmpty) ? v.trim() : null;
    String yn(bool? v) => v == true ? 'Sim' : 'Não';
    final out = <_FieldKV>[];
    void add(String label, String? value) {
      if (value != null && value.isNotEmpty) out.add(_FieldKV(label, value));
    }

    switch (_orderInt) {
      case 1:
        add('Cor da faixa', t(a?.stripeColor));
        add('Filtro de Ar', t(a?.airFilter));
        add('Painel', t(a?.panel));
        add('Descrição Técnica', t(d?.customizationDescription));
        break;
      case 2:
        add('Proforma', t(d?.invoiceNumber));
        break;
      case 3:
        add('Equipamento', t(d?.equipmentType));
        break;
      case 4:
        if (d != null) add('Reserva paga', yn(d.reservationPaid));
        break;
      case 5:
        if (d != null) add('Pagamento 5%', yn(d.fivePercentPaid));
        break;
      case 6:
        if (d != null) {
          add('Benefício fiscal', yn(d.fiscalBenefitActive));
          add('Radar', yn(d.hasRadar));
        }
        break;
      case 7:
        add('Despachante', t(d?.brokerName));
        break;
      case 8:
        add('Marca', t(d?.brand));
        add('Prefixo', t(d?.prefix));
        break;
      case 9:
        add('Forma de pagamento', t(d?.paymentMethod));
        break;
      case 10:
        if (d != null) add('Financiamento aprovado', yn(d.financingApproved));
        break;
      case 11:
        if (d != null) add('Pré-contrato assinado', yn(d.preContractSigned));
        break;
      case 12:
        add('Seguradora', t(d?.insuranceCompany));
        break;
      case 13:
        if (d != null) add('Apólice enviada', yn(d.insurancePolicySent));
        break;
      case 14:
        add('Saldo de entrada', t(d?.entryPaymentInfo));
        break;
      case 17:
        if (d != null) add('Contrato final assinado', yn(d.finalContractSigned));
        break;
      case 19:
        add('Desembaraço', t(d?.customsStatus));
        if (d != null) add('CND', yn(d.customsCnd));
        break;
    }
    return out;
  }

  /// Progresso do checklist de documentos das etapas 16 (Docs Oficina, 18
  /// itens) e 18 (Despachante, 11 itens). `null` para etapas que não são
  /// checklist. `total==0` nunca ocorre aqui.
  ({int checked, int total})? get _checklist {
    final d = details;
    List<bool?> items;
    switch (_orderInt) {
      case 16:
        items = [
          d?.oficInvoice, d?.oficExportCertificate, d?.oficBillOfSale,
          d?.oficTecat, d?.oficAadsac, d?.oficGendec,
          d?.oficSpecialAirworthness, d?.oficSeguroReta, d?.oficBoletoReta,
          d?.oficComprovanteReta, d?.oficDocsDespachante, d?.oficCopiaCadernetas,
          d?.oficPesoBalanceamento, d?.oficDesregistro, d?.oficFlightTest,
          d?.oficForm337, d?.oficListaComponentes, d?.oficListaAds,
        ];
        break;
      case 18:
        items = [
          d?.despCnd, d?.despInvoice, d?.despExportCertificate,
          d?.despBillOfSale, d?.despTecat, d?.despAvanac, d?.despGendec,
          d?.despSpecialAirworthness, d?.despSeguroReta, d?.despBoletoReta,
          d?.despComprovanteReta,
        ];
        break;
      default:
        return null;
    }
    final checked = items.where((e) => e == true).length;
    return (checked: checked, total: items.length);
  }

  static const ({Color background, Color border}) _redTone = (
    background: Color(0xFF3B2626),
    border: Color(0x80FF5963),
  );
  static const ({Color background, Color border}) _greenTone = (
    background: Color(0xFF243B36),
    border: Color(0x804FBFA9),
  );

  /// Preenchimento dos campos da etapa: `touched` = mexeu em algo,
  /// `allDone` = tudo preenchido. `null` para etapas sem campos (só
  /// confirmação, ex.: 15/20) e para as de checklist 16/18 ([_checklist]).
  ///
  /// Semântica por tipo de campo:
  /// - texto: preenchido quando não-vazio;
  /// - booleano-tarefa (pagou? assinou? enviou?): null = nunca respondido,
  ///   false = respondido "Não" → conta como começado E pendente,
  ///   true = feito;
  /// - booleano-resposta (tem radar? benefício ativo?): qualquer resposta
  ///   conta como preenchido — "Não" é resposta final, não pendência;
  /// - etapa 9 (Formalização de Pagamento): a documentação de financiamento
  ///   só entra na conta quando a forma escolhida é 'financiamento'.
  ({bool touched, bool allDone})? get _completion {
    final d = details;
    final a = aircraft;
    (bool, bool) text(String? v) {
      final ok = v != null && v.trim().isNotEmpty;
      return (ok, ok);
    }

    (bool, bool) task(bool? v) => (v != null, v == true);
    (bool, bool) answer(bool? v) => (v != null, v != null);

    List<(bool, bool)> fields;
    switch (_orderInt) {
      case 1:
        fields = [
          text(a?.stripeColor),
          text(a?.airFilter),
          text(a?.panel),
          text(d?.customizationDescription),
        ];
        break;
      case 2:
        fields = [text(d?.invoiceNumber)];
        break;
      case 3:
        fields = [text(d?.equipmentType)];
        break;
      case 4:
        fields = [task(d?.reservationPaid)];
        break;
      case 5:
        fields = [task(d?.fivePercentPaid)];
        break;
      case 6:
        fields = [answer(d?.fiscalBenefitActive), answer(d?.hasRadar)];
        break;
      case 7:
        fields = [text(d?.brokerName)];
        break;
      case 8:
        fields = [text(d?.brand), text(d?.prefix)];
        break;
      case 9:
        fields = [text(d?.paymentMethod)];
        if ((d?.paymentMethod ?? '').trim() == 'financiamento') {
          fields.addAll([
            task(d?.finDoc),
            task(d?.finContadora),
            task(d?.finEndUser),
            task(d?.finCpi),
            task(d?.finCartaHistorico),
            task(d?.finRefsComerciais),
            task(d?.finRefBancaria),
            task(d?.finFotosOperacao),
          ]);
        }
        break;
      case 10:
        fields = [task(d?.financingApproved)];
        break;
      case 11:
        fields = [task(d?.preContractSigned)];
        break;
      case 12:
        fields = [text(d?.insuranceCompany)];
        break;
      case 13:
        fields = [task(d?.insurancePolicySent)];
        break;
      case 14:
        fields = [text(d?.entryPaymentInfo)];
        break;
      case 17:
        fields = [task(d?.finalContractSigned)];
        break;
      case 19:
        fields = [text(d?.customsStatus), task(d?.customsCnd)];
        break;
      default:
        return null;
    }
    return (
      touched: fields.any((f) => f.$1),
      allDone: fields.every((f) => f.$2),
    );
  }

  /// Cor de fundo/borda do card (regra de 2026-07-15, vale para TODAS as
  /// etapas com campos, sobrepondo o "Concluído"):
  /// - nunca preenchido → neutro;
  /// - começou e falta algo → **vermelho**;
  /// - tudo preenchido → **verde**.
  /// Etapas de checklist (16/18) seguem a mesma ideia via [_checklist];
  /// etapas sem campos (só confirmação) ficam verdes quando `isCheck`.
  ({Color background, Color border})? get _cardTone {
    final cl = _checklist;
    if (cl != null) {
      if (cl.checked == 0) return null; // neutro
      if (cl.checked < cl.total) return _redTone; // parcial
      return _greenTone; // completo
    }
    final comp = _completion;
    if (comp != null) {
      if (!comp.touched) return null; // nunca preenchido → neutro
      if (!comp.allDone) return _redTone; // começou e falta algo → vermelho
      return _greenTone; // tudo preenchido → verde
    }
    return _checked ? _greenTone : null;
  }

  String get _statusLabel {
    if (_checked) {
      return _isConfigurable ? 'Configurado' : 'Confirmado';
    }
    return _isConfigurable ? 'Configurar' : 'Confirmar';
  }

  Future<void> _openAction(BuildContext context) async {
    final order = item.order?.toString() ?? '';
    final orderInt = int.tryParse(order) ?? 0;
    if (order == '1') {
      await _showStepDialog(
        context,
        ModalTrackingWidget(
          title: 'Preencha os campos abaixo com dados do cliente',
          order: 1,
          idTracking: item.id,
          userAircraftId: item.userAircraftId,
          onLinks: (_, __, ___, ____, _____) async {},
          onConfiguration:
              (stripeColor, filter, panel, isCheck, useraircraftId, trackingId) async {
            await UserAircraftTable().update(
              data: {
                'stripe_color': stripeColor,
                'air_filter': filter,
                'panel': panel,
              },
              matchingRows: (rows) =>
                  rows.eqOrNull('id', useraircraftId),
            );
            await TrackingTable().update(
              data: {'isCheck': isCheck},
              matchingRows: (rows) => rows.eqOrNull('id', trackingId),
            );
            _toast(context, 'Dados atualizados com sucesso!');
            await onChanged();
            if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
          },
        ),
      );
    } else if (order == '15') {
      await _showStepDialog(
        context,
        ModalTrackingWidget(
          title: 'Preencha o campo com o link do cliente',
          order: 15,
          idTracking: item.id,
          userAircraftId: item.userAircraftId,
          onLinks: (link1, link2, isCheck, idTracking, _) async {
            await TrackingTable().update(
              data: {'link': link1, 'link2': link2, 'isCheck': isCheck},
              matchingRows: (rows) => rows.eqOrNull('id', idTracking),
            );
            _toast(context, 'Link adicionado com sucesso!');
            await onChanged();
            if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
          },
          onConfiguration: (_, __, ___, ____, _____, ______) async {},
        ),
      );
    } else if (_kConfigurableOrders.contains(order) &&
        order != '1' &&
        order != '15') {
      await _showStepDialog(
        context,
        ModalTrackingWidget(
          title: item.trackingDescription,
          order: orderInt,
          idTracking: item.id,
          userAircraftId: item.userAircraftId,
          onConfirmStep: (trackingId) async {
            await TrackingTable().update(
              data: {'isCheck': true},
              matchingRows: (rows) => rows.eqOrNull('id', trackingId),
            );
            await onChanged();
          },
        ),
      );
    } else {
      await _showStepDialog(
        context,
        AlertDialogWidget(
          title: 'Deseja confirmar esta etapa do processo?',
          iconColor: const Color(0xFFC2D51C),
          btnColor: const Color(0xFFC2D51C),
          confirmBtnAction: () async {
            await TrackingTable().update(
              data: {'isCheck': true},
              matchingRows: (rows) => rows.eqOrNull('id', item.id),
            );
            if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
          },
        ),
      );
    }
    await onChanged();
  }

  Future<void> _openView(BuildContext context) async {
    await _showStepDialog(
      context,
      ModalTrackingWidget(
        title: item.trackingDescription,
        order: _orderInt < 0 ? 0 : _orderInt,
        idTracking: item.id,
        userAircraftId: userAircraftId,
      ),
    );
  }

  Future<void> _showStepDialog(BuildContext context, Widget child) {
    return showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        elevation: 0,
        insetPadding: EdgeInsets.zero,
        backgroundColor: Colors.transparent,
        alignment: Alignment.center,
        child: GestureDetector(
          onTap: () {
            FocusScope.of(dialogContext).unfocus();
            FocusManager.instance.primaryFocus?.unfocus();
          },
          child: child,
        ),
      ),
    );
  }

  void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Color(0xFF313131))),
        duration: const Duration(milliseconds: 4000),
        backgroundColor: const Color(0xFFC2D51C),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canAct = isAdmin && !_checked;
    final tone = _cardTone;
    return AppCard(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      background: tone?.background,
      border: tone != null
          ? Border.all(color: tone.border, width: 1.5)
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        // max + Spacer antes do rodapé: o conteúdo fica no topo e o botão
        // encosta na base, então cards da mesma linha (altura igual) ficam
        // alinhados sem sobra.
        mainAxisSize: MainAxisSize.max,
        children: [
          Row(
            children: [
              _StepBadge(
                icon: _iconForOrder(_orderInt),
                checked: _checked,
                order: _orderInt + 1,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.trackingDescription,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.1,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Etapa ${_orderInt + 1}',
                      style: GoogleFonts.roboto(
                        fontSize: 11.5,
                        color: const Color(0x99FFFFFF),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              AppStatusBadge(
                label: _checked ? 'Concluído' : 'Pendente',
                tone: _checked
                    ? AppStatusTone.success
                    : AppStatusTone.warning,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF313131),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0x14FFFFFF)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _MetaCol(label: 'PROPOSTA', value: refId),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetaCol(label: 'CLIENTE', value: clientName),
                ),
              ],
            ),
          ),
          if (_orderInt == 15 &&
              ((item.link?.isNotEmpty ?? false) ||
                  (item.link2?.isNotEmpty ?? false))) ...[
            const SizedBox(height: 10),
            if (item.link?.isNotEmpty ?? false)
              _LinkRow(label: 'Link 1', url: item.link ?? ''),
            if (item.link2?.isNotEmpty ?? false) ...[
              const SizedBox(height: 6),
              _LinkRow(label: 'Link 2', url: item.link2 ?? ''),
            ],
          ],
          if (_valueFields.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF313131),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0x14FFFFFF)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Dois campos por linha (lado a lado) para o card não ficar
                  // comprido. Última linha ímpar deixa a 2ª coluna vazia.
                  for (var i = 0; i < _valueFields.length; i += 2) ...[
                    if (i > 0) const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _MetaCol(
                            label: _valueFields[i].label.toUpperCase(),
                            value: _valueFields[i].value,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: i + 1 < _valueFields.length
                              ? _MetaCol(
                                  label:
                                      _valueFields[i + 1].label.toUpperCase(),
                                  value: _valueFields[i + 1].value,
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
          if (_checklist != null) ...[
            const SizedBox(height: 10),
            _ChecklistBar(
              checked: _checklist!.checked,
              total: _checklist!.total,
            ),
          ],
          const SizedBox(height: 14),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Rastreio é view-only para quem não pode editar (ex.: Vendedor):
              // sem botão de visualizar dados (abre modal editável) nem ação.
              if (_checked && isAdmin) ...[
                _GhostIconBtn(
                  icon: Icons.visibility_outlined,
                  tooltip: 'Visualizar dados',
                  onTap: () => _openView(context),
                ),
                const SizedBox(width: 8),
              ],
              if (isAdmin)
                AppPrimaryButton(
                  label: _statusLabel,
                  icon: _checked ? Icons.check_rounded : null,
                  onPressed: canAct ? () => _openAction(context) : null,
                )
              else
                AppStatusBadge(
                  label: 'Somente leitura',
                  tone: AppStatusTone.neutral,
                  icon: Icons.lock_outline_rounded,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepBadge extends StatelessWidget {
  const _StepBadge({
    required this.icon,
    required this.checked,
    required this.order,
  });

  final IconData icon;
  final bool checked;
  final int order;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: checked
              ? const [Color(0x55249689), Color(0x33249689)]
              : const [Color(0x55C2D51C), Color(0x33AEC117)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: checked
              ? const Color(0x554FBFA9)
              : const Color(0x55C2D51C),
        ),
      ),
      child: Stack(
        children: [
          Center(
            child: Icon(
              icon,
              size: 18,
              color: checked
                  ? const Color(0xFF4FBFA9)
                  : const Color(0xFFC2D51C),
            ),
          ),
          Positioned(
            right: 4,
            bottom: 2,
            child: Text(
              order.toString().padLeft(2, '0'),
              style: GoogleFonts.inter(
                fontSize: 8.5,
                fontWeight: FontWeight.w800,
                color: Colors.white.withValues(alpha: 0.8),
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaCol extends StatelessWidget {
  const _MetaCol({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
            color: const Color(0x88FFFFFF),
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.roboto(
            fontSize: 12.5,
            color: const Color(0xCCFFFFFF),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _FieldKV {
  const _FieldKV(this.label, this.value);
  final String label;
  final String value;
}

/// Resumo do checklist de documentos no card (etapas 16/18): "X de N
/// documentos", colorido por estado (neutro/vermelho/verde).
class _ChecklistBar extends StatelessWidget {
  const _ChecklistBar({required this.checked, required this.total});

  final int checked;
  final int total;

  @override
  Widget build(BuildContext context) {
    final started = checked > 0;
    final complete = checked >= total;
    final color = !started
        ? const Color(0x99FFFFFF)
        : complete
            ? const Color(0xFF4FBFA9)
            : const Color(0xFFFF5963);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF313131),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0x14FFFFFF)),
      ),
      child: Row(
        children: [
          Icon(
            complete
                ? Icons.check_circle_rounded
                : Icons.fact_check_outlined,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 8),
          Text(
            '$checked de $total documentos',
            style: GoogleFonts.roboto(
              fontSize: 12.5,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          if (started && !complete)
            Text(
              'faltam ${total - checked}',
              style: GoogleFonts.roboto(
                fontSize: 11,
                color: const Color(0xFFFF5963),
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }
}

class _LinkRow extends StatefulWidget {
  const _LinkRow({required this.label, required this.url});
  final String label;
  final String url;

  @override
  State<_LinkRow> createState() => _LinkRowState();
}

class _LinkRowState extends State<_LinkRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: () => openStorageDoc(widget.url),
        child: Row(
          children: [
            Icon(
              Icons.link_rounded,
              size: 13,
              color: _hover
                  ? const Color(0xFFC2D51C)
                  : const Color(0x99FFFFFF),
            ),
            const SizedBox(width: 6),
            Text(
              '${widget.label}: ',
              style: GoogleFonts.roboto(
                fontSize: 11.5,
                color: const Color(0x99FFFFFF),
              ),
            ),
            Expanded(
              child: Text(
                widget.url,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.roboto(
                  fontSize: 11.5,
                  color: _hover
                      ? const Color(0xFFC2D51C)
                      : const Color(0xCCFFFFFF),
                  fontWeight: FontWeight.w500,
                  decoration: _hover
                      ? TextDecoration.underline
                      : TextDecoration.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GhostIconBtn extends StatefulWidget {
  const _GhostIconBtn({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  State<_GhostIconBtn> createState() => _GhostIconBtnState();
}

class _GhostIconBtnState extends State<_GhostIconBtn> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _hover
                  ? const Color(0x22C2D51C)
                  : Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _hover
                    ? const Color(0x55C2D51C)
                    : Colors.white.withValues(alpha: 0.06),
              ),
            ),
            child: Icon(
              widget.icon,
              size: 17,
              color:
                  _hover ? const Color(0xFFC2D51C) : const Color(0xCCFFFFFF),
            ),
          ),
        ),
      ),
    );
  }
}
