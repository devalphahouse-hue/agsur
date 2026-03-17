import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_drop_down.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/form_field_controller.dart';
import '/flutter_flow/upload_data.dart';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'modal_tracking_model.dart';
export 'modal_tracking_model.dart';

class ModalTrackingWidget extends StatefulWidget {
  const ModalTrackingWidget({
    super.key,
    required this.title,
    required this.order,
    required this.idTracking,
    required this.userAircraftId,
    this.onLinks,
    this.onConfiguration,
    this.onConfirmStep,
  });

  final String? title;
  final int? order;
  final String? idTracking;
  final String? userAircraftId;
  final Future Function(String link1, String link2, bool isCheck,
      String idTracking, String useraircraftId)? onLinks;
  final Future Function(String stripeColor, String filter, String panel,
      bool isCheck, String useraircraftId, String trackingId)? onConfiguration;
  final Future Function(String trackingId)? onConfirmStep;

  @override
  State<ModalTrackingWidget> createState() => _ModalTrackingWidgetState();
}

class _ModalTrackingWidgetState extends State<ModalTrackingWidget>
    with TickerProviderStateMixin {
  late ModalTrackingModel _model;

  final animationsMap = <String, AnimationInfo>{};

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ModalTrackingModel());

    _model.tFLink1TextController ??= TextEditingController();
    _model.tFLink1FocusNode ??= FocusNode();

    _model.tFLink2TextController ??= TextEditingController();
    _model.tFLink2FocusNode ??= FocusNode();

    _model.tFDescTecnicaTextController ??= TextEditingController();
    _model.tFDescTecnicaFocusNode ??= FocusNode();

    _model.tFStripeColorTextController ??= TextEditingController();
    _model.tFStripeColorFocusNode ??= FocusNode();

    _model.tFFilterTextController ??= TextEditingController();
    _model.tFFilterFocusNode ??= FocusNode();

    _model.tFPanelTextController ??= TextEditingController();
    _model.tFPanelFocusNode ??= FocusNode();

    _model.tXTinvoiceTextController ??= TextEditingController();
    _model.tXTinvoiceFocusNode ??= FocusNode();

    _model.tXTipoEquipamentoTextController ??= TextEditingController();
    _model.tXTipoEquipamentoFocusNode ??= FocusNode();

    _model.tXTNomeDespachanteTextController ??= TextEditingController();
    _model.tXTNomeDespachanteFocusNode ??= FocusNode();

    _model.tXTPrefixoTextController ??= TextEditingController();
    _model.tXTPrefixoFocusNode ??= FocusNode();

    _model.tXTMarcaTextController ??= TextEditingController();
    _model.tXTMarcaFocusNode ??= FocusNode();

    _model.tXTSeguradoraTextController ??= TextEditingController();
    _model.tXTSeguradoraFocusNode ??= FocusNode();

    // CA/CM doc uploads initialized in model

    // Load existing tracking_details for this tracking_id
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      if (widget.idTracking == null || widget.idTracking!.isEmpty) {
        safeSetState(() => _model.detailsLoaded = true);
        return;
      }

      try {
        final existingRows = await TrackingDetailsTable().queryRows(
          queryFn: (q) => q.eq('tracking_id', widget.idTracking!),
          limit: 1,
        );
        if (existingRows.isNotEmpty) {
          final row = existingRows.first;
          safeSetState(() {
            _model.existingDetailsId = row.id;
            // Order 16 - Oficina
            _model.oficInvoice = row.oficInvoice ?? false;
            _model.oficExportCertificate = row.oficExportCertificate ?? false;
            _model.oficBillOfSale = row.oficBillOfSale ?? false;
            _model.oficTecat = row.oficTecat ?? false;
            _model.oficAadsac = row.oficAadsac ?? false;
            _model.oficGendec = row.oficGendec ?? false;
            _model.oficSpecialAirworthness = row.oficSpecialAirworthness ?? false;
            _model.oficSeguroReta = row.oficSeguroReta ?? false;
            _model.oficBoletoReta = row.oficBoletoReta ?? false;
            _model.oficComprovanteReta = row.oficComprovanteReta ?? false;
            _model.oficDocsDespachante = row.oficDocsDespachante ?? false;
            _model.oficCopiaCadernetas = row.oficCopiaCadernetas ?? false;
            _model.oficPesoBalanceamento = row.oficPesoBalanceamento ?? false;
            _model.oficDesregistro = row.oficDesregistro ?? false;
            _model.oficFlightTest = row.oficFlightTest ?? false;
            _model.oficForm337 = row.oficForm337 ?? false;
            _model.oficListaComponentes = row.oficListaComponentes ?? false;
            _model.oficListaAds = row.oficListaAds ?? false;
            // Order 18 - Despachante
            _model.despCnd = row.despCnd ?? false;
            _model.despInvoice = row.despInvoice ?? false;
            _model.despExportCertificate = row.despExportCertificate ?? false;
            _model.despBillOfSale = row.despBillOfSale ?? false;
            _model.despTecat = row.despTecat ?? false;
            _model.despAvanac = row.despAvanac ?? false;
            _model.despGendec = row.despGendec ?? false;
            _model.despSpecialAirworthness = row.despSpecialAirworthness ?? false;
            _model.despSeguroReta = row.despSeguroReta ?? false;
            _model.despBoletoReta = row.despBoletoReta ?? false;
            _model.despComprovanteReta = row.despComprovanteReta ?? false;
            // Order 19 - Customs
            _model.customsStatus = row.customsStatus;
            _model.customsCnd = row.customsCnd ?? false;
            // Order 20 - Docs
            if (row.caDocumentUrl != null && row.caDocumentUrl!.isNotEmpty) {
              _model.uploadedFileUrl_caDoc = row.caDocumentUrl!;
            }
            if (row.cmDocumentUrl != null && row.cmDocumentUrl!.isNotEmpty) {
              _model.uploadedFileUrl_cmDoc = row.cmDocumentUrl!;
            }
            // Order 1 - Personalização
            if (row.customizationDescription != null && row.customizationDescription!.isNotEmpty) {
              _model.tFDescTecnicaTextController?.text = row.customizationDescription!;
            }
            // Order 2 - Invoice
            if (row.invoiceNumber != null && row.invoiceNumber!.isNotEmpty) {
              _model.tXTinvoiceTextController?.text = row.invoiceNumber!;
            }
            // Order 3 - Tipo de Equipamento
            if (row.equipmentType != null && row.equipmentType!.isNotEmpty) {
              _model.tXTipoEquipamentoTextController?.text = row.equipmentType!;
            }
            // Order 7 - Nome do Despachante
            if (row.brokerName != null && row.brokerName!.isNotEmpty) {
              _model.tXTNomeDespachanteTextController?.text = row.brokerName!;
            }
            // Order 8 - Prefixo, Marca e Documento
            if (row.prefix != null && row.prefix!.isNotEmpty) {
              _model.tXTPrefixoTextController?.text = row.prefix!;
            }
            if (row.brand != null && row.brand!.isNotEmpty) {
              _model.tXTMarcaTextController?.text = row.brand!;
            }
            if (row.prefixFileUrl != null && row.prefixFileUrl!.isNotEmpty) {
              _model.uploadedFileUrl_uploadDataPh0 = row.prefixFileUrl!;
            }
            // Order 12 - Seguradora
            if (row.insuranceCompany != null && row.insuranceCompany!.isNotEmpty) {
              _model.tXTSeguradoraTextController?.text = row.insuranceCompany!;
            }
            // Order 9 - Formalização de Pagamento
            _model.paymentMethod = row.paymentMethod;
            _model.finDoc = row.finDoc ?? false;
            _model.finContadora = row.finContadora ?? false;
            _model.finEndUser = row.finEndUser ?? false;
            _model.finCpi = row.finCpi ?? false;
            _model.finCartaHistorico = row.finCartaHistorico ?? false;
            _model.finRefsComerciais = row.finRefsComerciais ?? false;
            _model.finRefBancaria = row.finRefBancaria ?? false;
            _model.finFotosOperacao = row.finFotosOperacao ?? false;
            // Other fields
            _model.fiscalBenefitActive = row.fiscalBenefitActive ?? true;
            _model.hasRadar = row.hasRadar ?? false;
            _model.reservationPaid = row.reservationPaid ?? false;
            _model.fivePercentPaid = row.fivePercentPaid ?? false;
            _model.financingApproved = row.financingApproved ?? false;
            _model.preContractSigned = row.preContractSigned ?? false;
            _model.insurancePolicySent = row.insurancePolicySent ?? false;
            _model.finalContractSigned = row.finalContractSigned ?? false;
            _model.entryPaymentInfo = row.entryPaymentInfo;
            _model.detailsLoaded = true;
          });
        } else {
          safeSetState(() => _model.detailsLoaded = true);
        }
      } catch (e) {
        debugPrint('Erro ao carregar tracking_details: $e');
        safeSetState(() => _model.detailsLoaded = true);
      }

      // Load user_aircraft data for order 1 (Personalização) fields
      try {
        if (widget.userAircraftId != null && widget.userAircraftId!.isNotEmpty) {
          final uaRows = await UserAircraftTable().queryRows(
            queryFn: (q) => q.eq('id', widget.userAircraftId!),
            limit: 1,
          );
          if (uaRows.isNotEmpty) {
            final ua = uaRows.first;
            safeSetState(() {
              if (ua.stripeColor != null && ua.stripeColor!.isNotEmpty) {
                _model.tFStripeColorTextController?.text = ua.stripeColor!;
              }
              if (ua.airFilter != null && ua.airFilter!.isNotEmpty) {
                _model.tFFilterTextController?.text = ua.airFilter!;
              }
              if (ua.panel != null && ua.panel!.isNotEmpty) {
                _model.tFPanelTextController?.text = ua.panel!;
              }
            });
          }
        }
      } catch (e) {
        debugPrint('Erro ao carregar user_aircraft: $e');
      }

      // Load tracking data for order 15 (links)
      try {
        if (widget.idTracking != null && widget.idTracking!.isNotEmpty) {
          final trackingRows = await TrackingTable().queryRows(
            queryFn: (q) => q.eq('id', widget.idTracking!),
            limit: 1,
          );
          if (trackingRows.isNotEmpty) {
            final tr = trackingRows.first;
            safeSetState(() {
              if (tr.link != null && tr.link!.isNotEmpty) {
                _model.tFLink1TextController?.text = tr.link!;
              }
              if (tr.link2 != null && tr.link2!.isNotEmpty) {
                _model.tFLink2TextController?.text = tr.link2!;
              }
            });
          }
        }
      } catch (e) {
        debugPrint('Erro ao carregar tracking links: $e');
      }
    });

    animationsMap.addAll({
      'containerOnPageLoadAnimation': AnimationInfo(
        trigger: AnimationTrigger.onPageLoad,
        effectsBuilder: () => [
          ScaleEffect(
            curve: Curves.easeInOut,
            delay: 0.0.ms,
            duration: 500.0.ms,
            begin: Offset(0.0, 0.0),
            end: Offset(1.0, 1.0),
          ),
        ],
      ),
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional(0.0, -1.0),
      child: Padding(
        padding: EdgeInsets.all(36.0),
        child: Container(
          width: MediaQuery.sizeOf(context).width * 1.0,
          constraints: BoxConstraints(
            maxWidth: 800.0,
            maxHeight: MediaQuery.sizeOf(context).height * 0.9,
          ),
          decoration: BoxDecoration(
            color: Color(0xFF313131),
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Align(
                alignment: AlignmentDirectional(1.0, -1.0),
                child: Padding(
                  padding:
                      EdgeInsetsDirectional.fromSTEB(12.0, 12.0, 12.0, 16.0),
                  child: InkWell(
                    splashColor: Colors.transparent,
                    focusColor: Colors.transparent,
                    hoverColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    onTap: () async {
                      Navigator.pop(context);
                    },
                    child: Icon(
                      Icons.close_sharp,
                      color: Color(0x72FFFFFF),
                      size: 24.0,
                    ),
                  ),
                ),
              ),
              Text(
                valueOrDefault<String>(
                  widget!.title,
                  'Preencha os dados abaixo para prosseguir',
                ),
                style: FlutterFlowTheme.of(context).bodyMedium.override(
                      font: GoogleFonts.inter(
                        fontWeight: FontWeight.w500,
                        fontStyle:
                            FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                      ),
                      color: FlutterFlowTheme.of(context).secondaryBackground,
                      fontSize: 18.0,
                      letterSpacing: 0.0,
                      fontWeight: FontWeight.w500,
                      fontStyle:
                          FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                    ),
              ),
              Align(
                alignment: AlignmentDirectional(0.0, 0.0),
                child: Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(0.0, 4.0, 0.0, 0.0),
                  child: Text(
                    'Preencha os dados abaixo para prosseguir',
                    textAlign: TextAlign.center,
                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                          font: GoogleFonts.inter(
                            fontWeight: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .fontWeight,
                            fontStyle: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .fontStyle,
                          ),
                          color: Color(0x74FFFFFF),
                          fontSize: 14.0,
                          letterSpacing: 0.0,
                          fontWeight: FlutterFlowTheme.of(context)
                              .bodyMedium
                              .fontWeight,
                          fontStyle:
                              FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                        ),
                  ),
                ),
              ),
              Flexible(
                child: Builder(
                builder: (context) {
                  if (widget!.order == 15) {
                    return Form(
                      key: _model.formKey8,
                      autovalidateMode: AutovalidateMode.disabled,
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            TextFormField(
                              controller: _model.tFLink1TextController,
                              focusNode: _model.tFLink1FocusNode,
                              autofocus: false,
                              obscureText: false,
                              decoration: InputDecoration(
                                isDense: false,
                                labelText: 'Link 01',
                                labelStyle: FlutterFlowTheme.of(context)
                                    .labelMedium
                                    .override(
                                      font: GoogleFonts.inter(
                                        fontWeight: FlutterFlowTheme.of(context)
                                            .labelMedium
                                            .fontWeight,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .labelMedium
                                            .fontStyle,
                                      ),
                                      color: FlutterFlowTheme.of(context)
                                          .secondaryBackground,
                                      letterSpacing: 0.0,
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .labelMedium
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .labelMedium
                                          .fontStyle,
                                    ),
                                hintText: 'https://seulinkaqui.com.br',
                                hintStyle: FlutterFlowTheme.of(context)
                                    .labelMedium
                                    .override(
                                      font: GoogleFonts.inter(
                                        fontWeight: FlutterFlowTheme.of(context)
                                            .labelMedium
                                            .fontWeight,
                                        fontStyle: FontStyle.italic,
                                      ),
                                      color: FlutterFlowTheme.of(context)
                                          .secondaryBackground,
                                      letterSpacing: 0.0,
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .labelMedium
                                          .fontWeight,
                                      fontStyle: FontStyle.italic,
                                    ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Color(0x72FFFFFF),
                                    width: 1.0,
                                  ),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: FlutterFlowTheme.of(context)
                                        .primaryText,
                                    width: 1.0,
                                  ),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: FlutterFlowTheme.of(context).error,
                                    width: 1.0,
                                  ),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: FlutterFlowTheme.of(context).error,
                                    width: 1.0,
                                  ),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                filled: true,
                                fillColor: Color(0xFF404040),
                              ),
                              style: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .override(
                                    font: GoogleFonts.inter(
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontStyle,
                                    ),
                                    color: FlutterFlowTheme.of(context)
                                        .secondaryBackground,
                                    letterSpacing: 0.0,
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontStyle,
                                  ),
                              cursorColor: FlutterFlowTheme.of(context)
                                  .secondaryBackground,
                              validator: _model.tFLink1TextControllerValidator
                                  .asValidator(context),
                            ),
                            Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                  0.0, 12.0, 0.0, 0.0),
                              child: TextFormField(
                                controller: _model.tFLink2TextController,
                                focusNode: _model.tFLink2FocusNode,
                                autofocus: false,
                                obscureText: false,
                                decoration: InputDecoration(
                                  isDense: false,
                                  labelText: 'Link 02',
                                  labelStyle: FlutterFlowTheme.of(context)
                                      .labelMedium
                                      .override(
                                        font: GoogleFonts.inter(
                                          fontWeight:
                                              FlutterFlowTheme.of(context)
                                                  .labelMedium
                                                  .fontWeight,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .labelMedium
                                                  .fontStyle,
                                        ),
                                        color: FlutterFlowTheme.of(context)
                                            .secondaryBackground,
                                        letterSpacing: 0.0,
                                        fontWeight: FlutterFlowTheme.of(context)
                                            .labelMedium
                                            .fontWeight,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .labelMedium
                                            .fontStyle,
                                      ),
                                  hintText: 'https://seulinkaqui.com.br',
                                  hintStyle: FlutterFlowTheme.of(context)
                                      .labelMedium
                                      .override(
                                        font: GoogleFonts.inter(
                                          fontWeight:
                                              FlutterFlowTheme.of(context)
                                                  .labelMedium
                                                  .fontWeight,
                                          fontStyle: FontStyle.italic,
                                        ),
                                        color: FlutterFlowTheme.of(context)
                                            .secondaryBackground,
                                        letterSpacing: 0.0,
                                        fontWeight: FlutterFlowTheme.of(context)
                                            .labelMedium
                                            .fontWeight,
                                        fontStyle: FontStyle.italic,
                                      ),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Color(0x72FFFFFF),
                                      width: 1.0,
                                    ),
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: FlutterFlowTheme.of(context)
                                          .primaryText,
                                      width: 1.0,
                                    ),
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: FlutterFlowTheme.of(context).error,
                                      width: 1.0,
                                    ),
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  focusedErrorBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: FlutterFlowTheme.of(context).error,
                                      width: 1.0,
                                    ),
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  filled: true,
                                  fillColor: Color(0xFF404040),
                                ),
                                style: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .override(
                                      font: GoogleFonts.inter(
                                        fontWeight: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .fontWeight,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .fontStyle,
                                      ),
                                      color: FlutterFlowTheme.of(context)
                                          .secondaryBackground,
                                      letterSpacing: 0.0,
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontStyle,
                                    ),
                                cursorColor: FlutterFlowTheme.of(context)
                                    .secondaryBackground,
                                validator: _model.tFLink2TextControllerValidator
                                    .asValidator(context),
                              ),
                            ),
                            Align(
                              alignment: AlignmentDirectional(1.0, 0.0),
                              child: Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    4.0, 16.0, 4.0, 16.0),
                                child: FFButtonWidget(
                                  onPressed: () async {
                                    if (_model.formKey8.currentState == null ||
                                        !_model.formKey8.currentState!
                                            .validate()) {
                                      return;
                                    }
                                    if (widget.onLinks != null) {
                                      await widget.onLinks!.call(
                                        _model.tFLink1TextController.text,
                                        _model.tFLink2TextController.text,
                                        true,
                                        widget.idTracking!,
                                        widget.userAircraftId ?? '',
                                      );
                                    } else {
                                      // Eye icon edit mode: save links directly
                                      if (widget.idTracking != null) {
                                        await TrackingTable().update(
                                          data: {
                                            'link': _model.tFLink1TextController.text,
                                            'link2': _model.tFLink2TextController.text,
                                          },
                                          matchingRows: (rows) => rows.eqOrNull('id', widget.idTracking!),
                                        );
                                      }
                                      Navigator.pop(context);
                                    }
                                  },
                                  text: 'Cadastrar',
                                  options: FFButtonOptions(
                                    height: 48.0,
                                    padding: EdgeInsetsDirectional.fromSTEB(
                                        48.0, 0.0, 48.0, 0.0),
                                    iconPadding: EdgeInsetsDirectional.fromSTEB(
                                        0.0, 0.0, 0.0, 0.0),
                                    color: FlutterFlowTheme.of(context).primary,
                                    textStyle: FlutterFlowTheme.of(context)
                                        .titleSmall
                                        .override(
                                          font: GoogleFonts.inter(
                                            fontWeight:
                                                FlutterFlowTheme.of(context)
                                                    .titleSmall
                                                    .fontWeight,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .titleSmall
                                                    .fontStyle,
                                          ),
                                          color: FlutterFlowTheme.of(context)
                                              .primaryText,
                                          fontSize: 14.0,
                                          letterSpacing: 0.0,
                                          fontWeight:
                                              FlutterFlowTheme.of(context)
                                                  .titleSmall
                                                  .fontWeight,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .titleSmall
                                                  .fontStyle,
                                        ),
                                    elevation: 0.0,
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                ),
                              ),
                            ),
                          ].divide(SizedBox(height: 16.0)),
                        ),
                      ),
                    );
                  } else if (widget!.order == 1) {
                    return Form(
                      key: _model.formKey3,
                      autovalidateMode: AutovalidateMode.disabled,
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            TextFormField(
                              controller: _model.tFStripeColorTextController,
                              focusNode: _model.tFStripeColorFocusNode,
                              autofocus: false,
                              obscureText: false,
                              decoration: InputDecoration(
                                isDense: false,
                                labelText: 'Cor da faixa',
                                labelStyle: FlutterFlowTheme.of(context)
                                    .labelMedium
                                    .override(
                                      font: GoogleFonts.inter(
                                        fontWeight: FlutterFlowTheme.of(context)
                                            .labelMedium
                                            .fontWeight,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .labelMedium
                                            .fontStyle,
                                      ),
                                      color: FlutterFlowTheme.of(context)
                                          .secondaryBackground,
                                      letterSpacing: 0.0,
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .labelMedium
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .labelMedium
                                          .fontStyle,
                                    ),
                                hintText: 'Cor da faixa',
                                hintStyle: FlutterFlowTheme.of(context)
                                    .labelMedium
                                    .override(
                                      font: GoogleFonts.inter(
                                        fontWeight: FlutterFlowTheme.of(context)
                                            .labelMedium
                                            .fontWeight,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .labelMedium
                                            .fontStyle,
                                      ),
                                      color: FlutterFlowTheme.of(context)
                                          .secondaryBackground,
                                      letterSpacing: 0.0,
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .labelMedium
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .labelMedium
                                          .fontStyle,
                                    ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Color(0x72FFFFFF),
                                    width: 1.0,
                                  ),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: FlutterFlowTheme.of(context)
                                        .primaryText,
                                    width: 1.0,
                                  ),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: FlutterFlowTheme.of(context).error,
                                    width: 1.0,
                                  ),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: FlutterFlowTheme.of(context).error,
                                    width: 1.0,
                                  ),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                filled: true,
                                fillColor: Color(0xFF404040),
                              ),
                              style: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .override(
                                    font: GoogleFonts.inter(
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontStyle,
                                    ),
                                    color: FlutterFlowTheme.of(context)
                                        .secondaryBackground,
                                    letterSpacing: 0.0,
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontStyle,
                                  ),
                              cursorColor: FlutterFlowTheme.of(context)
                                  .secondaryBackground,
                              validator: _model
                                  .tFStripeColorTextControllerValidator
                                  .asValidator(context),
                            ),
                            TextFormField(
                              controller: _model.tFFilterTextController,
                              focusNode: _model.tFFilterFocusNode,
                              autofocus: false,
                              obscureText: false,
                              decoration: InputDecoration(
                                isDense: false,
                                labelText: 'Filtro de Ar',
                                labelStyle: FlutterFlowTheme.of(context)
                                    .labelMedium
                                    .override(
                                      font: GoogleFonts.inter(
                                        fontWeight: FlutterFlowTheme.of(context)
                                            .labelMedium
                                            .fontWeight,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .labelMedium
                                            .fontStyle,
                                      ),
                                      color: FlutterFlowTheme.of(context)
                                          .secondaryBackground,
                                      letterSpacing: 0.0,
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .labelMedium
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .labelMedium
                                          .fontStyle,
                                    ),
                                hintText: 'Filtro de Ar',
                                hintStyle: FlutterFlowTheme.of(context)
                                    .labelMedium
                                    .override(
                                      font: GoogleFonts.inter(
                                        fontWeight: FlutterFlowTheme.of(context)
                                            .labelMedium
                                            .fontWeight,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .labelMedium
                                            .fontStyle,
                                      ),
                                      color: FlutterFlowTheme.of(context)
                                          .secondaryBackground,
                                      letterSpacing: 0.0,
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .labelMedium
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .labelMedium
                                          .fontStyle,
                                    ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Color(0x72FFFFFF),
                                    width: 1.0,
                                  ),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: FlutterFlowTheme.of(context)
                                        .primaryText,
                                    width: 1.0,
                                  ),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: FlutterFlowTheme.of(context).error,
                                    width: 1.0,
                                  ),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: FlutterFlowTheme.of(context).error,
                                    width: 1.0,
                                  ),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                filled: true,
                                fillColor: Color(0xFF404040),
                              ),
                              style: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .override(
                                    font: GoogleFonts.inter(
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontStyle,
                                    ),
                                    color: FlutterFlowTheme.of(context)
                                        .secondaryBackground,
                                    letterSpacing: 0.0,
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontStyle,
                                  ),
                              cursorColor: FlutterFlowTheme.of(context)
                                  .secondaryBackground,
                              validator: _model.tFFilterTextControllerValidator
                                  .asValidator(context),
                            ),
                            TextFormField(
                              controller: _model.tFPanelTextController,
                              focusNode: _model.tFPanelFocusNode,
                              autofocus: false,
                              obscureText: false,
                              decoration: InputDecoration(
                                isDense: false,
                                labelText: 'Painel',
                                labelStyle: FlutterFlowTheme.of(context)
                                    .labelMedium
                                    .override(
                                      font: GoogleFonts.inter(
                                        fontWeight: FlutterFlowTheme.of(context)
                                            .labelMedium
                                            .fontWeight,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .labelMedium
                                            .fontStyle,
                                      ),
                                      color: FlutterFlowTheme.of(context)
                                          .secondaryBackground,
                                      letterSpacing: 0.0,
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .labelMedium
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .labelMedium
                                          .fontStyle,
                                    ),
                                hintText: 'Painel',
                                hintStyle: FlutterFlowTheme.of(context)
                                    .labelMedium
                                    .override(
                                      font: GoogleFonts.inter(
                                        fontWeight: FlutterFlowTheme.of(context)
                                            .labelMedium
                                            .fontWeight,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .labelMedium
                                            .fontStyle,
                                      ),
                                      color: FlutterFlowTheme.of(context)
                                          .secondaryBackground,
                                      letterSpacing: 0.0,
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .labelMedium
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .labelMedium
                                          .fontStyle,
                                    ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Color(0x72FFFFFF),
                                    width: 1.0,
                                  ),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: FlutterFlowTheme.of(context)
                                        .primaryText,
                                    width: 1.0,
                                  ),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: FlutterFlowTheme.of(context).error,
                                    width: 1.0,
                                  ),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: FlutterFlowTheme.of(context).error,
                                    width: 1.0,
                                  ),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                filled: true,
                                fillColor: Color(0xFF404040),
                              ),
                              style: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .override(
                                    font: GoogleFonts.inter(
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontStyle,
                                    ),
                                    color: FlutterFlowTheme.of(context)
                                        .secondaryBackground,
                                    letterSpacing: 0.0,
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontStyle,
                                  ),
                              cursorColor: FlutterFlowTheme.of(context)
                                  .secondaryBackground,
                              validator: _model.tFPanelTextControllerValidator
                                  .asValidator(context),
                            ),
                            TextFormField(
                              controller: _model.tFDescTecnicaTextController,
                              focusNode: _model.tFDescTecnicaFocusNode,
                              autofocus: false,
                              obscureText: false,
                              maxLines: 3,
                              minLines: 2,
                              decoration: InputDecoration(
                                isDense: false,
                                labelText: 'Descrição Técnica',
                                labelStyle: FlutterFlowTheme.of(context)
                                    .labelMedium
                                    .override(
                                      font: GoogleFonts.inter(
                                        fontWeight: FlutterFlowTheme.of(context)
                                            .labelMedium
                                            .fontWeight,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .labelMedium
                                            .fontStyle,
                                      ),
                                      color: FlutterFlowTheme.of(context)
                                          .secondaryBackground,
                                      letterSpacing: 0.0,
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .labelMedium
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .labelMedium
                                          .fontStyle,
                                    ),
                                hintText: 'Descrição Técnica',
                                hintStyle: FlutterFlowTheme.of(context)
                                    .labelMedium
                                    .override(
                                      font: GoogleFonts.inter(
                                        fontWeight: FlutterFlowTheme.of(context)
                                            .labelMedium
                                            .fontWeight,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .labelMedium
                                            .fontStyle,
                                      ),
                                      color: FlutterFlowTheme.of(context)
                                          .secondaryBackground,
                                      letterSpacing: 0.0,
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .labelMedium
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .labelMedium
                                          .fontStyle,
                                    ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Color(0x72FFFFFF),
                                    width: 1.0,
                                  ),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: FlutterFlowTheme.of(context)
                                        .primaryText,
                                    width: 1.0,
                                  ),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: FlutterFlowTheme.of(context).error,
                                    width: 1.0,
                                  ),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: FlutterFlowTheme.of(context).error,
                                    width: 1.0,
                                  ),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                filled: true,
                                fillColor: Color(0xFF404040),
                              ),
                              style: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .override(
                                    font: GoogleFonts.inter(
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontStyle,
                                    ),
                                    color: FlutterFlowTheme.of(context)
                                        .secondaryBackground,
                                    letterSpacing: 0.0,
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontStyle,
                                  ),
                              cursorColor: FlutterFlowTheme.of(context)
                                  .secondaryBackground,
                              validator: _model
                                  .tFDescTecnicaTextControllerValidator
                                  .asValidator(context),
                            ),
                            Align(
                              alignment: AlignmentDirectional(1.0, 0.0),
                              child: Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    4.0, 16.0, 4.0, 16.0),
                                child: FFButtonWidget(
                                  onPressed: () async {
                                    if (_model.formKey3.currentState == null ||
                                        !_model.formKey3.currentState!
                                            .validate()) {
                                      return;
                                    }
                                    await _saveTrackingDetails({
                                      'customization_description': _model.tFDescTecnicaTextController?.text ?? '',
                                    });
                                    if (widget.onConfiguration != null) {
                                      await widget.onConfiguration!.call(
                                        _model.tFStripeColorTextController.text,
                                        _model.tFFilterTextController.text,
                                        _model.tFPanelTextController.text,
                                        true,
                                        widget.userAircraftId ?? '',
                                        widget.idTracking!,
                                      );
                                    } else {
                                      // Eye icon edit mode: save directly to user_aircraft
                                      if (widget.userAircraftId != null && widget.userAircraftId!.isNotEmpty) {
                                        await UserAircraftTable().update(
                                          data: {
                                            'stripe_color': _model.tFStripeColorTextController.text,
                                            'air_filter': _model.tFFilterTextController.text,
                                            'panel': _model.tFPanelTextController.text,
                                          },
                                          matchingRows: (rows) => rows.eqOrNull('id', widget.userAircraftId!),
                                        );
                                      }
                                      Navigator.pop(context);
                                    }
                                  },
                                  text: 'Cadastrar',
                                  options: FFButtonOptions(
                                    height: 48.0,
                                    padding: EdgeInsetsDirectional.fromSTEB(
                                        48.0, 0.0, 48.0, 0.0),
                                    iconPadding: EdgeInsetsDirectional.fromSTEB(
                                        0.0, 0.0, 0.0, 0.0),
                                    color: FlutterFlowTheme.of(context).primary,
                                    textStyle: FlutterFlowTheme.of(context)
                                        .titleSmall
                                        .override(
                                          font: GoogleFonts.inter(
                                            fontWeight:
                                                FlutterFlowTheme.of(context)
                                                    .titleSmall
                                                    .fontWeight,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .titleSmall
                                                    .fontStyle,
                                          ),
                                          color: FlutterFlowTheme.of(context)
                                              .primaryText,
                                          fontSize: 14.0,
                                          letterSpacing: 0.0,
                                          fontWeight:
                                              FlutterFlowTheme.of(context)
                                                  .titleSmall
                                                  .fontWeight,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .titleSmall
                                                  .fontStyle,
                                        ),
                                    elevation: 0.0,
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                ),
                              ),
                            ),
                          ].divide(SizedBox(height: 20.0)),
                        ),
                      ),
                    );
                  } else if (widget!.order == 2) {
                    return Form(
                      key: _model.formKey1,
                      autovalidateMode: AutovalidateMode.disabled,
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            TextFormField(
                              controller: _model.tXTinvoiceTextController,
                              focusNode: _model.tXTinvoiceFocusNode,
                              autofocus: false,
                              obscureText: false,
                              decoration: InputDecoration(
                                isDense: false,
                                labelText: 'Número da Invoice',
                                labelStyle: FlutterFlowTheme.of(context)
                                    .labelMedium
                                    .override(
                                      font: GoogleFonts.inter(
                                        fontWeight: FlutterFlowTheme.of(context)
                                            .labelMedium
                                            .fontWeight,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .labelMedium
                                            .fontStyle,
                                      ),
                                      color: FlutterFlowTheme.of(context)
                                          .secondaryBackground,
                                      letterSpacing: 0.0,
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .labelMedium
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .labelMedium
                                          .fontStyle,
                                    ),
                                hintText: 'Número da Invoice',
                                hintStyle: FlutterFlowTheme.of(context)
                                    .labelMedium
                                    .override(
                                      font: GoogleFonts.inter(
                                        fontWeight: FlutterFlowTheme.of(context)
                                            .labelMedium
                                            .fontWeight,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .labelMedium
                                            .fontStyle,
                                      ),
                                      color: FlutterFlowTheme.of(context)
                                          .secondaryBackground,
                                      letterSpacing: 0.0,
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .labelMedium
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .labelMedium
                                          .fontStyle,
                                    ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Color(0x72FFFFFF),
                                    width: 1.0,
                                  ),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: FlutterFlowTheme.of(context)
                                        .primaryText,
                                    width: 1.0,
                                  ),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: FlutterFlowTheme.of(context).error,
                                    width: 1.0,
                                  ),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: FlutterFlowTheme.of(context).error,
                                    width: 1.0,
                                  ),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                filled: true,
                                fillColor: Color(0xFF404040),
                              ),
                              style: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .override(
                                    font: GoogleFonts.inter(
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontStyle,
                                    ),
                                    color: FlutterFlowTheme.of(context)
                                        .secondaryBackground,
                                    letterSpacing: 0.0,
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontStyle,
                                  ),
                              keyboardType: TextInputType.number,
                              cursorColor: FlutterFlowTheme.of(context)
                                  .secondaryBackground,
                              validator: _model
                                  .tXTinvoiceTextControllerValidator
                                  .asValidator(context),
                            ),
                            Align(
                              alignment: AlignmentDirectional(1.0, 0.0),
                              child: Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    4.0, 16.0, 4.0, 16.0),
                                child: FFButtonWidget(
                                  onPressed: () async {
                                    if (_model.formKey1.currentState == null ||
                                        !_model.formKey1.currentState!
                                            .validate()) {
                                      return;
                                    }
                                    await _saveTrackingDetails({
                                      'invoice_number':
                                          _model.tXTinvoiceTextController.text,
                                    });
                                    await widget.onConfirmStep
                                        ?.call(widget.idTracking!);
                                    Navigator.pop(context);
                                  },
                                  text: 'Cadastrar',
                                  options: FFButtonOptions(
                                    height: 48.0,
                                    padding: EdgeInsetsDirectional.fromSTEB(
                                        48.0, 0.0, 48.0, 0.0),
                                    iconPadding: EdgeInsetsDirectional.fromSTEB(
                                        0.0, 0.0, 0.0, 0.0),
                                    color: FlutterFlowTheme.of(context).primary,
                                    textStyle: FlutterFlowTheme.of(context)
                                        .titleSmall
                                        .override(
                                          font: GoogleFonts.inter(
                                            fontWeight:
                                                FlutterFlowTheme.of(context)
                                                    .titleSmall
                                                    .fontWeight,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .titleSmall
                                                    .fontStyle,
                                          ),
                                          color: FlutterFlowTheme.of(context)
                                              .primaryText,
                                          fontSize: 14.0,
                                          letterSpacing: 0.0,
                                          fontWeight:
                                              FlutterFlowTheme.of(context)
                                                  .titleSmall
                                                  .fontWeight,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .titleSmall
                                                  .fontStyle,
                                        ),
                                    elevation: 0.0,
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                ),
                              ),
                            ),
                          ].divide(SizedBox(height: 20.0)),
                        ),
                      ),
                    );
                  } else if (widget!.order == 3) {
                    return Form(
                      key: _model.formKey2,
                      autovalidateMode: AutovalidateMode.disabled,
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            TextFormField(
                              controller:
                                  _model.tXTipoEquipamentoTextController,
                              focusNode: _model.tXTipoEquipamentoFocusNode,
                              autofocus: false,
                              obscureText: false,
                              decoration: InputDecoration(
                                isDense: false,
                                labelText: 'Tipo de equipamento',
                                labelStyle: FlutterFlowTheme.of(context)
                                    .labelMedium
                                    .override(
                                      font: GoogleFonts.inter(
                                        fontWeight: FlutterFlowTheme.of(context)
                                            .labelMedium
                                            .fontWeight,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .labelMedium
                                            .fontStyle,
                                      ),
                                      color: FlutterFlowTheme.of(context)
                                          .secondaryBackground,
                                      letterSpacing: 0.0,
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .labelMedium
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .labelMedium
                                          .fontStyle,
                                    ),
                                hintText: 'Tipo de equipamento',
                                hintStyle: FlutterFlowTheme.of(context)
                                    .labelMedium
                                    .override(
                                      font: GoogleFonts.inter(
                                        fontWeight: FlutterFlowTheme.of(context)
                                            .labelMedium
                                            .fontWeight,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .labelMedium
                                            .fontStyle,
                                      ),
                                      color: FlutterFlowTheme.of(context)
                                          .secondaryBackground,
                                      letterSpacing: 0.0,
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .labelMedium
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .labelMedium
                                          .fontStyle,
                                    ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Color(0x72FFFFFF),
                                    width: 1.0,
                                  ),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: FlutterFlowTheme.of(context)
                                        .primaryText,
                                    width: 1.0,
                                  ),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: FlutterFlowTheme.of(context).error,
                                    width: 1.0,
                                  ),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: FlutterFlowTheme.of(context).error,
                                    width: 1.0,
                                  ),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                filled: true,
                                fillColor: Color(0xFF404040),
                              ),
                              style: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .override(
                                    font: GoogleFonts.inter(
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontStyle,
                                    ),
                                    color: FlutterFlowTheme.of(context)
                                        .secondaryBackground,
                                    letterSpacing: 0.0,
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontStyle,
                                  ),
                              cursorColor: FlutterFlowTheme.of(context)
                                  .secondaryBackground,
                              validator: _model
                                  .tXTipoEquipamentoTextControllerValidator
                                  .asValidator(context),
                            ),
                            Align(
                              alignment: AlignmentDirectional(1.0, 0.0),
                              child: Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    4.0, 16.0, 4.0, 16.0),
                                child: FFButtonWidget(
                                  onPressed: () async {
                                    if (_model.formKey2.currentState == null ||
                                        !_model.formKey2.currentState!
                                            .validate()) {
                                      return;
                                    }
                                    await _saveTrackingDetails({
                                      'equipment_type': _model
                                          .tXTipoEquipamentoTextController.text,
                                    });
                                    await widget.onConfirmStep
                                        ?.call(widget.idTracking!);
                                    Navigator.pop(context);
                                  },
                                  text: 'Cadastrar',
                                  options: FFButtonOptions(
                                    height: 48.0,
                                    padding: EdgeInsetsDirectional.fromSTEB(
                                        48.0, 0.0, 48.0, 0.0),
                                    iconPadding: EdgeInsetsDirectional.fromSTEB(
                                        0.0, 0.0, 0.0, 0.0),
                                    color: FlutterFlowTheme.of(context).primary,
                                    textStyle: FlutterFlowTheme.of(context)
                                        .titleSmall
                                        .override(
                                          font: GoogleFonts.inter(
                                            fontWeight:
                                                FlutterFlowTheme.of(context)
                                                    .titleSmall
                                                    .fontWeight,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .titleSmall
                                                    .fontStyle,
                                          ),
                                          color: FlutterFlowTheme.of(context)
                                              .primaryText,
                                          fontSize: 14.0,
                                          letterSpacing: 0.0,
                                          fontWeight:
                                              FlutterFlowTheme.of(context)
                                                  .titleSmall
                                                  .fontWeight,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .titleSmall
                                                  .fontStyle,
                                        ),
                                    elevation: 0.0,
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                ),
                              ),
                            ),
                          ].divide(SizedBox(height: 20.0)),
                        ),
                      ),
                    );
                  } else if (widget!.order == 6) {
                    return Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Column(
                            mainAxisSize: MainAxisSize.max,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Benefício Fiscal Ativo',
                                style: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .override(
                                      font: GoogleFonts.inter(
                                        fontWeight: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .fontWeight,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .fontStyle,
                                      ),
                                      color: FlutterFlowTheme.of(context).info,
                                      letterSpacing: 0.0,
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontStyle,
                                    ),
                              ),
                              Container(
                                width: 150.0,
                                height: 30.0,
                                decoration: BoxDecoration(
                                  color: FlutterFlowTheme.of(context)
                                      .secondaryBackground,
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                child: Padding(
                                  padding: EdgeInsets.all(2.0),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.max,
                                    children: [
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () => safeSetState(() =>
                                              _model.fiscalBenefitActive = true),
                                          child: Container(
                                            width: 100.0,
                                            height: 100.0,
                                            decoration: BoxDecoration(
                                              color: _model.fiscalBenefitActive
                                                  ? FlutterFlowTheme.of(context)
                                                      .primary
                                                  : FlutterFlowTheme.of(context)
                                                      .secondaryBackground,
                                              borderRadius: BorderRadius.only(
                                                bottomLeft: Radius.circular(8.0),
                                                bottomRight:
                                                    Radius.circular(0.0),
                                                topLeft: Radius.circular(8.0),
                                                topRight: Radius.circular(0.0),
                                              ),
                                            ),
                                            alignment:
                                                AlignmentDirectional(0.0, 0.0),
                                            child: Text(
                                              'Sim',
                                              style: FlutterFlowTheme.of(context)
                                                  .bodyMedium
                                                  .override(
                                                    font: GoogleFonts.inter(
                                                      fontWeight:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .bodyMedium
                                                              .fontWeight,
                                                      fontStyle:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .bodyMedium
                                                              .fontStyle,
                                                    ),
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .primaryText,
                                                    letterSpacing: 0.0,
                                                    fontWeight:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .bodyMedium
                                                            .fontWeight,
                                                    fontStyle:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .bodyMedium
                                                            .fontStyle,
                                                  ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () => safeSetState(() =>
                                              _model.fiscalBenefitActive =
                                                  false),
                                          child: Container(
                                            width: 100.0,
                                            height: 100.0,
                                            decoration: BoxDecoration(
                                              color: !_model.fiscalBenefitActive
                                                  ? FlutterFlowTheme.of(context)
                                                      .primary
                                                  : FlutterFlowTheme.of(context)
                                                      .secondaryBackground,
                                              borderRadius: BorderRadius.only(
                                                bottomLeft:
                                                    Radius.circular(0.0),
                                                bottomRight:
                                                    Radius.circular(8.0),
                                                topLeft: Radius.circular(0.0),
                                                topRight: Radius.circular(8.0),
                                              ),
                                            ),
                                            alignment:
                                                AlignmentDirectional(0.0, 0.0),
                                            child: Text(
                                              'Não',
                                              style: FlutterFlowTheme.of(context)
                                                  .bodyMedium
                                                  .override(
                                                    font: GoogleFonts.inter(
                                                      fontWeight:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .bodyMedium
                                                              .fontWeight,
                                                      fontStyle:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .bodyMedium
                                                              .fontStyle,
                                                    ),
                                                    letterSpacing: 0.0,
                                                    fontWeight:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .bodyMedium
                                                            .fontWeight,
                                                    fontStyle:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .bodyMedium
                                                            .fontStyle,
                                                  ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ].divide(SizedBox(height: 4.0)),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.max,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Possui RADAR',
                                style: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .override(
                                      font: GoogleFonts.inter(
                                        fontWeight: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .fontWeight,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .fontStyle,
                                      ),
                                      color: FlutterFlowTheme.of(context).info,
                                      letterSpacing: 0.0,
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontStyle,
                                    ),
                              ),
                              Container(
                                width: 150.0,
                                height: 30.0,
                                decoration: BoxDecoration(
                                  color: FlutterFlowTheme.of(context)
                                      .secondaryBackground,
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                child: Padding(
                                  padding: EdgeInsets.all(2.0),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.max,
                                    children: [
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () => safeSetState(
                                              () => _model.hasRadar = true),
                                          child: Container(
                                            width: 100.0,
                                            height: 100.0,
                                            decoration: BoxDecoration(
                                              color: _model.hasRadar
                                                  ? FlutterFlowTheme.of(context)
                                                      .primary
                                                  : FlutterFlowTheme.of(context)
                                                      .secondaryBackground,
                                              borderRadius: BorderRadius.only(
                                                bottomLeft: Radius.circular(8.0),
                                                bottomRight:
                                                    Radius.circular(0.0),
                                                topLeft: Radius.circular(8.0),
                                                topRight: Radius.circular(0.0),
                                              ),
                                            ),
                                            alignment:
                                                AlignmentDirectional(0.0, 0.0),
                                            child: Text(
                                              'Sim',
                                              style: FlutterFlowTheme.of(context)
                                                  .bodyMedium
                                                  .override(
                                                    font: GoogleFonts.inter(
                                                      fontWeight:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .bodyMedium
                                                              .fontWeight,
                                                      fontStyle:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .bodyMedium
                                                              .fontStyle,
                                                    ),
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .primaryText,
                                                    letterSpacing: 0.0,
                                                    fontWeight:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .bodyMedium
                                                            .fontWeight,
                                                    fontStyle:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .bodyMedium
                                                            .fontStyle,
                                                  ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () => safeSetState(
                                              () => _model.hasRadar = false),
                                          child: Container(
                                            width: 100.0,
                                            height: 100.0,
                                            decoration: BoxDecoration(
                                              color: !_model.hasRadar
                                                  ? FlutterFlowTheme.of(context)
                                                      .primary
                                                  : FlutterFlowTheme.of(context)
                                                      .secondaryBackground,
                                              borderRadius: BorderRadius.only(
                                                bottomLeft:
                                                    Radius.circular(0.0),
                                                bottomRight:
                                                    Radius.circular(8.0),
                                                topLeft: Radius.circular(0.0),
                                                topRight: Radius.circular(8.0),
                                              ),
                                            ),
                                            alignment:
                                                AlignmentDirectional(0.0, 0.0),
                                            child: Text(
                                              'Não',
                                              style: FlutterFlowTheme.of(context)
                                                  .bodyMedium
                                                  .override(
                                                    font: GoogleFonts.inter(
                                                      fontWeight:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .bodyMedium
                                                              .fontWeight,
                                                      fontStyle:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .bodyMedium
                                                              .fontStyle,
                                                    ),
                                                    letterSpacing: 0.0,
                                                    fontWeight:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .bodyMedium
                                                            .fontWeight,
                                                    fontStyle:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .bodyMedium
                                                            .fontStyle,
                                                  ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ].divide(SizedBox(height: 4.0)),
                          ),
                          Padding(
                            padding: EdgeInsetsDirectional.fromSTEB(
                                4.0, 16.0, 4.0, 16.0),
                            child: FFButtonWidget(
                              onPressed: () async {
                                await _saveTrackingDetails({
                                  'fiscal_benefit_active':
                                      _model.fiscalBenefitActive,
                                  'has_radar': _model.hasRadar,
                                });
                                await widget.onConfirmStep
                                    ?.call(widget.idTracking!);
                                Navigator.pop(context);
                              },
                              text: 'Cadastrar',
                              options: FFButtonOptions(
                                height: 48.0,
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    48.0, 0.0, 48.0, 0.0),
                                iconPadding: EdgeInsetsDirectional.fromSTEB(
                                    0.0, 0.0, 0.0, 0.0),
                                color: FlutterFlowTheme.of(context).primary,
                                textStyle: FlutterFlowTheme.of(context)
                                    .titleSmall
                                    .override(
                                      font: GoogleFonts.inter(
                                        fontWeight: FlutterFlowTheme.of(context)
                                            .titleSmall
                                            .fontWeight,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .titleSmall
                                            .fontStyle,
                                      ),
                                      color: FlutterFlowTheme.of(context)
                                          .primaryText,
                                      fontSize: 14.0,
                                      letterSpacing: 0.0,
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .titleSmall
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .titleSmall
                                          .fontStyle,
                                    ),
                                elevation: 0.0,
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                          ),
                        ].divide(SizedBox(height: 20.0)),
                      ),
                    );
                  } else if (widget!.order == 7) {
                    return Form(
                      key: _model.formKey5,
                      autovalidateMode: AutovalidateMode.disabled,
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            TextFormField(
                              controller:
                                  _model.tXTNomeDespachanteTextController,
                              focusNode: _model.tXTNomeDespachanteFocusNode,
                              autofocus: false,
                              obscureText: false,
                              decoration: InputDecoration(
                                isDense: false,
                                labelText: 'Nome do Despachante',
                                labelStyle: FlutterFlowTheme.of(context)
                                    .labelMedium
                                    .override(
                                      font: GoogleFonts.inter(
                                        fontWeight: FlutterFlowTheme.of(context)
                                            .labelMedium
                                            .fontWeight,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .labelMedium
                                            .fontStyle,
                                      ),
                                      color: FlutterFlowTheme.of(context)
                                          .secondaryBackground,
                                      letterSpacing: 0.0,
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .labelMedium
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .labelMedium
                                          .fontStyle,
                                    ),
                                hintText: 'Nome do Despachante',
                                hintStyle: FlutterFlowTheme.of(context)
                                    .labelMedium
                                    .override(
                                      font: GoogleFonts.inter(
                                        fontWeight: FlutterFlowTheme.of(context)
                                            .labelMedium
                                            .fontWeight,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .labelMedium
                                            .fontStyle,
                                      ),
                                      color: FlutterFlowTheme.of(context)
                                          .secondaryBackground,
                                      letterSpacing: 0.0,
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .labelMedium
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .labelMedium
                                          .fontStyle,
                                    ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Color(0x72FFFFFF),
                                    width: 1.0,
                                  ),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: FlutterFlowTheme.of(context)
                                        .primaryText,
                                    width: 1.0,
                                  ),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: FlutterFlowTheme.of(context).error,
                                    width: 1.0,
                                  ),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: FlutterFlowTheme.of(context).error,
                                    width: 1.0,
                                  ),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                filled: true,
                                fillColor: Color(0xFF404040),
                              ),
                              style: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .override(
                                    font: GoogleFonts.inter(
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontStyle,
                                    ),
                                    color: FlutterFlowTheme.of(context)
                                        .secondaryBackground,
                                    letterSpacing: 0.0,
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontStyle,
                                  ),
                              cursorColor: FlutterFlowTheme.of(context)
                                  .secondaryBackground,
                              validator: _model
                                  .tXTNomeDespachanteTextControllerValidator
                                  .asValidator(context),
                            ),
                            Align(
                              alignment: AlignmentDirectional(1.0, 0.0),
                              child: Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    4.0, 16.0, 4.0, 16.0),
                                child: FFButtonWidget(
                                  onPressed: () async {
                                    if (_model.formKey5.currentState == null ||
                                        !_model.formKey5.currentState!
                                            .validate()) {
                                      return;
                                    }
                                    await _saveTrackingDetails({
                                      'broker_name': _model
                                          .tXTNomeDespachanteTextController.text,
                                    });
                                    await widget.onConfirmStep
                                        ?.call(widget.idTracking!);
                                    Navigator.pop(context);
                                  },
                                  text: 'Cadastrar',
                                  options: FFButtonOptions(
                                    height: 48.0,
                                    padding: EdgeInsetsDirectional.fromSTEB(
                                        48.0, 0.0, 48.0, 0.0),
                                    iconPadding: EdgeInsetsDirectional.fromSTEB(
                                        0.0, 0.0, 0.0, 0.0),
                                    color: FlutterFlowTheme.of(context).primary,
                                    textStyle: FlutterFlowTheme.of(context)
                                        .titleSmall
                                        .override(
                                          font: GoogleFonts.inter(
                                            fontWeight:
                                                FlutterFlowTheme.of(context)
                                                    .titleSmall
                                                    .fontWeight,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .titleSmall
                                                    .fontStyle,
                                          ),
                                          color: FlutterFlowTheme.of(context)
                                              .primaryText,
                                          fontSize: 14.0,
                                          letterSpacing: 0.0,
                                          fontWeight:
                                              FlutterFlowTheme.of(context)
                                                  .titleSmall
                                                  .fontWeight,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .titleSmall
                                                  .fontStyle,
                                        ),
                                    elevation: 0.0,
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                ),
                              ),
                            ),
                          ].divide(SizedBox(height: 20.0)),
                        ),
                      ),
                    );
                  } else if (widget!.order == 8) {
                    return Form(
                      key: _model.formKey7,
                      autovalidateMode: AutovalidateMode.disabled,
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextFormField(
                              controller: _model.tXTPrefixoTextController,
                              focusNode: _model.tXTPrefixoFocusNode,
                              autofocus: false,
                              obscureText: false,
                              decoration: InputDecoration(
                                isDense: false,
                                labelText: 'Prefixo',
                                labelStyle: FlutterFlowTheme.of(context)
                                    .labelMedium
                                    .override(
                                      font: GoogleFonts.inter(
                                        fontWeight: FlutterFlowTheme.of(context)
                                            .labelMedium
                                            .fontWeight,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .labelMedium
                                            .fontStyle,
                                      ),
                                      color: FlutterFlowTheme.of(context)
                                          .secondaryBackground,
                                      letterSpacing: 0.0,
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .labelMedium
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .labelMedium
                                          .fontStyle,
                                    ),
                                hintText: 'Prefixo',
                                hintStyle: FlutterFlowTheme.of(context)
                                    .labelMedium
                                    .override(
                                      font: GoogleFonts.inter(
                                        fontWeight: FlutterFlowTheme.of(context)
                                            .labelMedium
                                            .fontWeight,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .labelMedium
                                            .fontStyle,
                                      ),
                                      color: FlutterFlowTheme.of(context)
                                          .secondaryBackground,
                                      letterSpacing: 0.0,
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .labelMedium
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .labelMedium
                                          .fontStyle,
                                    ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Color(0x72FFFFFF),
                                    width: 1.0,
                                  ),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: FlutterFlowTheme.of(context)
                                        .primaryText,
                                    width: 1.0,
                                  ),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: FlutterFlowTheme.of(context).error,
                                    width: 1.0,
                                  ),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: FlutterFlowTheme.of(context).error,
                                    width: 1.0,
                                  ),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                filled: true,
                                fillColor: Color(0xFF404040),
                              ),
                              style: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .override(
                                    font: GoogleFonts.inter(
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontStyle,
                                    ),
                                    color: FlutterFlowTheme.of(context)
                                        .secondaryBackground,
                                    letterSpacing: 0.0,
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontStyle,
                                  ),
                              cursorColor: FlutterFlowTheme.of(context)
                                  .secondaryBackground,
                              validator: _model
                                  .tXTPrefixoTextControllerValidator
                                  .asValidator(context),
                            ),
                            TextFormField(
                              controller: _model.tXTMarcaTextController,
                              focusNode: _model.tXTMarcaFocusNode,
                              autofocus: false,
                              obscureText: false,
                              decoration: InputDecoration(
                                isDense: false,
                                labelText: 'Marca',
                                labelStyle: FlutterFlowTheme.of(context)
                                    .labelMedium
                                    .override(
                                      font: GoogleFonts.inter(
                                        fontWeight: FlutterFlowTheme.of(context)
                                            .labelMedium
                                            .fontWeight,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .labelMedium
                                            .fontStyle,
                                      ),
                                      color: FlutterFlowTheme.of(context)
                                          .secondaryBackground,
                                      letterSpacing: 0.0,
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .labelMedium
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .labelMedium
                                          .fontStyle,
                                    ),
                                hintText: 'Marca',
                                hintStyle: FlutterFlowTheme.of(context)
                                    .labelMedium
                                    .override(
                                      font: GoogleFonts.inter(
                                        fontWeight: FlutterFlowTheme.of(context)
                                            .labelMedium
                                            .fontWeight,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .labelMedium
                                            .fontStyle,
                                      ),
                                      color: FlutterFlowTheme.of(context)
                                          .secondaryBackground,
                                      letterSpacing: 0.0,
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .labelMedium
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .labelMedium
                                          .fontStyle,
                                    ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Color(0x72FFFFFF),
                                    width: 1.0,
                                  ),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: FlutterFlowTheme.of(context)
                                        .primaryText,
                                    width: 1.0,
                                  ),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: FlutterFlowTheme.of(context).error,
                                    width: 1.0,
                                  ),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: FlutterFlowTheme.of(context).error,
                                    width: 1.0,
                                  ),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                filled: true,
                                fillColor: Color(0xFF404040),
                              ),
                              style: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .override(
                                    font: GoogleFonts.inter(
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontStyle,
                                    ),
                                    color: FlutterFlowTheme.of(context)
                                        .secondaryBackground,
                                    letterSpacing: 0.0,
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontStyle,
                                  ),
                              cursorColor: FlutterFlowTheme.of(context)
                                  .secondaryBackground,
                              validator: _model.tXTMarcaTextControllerValidator
                                  .asValidator(context),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.max,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    if (_model.uploadedFileUrl_uploadDataPh0 !=
                                            null &&
                                        _model.uploadedFileUrl_uploadDataPh0 !=
                                            '')
                                      Icon(
                                        Icons.check_circle,
                                        color: FlutterFlowTheme.of(context)
                                            .success,
                                        size: 24.0,
                                      ),
                                    Text(
                                      'Upload de Documento',
                                      style: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .override(
                                            font: GoogleFonts.inter(
                                              fontWeight:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyMedium
                                                      .fontWeight,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyMedium
                                                      .fontStyle,
                                            ),
                                            color: FlutterFlowTheme.of(context)
                                                .info,
                                            letterSpacing: 0.0,
                                            fontWeight:
                                                FlutterFlowTheme.of(context)
                                                    .bodyMedium
                                                    .fontWeight,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .bodyMedium
                                                    .fontStyle,
                                          ),
                                    ),
                                  ].divide(SizedBox(width: 8.0)),
                                ),
                                FFButtonWidget(
                                  onPressed: () async {
                                    final selectedFiles = await selectFiles(
                                      storageFolderPath: '',
                                      multiFile: false,
                                    );
                                    if (selectedFiles != null) {
                                      safeSetState(() =>
                                          _model.isDataUploading_uploadDataPh0 =
                                              true);
                                      var selectedUploadedFiles =
                                          <FFUploadedFile>[];

                                      var downloadUrls = <String>[];
                                      try {
                                        selectedUploadedFiles = selectedFiles
                                            .map((m) => FFUploadedFile(
                                                  name: m.storagePath
                                                      .split('/')
                                                      .last,
                                                  bytes: m.bytes,
                                                  originalFilename:
                                                      m.originalFilename,
                                                ))
                                            .toList();

                                        downloadUrls =
                                            await uploadSupabaseStorageFiles(
                                          bucketName: 'AGSur',
                                          selectedFiles: selectedFiles,
                                        );
                                      } finally {
                                        _model.isDataUploading_uploadDataPh0 =
                                            false;
                                      }
                                      if (selectedUploadedFiles.length ==
                                              selectedFiles.length &&
                                          downloadUrls.length ==
                                              selectedFiles.length) {
                                        safeSetState(() {
                                          _model.uploadedLocalFile_uploadDataPh0 =
                                              selectedUploadedFiles.first;
                                          _model.uploadedFileUrl_uploadDataPh0 =
                                              downloadUrls.first;
                                        });
                                      } else {
                                        safeSetState(() {});
                                        return;
                                      }
                                    }
                                  },
                                  text: 'Upload',
                                  options: FFButtonOptions(
                                    width: 150.0,
                                    height: 40.0,
                                    padding: EdgeInsetsDirectional.fromSTEB(
                                        16.0, 0.0, 16.0, 0.0),
                                    iconPadding: EdgeInsetsDirectional.fromSTEB(
                                        0.0, 0.0, 0.0, 0.0),
                                    color: FlutterFlowTheme.of(context).primary,
                                    textStyle: FlutterFlowTheme.of(context)
                                        .titleSmall
                                        .override(
                                          font: GoogleFonts.inter(
                                            fontWeight:
                                                FlutterFlowTheme.of(context)
                                                    .titleSmall
                                                    .fontWeight,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .titleSmall
                                                    .fontStyle,
                                          ),
                                          color: Colors.white,
                                          letterSpacing: 0.0,
                                          fontWeight:
                                              FlutterFlowTheme.of(context)
                                                  .titleSmall
                                                  .fontWeight,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .titleSmall
                                                  .fontStyle,
                                        ),
                                    elevation: 0.0,
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                ),
                              ].divide(SizedBox(height: 4.0)),
                            ),
                            Align(
                              alignment: AlignmentDirectional(1.0, 0.0),
                              child: Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    4.0, 16.0, 4.0, 16.0),
                                child: FFButtonWidget(
                                  onPressed: () async {
                                    if (_model.formKey7.currentState == null ||
                                        !_model.formKey7.currentState!
                                            .validate()) {
                                      return;
                                    }
                                    await _saveTrackingDetails({
                                      'prefix':
                                          _model.tXTPrefixoTextController.text,
                                      'brand':
                                          _model.tXTMarcaTextController.text,
                                      'prefix_file_url': _model
                                          .uploadedFileUrl_uploadDataPh0,
                                    });
                                    await widget.onConfirmStep
                                        ?.call(widget.idTracking!);
                                    Navigator.pop(context);
                                  },
                                  text: 'Cadastrar',
                                  options: FFButtonOptions(
                                    height: 48.0,
                                    padding: EdgeInsetsDirectional.fromSTEB(
                                        48.0, 0.0, 48.0, 0.0),
                                    iconPadding: EdgeInsetsDirectional.fromSTEB(
                                        0.0, 0.0, 0.0, 0.0),
                                    color: FlutterFlowTheme.of(context).primary,
                                    textStyle: FlutterFlowTheme.of(context)
                                        .titleSmall
                                        .override(
                                          font: GoogleFonts.inter(
                                            fontWeight:
                                                FlutterFlowTheme.of(context)
                                                    .titleSmall
                                                    .fontWeight,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .titleSmall
                                                    .fontStyle,
                                          ),
                                          color: FlutterFlowTheme.of(context)
                                              .primaryText,
                                          fontSize: 14.0,
                                          letterSpacing: 0.0,
                                          fontWeight:
                                              FlutterFlowTheme.of(context)
                                                  .titleSmall
                                                  .fontWeight,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .titleSmall
                                                  .fontStyle,
                                        ),
                                    elevation: 0.0,
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                ),
                              ),
                            ),
                          ].divide(SizedBox(height: 20.0)),
                        ),
                      ),
                    );
                  } else if (widget!.order == 9) {
                    return Padding(
                      padding: EdgeInsets.all(24.0),
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Formalização de Pagamento',
                              style: FlutterFlowTheme.of(context).titleMedium.override(
                                font: GoogleFonts.inter(),
                                color: Colors.white,
                                fontSize: 16.0,
                                letterSpacing: 0.0,
                              ),
                            ),
                            SizedBox(height: 16.0),
                            Text(
                              'Forma de pagamento',
                              style: FlutterFlowTheme.of(context).bodyMedium.override(
                                font: GoogleFonts.inter(
                                  fontWeight: FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                                  fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                ),
                                color: Color(0x73FFFFFF),
                                letterSpacing: 0.0,
                                fontWeight: FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                                fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                              ),
                            ),
                            SizedBox(height: 8.0),
                            Wrap(
                              spacing: 8.0,
                              runSpacing: 8.0,
                              children: [
                                GestureDetector(
                                  onTap: () => safeSetState(() => _model.paymentMethod = 'vista'),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                                    decoration: BoxDecoration(
                                      color: _model.paymentMethod == 'vista' ? FlutterFlowTheme.of(context).primary : Color(0xFF404040),
                                      borderRadius: BorderRadius.circular(8.0),
                                      border: _model.paymentMethod == 'vista' ? Border.all(color: Colors.white, width: 2.0) : null,
                                    ),
                                    child: Text(
                                      'Pagamento à Vista',
                                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                                        font: GoogleFonts.inter(),
                                        color: Colors.white,
                                        letterSpacing: 0.0,
                                        fontWeight: _model.paymentMethod == 'vista' ? FontWeight.w600 : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => safeSetState(() => _model.paymentMethod = 'financiamento'),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                                    decoration: BoxDecoration(
                                      color: _model.paymentMethod == 'financiamento' ? FlutterFlowTheme.of(context).primary : Color(0xFF404040),
                                      borderRadius: BorderRadius.circular(8.0),
                                      border: _model.paymentMethod == 'financiamento' ? Border.all(color: Colors.white, width: 2.0) : null,
                                    ),
                                    child: Text(
                                      'Financiamento',
                                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                                        font: GoogleFonts.inter(),
                                        color: Colors.white,
                                        letterSpacing: 0.0,
                                        fontWeight: _model.paymentMethod == 'financiamento' ? FontWeight.w600 : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (_model.paymentMethod == 'financiamento') ...[
                              SizedBox(height: 20.0),
                              Text(
                                'Documentação para Financiamento',
                                style: FlutterFlowTheme.of(context).bodyMedium.override(
                                  font: GoogleFonts.inter(
                                    fontWeight: FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                  ),
                                  color: Color(0x73FFFFFF),
                                  letterSpacing: 0.0,
                                  fontWeight: FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                                  fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                ),
                              ),
                              SizedBox(height: 8.0),
                              ..._buildDocChecklist(context, [
                                _DocItem('Doc', _model.finDoc, () => safeSetState(() => _model.finDoc = true), () => safeSetState(() => _model.finDoc = false)),
                                _DocItem('Contadora', _model.finContadora, () => safeSetState(() => _model.finContadora = true), () => safeSetState(() => _model.finContadora = false)),
                                _DocItem('End User', _model.finEndUser, () => safeSetState(() => _model.finEndUser = true), () => safeSetState(() => _model.finEndUser = false)),
                                _DocItem('CPI', _model.finCpi, () => safeSetState(() => _model.finCpi = true), () => safeSetState(() => _model.finCpi = false)),
                                _DocItem('Carta Histórico', _model.finCartaHistorico, () => safeSetState(() => _model.finCartaHistorico = true), () => safeSetState(() => _model.finCartaHistorico = false)),
                                _DocItem('3x Refs Comerciais', _model.finRefsComerciais, () => safeSetState(() => _model.finRefsComerciais = true), () => safeSetState(() => _model.finRefsComerciais = false)),
                                _DocItem('Ref Bancária', _model.finRefBancaria, () => safeSetState(() => _model.finRefBancaria = true), () => safeSetState(() => _model.finRefBancaria = false)),
                                _DocItem('Fotos da Operação', _model.finFotosOperacao, () => safeSetState(() => _model.finFotosOperacao = true), () => safeSetState(() => _model.finFotosOperacao = false)),
                              ]),
                            ],
                            SizedBox(height: 24.0),
                            Align(
                              alignment: AlignmentDirectional(1.0, 0.0),
                              child: FFButtonWidget(
                                onPressed: () async {
                                  await _saveTrackingDetails({
                                    'payment_method': _model.paymentMethod,
                                    'fin_doc': _model.finDoc,
                                    'fin_contadora': _model.finContadora,
                                    'fin_end_user': _model.finEndUser,
                                    'fin_cpi': _model.finCpi,
                                    'fin_carta_historico': _model.finCartaHistorico,
                                    'fin_refs_comerciais': _model.finRefsComerciais,
                                    'fin_ref_bancaria': _model.finRefBancaria,
                                    'fin_fotos_operacao': _model.finFotosOperacao,
                                  });
                                  if (widget.idTracking != null) {
                                    await widget.onConfirmStep?.call(widget.idTracking!);
                                  }
                                  Navigator.pop(context);
                                },
                                text: 'Confirmar',
                                options: FFButtonOptions(
                                  height: 48.0,
                                  padding: EdgeInsetsDirectional.fromSTEB(48.0, 0.0, 48.0, 0.0),
                                  iconPadding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                                  color: FlutterFlowTheme.of(context).primary,
                                  textStyle: FlutterFlowTheme.of(context).titleSmall.override(
                                    font: GoogleFonts.inter(
                                      fontWeight: FlutterFlowTheme.of(context).titleSmall.fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context).titleSmall.fontStyle,
                                    ),
                                    color: FlutterFlowTheme.of(context).primaryText,
                                    fontSize: 14.0,
                                    letterSpacing: 0.0,
                                    fontWeight: FlutterFlowTheme.of(context).titleSmall.fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context).titleSmall.fontStyle,
                                  ),
                                  elevation: 0.0,
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  } else if (widget!.order == 12) {
                    return Form(
                      key: _model.formKey4,
                      autovalidateMode: AutovalidateMode.disabled,
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextFormField(
                              controller: _model.tXTSeguradoraTextController,
                              focusNode: _model.tXTSeguradoraFocusNode,
                              autofocus: false,
                              obscureText: false,
                              decoration: InputDecoration(
                                isDense: false,
                                labelText: 'Nome da seguradora',
                                labelStyle: FlutterFlowTheme.of(context)
                                    .labelMedium
                                    .override(
                                      font: GoogleFonts.inter(
                                        fontWeight: FlutterFlowTheme.of(context)
                                            .labelMedium
                                            .fontWeight,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .labelMedium
                                            .fontStyle,
                                      ),
                                      color: FlutterFlowTheme.of(context)
                                          .secondaryBackground,
                                      letterSpacing: 0.0,
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .labelMedium
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .labelMedium
                                          .fontStyle,
                                    ),
                                hintText: 'Nome da seguradora',
                                hintStyle: FlutterFlowTheme.of(context)
                                    .labelMedium
                                    .override(
                                      font: GoogleFonts.inter(
                                        fontWeight: FlutterFlowTheme.of(context)
                                            .labelMedium
                                            .fontWeight,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .labelMedium
                                            .fontStyle,
                                      ),
                                      color: FlutterFlowTheme.of(context)
                                          .secondaryBackground,
                                      letterSpacing: 0.0,
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .labelMedium
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .labelMedium
                                          .fontStyle,
                                    ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Color(0x72FFFFFF),
                                    width: 1.0,
                                  ),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: FlutterFlowTheme.of(context)
                                        .primaryText,
                                    width: 1.0,
                                  ),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: FlutterFlowTheme.of(context).error,
                                    width: 1.0,
                                  ),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: FlutterFlowTheme.of(context).error,
                                    width: 1.0,
                                  ),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                filled: true,
                                fillColor: Color(0xFF404040),
                              ),
                              style: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .override(
                                    font: GoogleFonts.inter(
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontStyle,
                                    ),
                                    color: FlutterFlowTheme.of(context)
                                        .secondaryBackground,
                                    letterSpacing: 0.0,
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontStyle,
                                  ),
                              cursorColor: FlutterFlowTheme.of(context)
                                  .secondaryBackground,
                              validator: _model
                                  .tXTSeguradoraTextControllerValidator
                                  .asValidator(context),
                            ),
                            Align(
                              alignment: AlignmentDirectional(1.0, 0.0),
                              child: Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    4.0, 16.0, 4.0, 16.0),
                                child: FFButtonWidget(
                                  onPressed: () async {
                                    if (_model.formKey4.currentState == null ||
                                        !_model.formKey4.currentState!
                                            .validate()) {
                                      return;
                                    }
                                    await _saveTrackingDetails({
                                      'insurance_company': _model
                                          .tXTSeguradoraTextController.text,
                                    });
                                    await widget.onConfirmStep
                                        ?.call(widget.idTracking!);
                                    Navigator.pop(context);
                                  },
                                  text: 'Cadastrar',
                                  options: FFButtonOptions(
                                    height: 48.0,
                                    padding: EdgeInsetsDirectional.fromSTEB(
                                        48.0, 0.0, 48.0, 0.0),
                                    iconPadding: EdgeInsetsDirectional.fromSTEB(
                                        0.0, 0.0, 0.0, 0.0),
                                    color: FlutterFlowTheme.of(context).primary,
                                    textStyle: FlutterFlowTheme.of(context)
                                        .titleSmall
                                        .override(
                                          font: GoogleFonts.inter(
                                            fontWeight:
                                                FlutterFlowTheme.of(context)
                                                    .titleSmall
                                                    .fontWeight,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .titleSmall
                                                    .fontStyle,
                                          ),
                                          color: FlutterFlowTheme.of(context)
                                              .primaryText,
                                          fontSize: 14.0,
                                          letterSpacing: 0.0,
                                          fontWeight:
                                              FlutterFlowTheme.of(context)
                                                  .titleSmall
                                                  .fontWeight,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .titleSmall
                                                  .fontStyle,
                                        ),
                                    elevation: 0.0,
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                ),
                              ),
                            ),
                          ].divide(SizedBox(height: 20.0)),
                        ),
                      ),
                    );
                  } else if (widget!.order == 4) {
                    return Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Pagamento da Reserva (10.000 U\$)', style: FlutterFlowTheme.of(context).titleMedium.override(font: GoogleFonts.inter(), color: Colors.white, fontSize: 16.0, letterSpacing: 0.0)),
                          SizedBox(height: 16.0),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Reserva Paga?', style: FlutterFlowTheme.of(context).bodyMedium.override(font: GoogleFonts.inter(), color: Colors.white, letterSpacing: 0.0)),
                              SizedBox(height: 8.0),
                              Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => safeSetState(() => _model.reservationPaid = true),
                                      child: Container(
                                        height: 44.0,
                                        decoration: BoxDecoration(
                                          color: _model.reservationPaid ? Color(0xFF2D6A4F) : Color(0xFF404040),
                                          borderRadius: BorderRadius.only(topLeft: Radius.circular(8.0), bottomLeft: Radius.circular(8.0)),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text('Sim', style: FlutterFlowTheme.of(context).bodyMedium.override(font: GoogleFonts.inter(), color: _model.reservationPaid ? Color(0xFF95D5B2) : Colors.white70, letterSpacing: 0.0, fontWeight: FontWeight.w600)),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 2.0),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => safeSetState(() => _model.reservationPaid = false),
                                      child: Container(
                                        height: 44.0,
                                        decoration: BoxDecoration(
                                          color: !_model.reservationPaid ? Color(0xFF6B1C1C) : Color(0xFF404040),
                                          borderRadius: BorderRadius.only(topRight: Radius.circular(8.0), bottomRight: Radius.circular(8.0)),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text('Não', style: FlutterFlowTheme.of(context).bodyMedium.override(font: GoogleFonts.inter(), color: !_model.reservationPaid ? Color(0xFFFF5963) : Colors.white70, letterSpacing: 0.0, fontWeight: FontWeight.w600)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(height: 24.0),
                          Align(
                            alignment: AlignmentDirectional(1.0, 0.0),
                            child: FFButtonWidget(
                              onPressed: () async {
                                await _saveTrackingDetails({'reservation_paid': _model.reservationPaid});
                                if (widget.idTracking != null) await widget.onConfirmStep?.call(widget.idTracking!);
                                Navigator.pop(context);
                              },
                              text: 'Confirmar',
                              options: FFButtonOptions(height: 48.0, padding: EdgeInsetsDirectional.fromSTEB(48.0, 0.0, 48.0, 0.0), color: FlutterFlowTheme.of(context).primary, textStyle: FlutterFlowTheme.of(context).titleSmall.override(font: GoogleFonts.inter(), color: FlutterFlowTheme.of(context).primaryText, fontSize: 14.0, letterSpacing: 0.0), elevation: 0.0, borderRadius: BorderRadius.circular(8.0)),
                            ),
                          ),
                        ],
                      ),
                    );
                  } else if (widget!.order == 5) {
                    return Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Pagamento dos 5%', style: FlutterFlowTheme.of(context).titleMedium.override(font: GoogleFonts.inter(), color: Colors.white, fontSize: 16.0, letterSpacing: 0.0)),
                          SizedBox(height: 16.0),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('5% Pago?', style: FlutterFlowTheme.of(context).bodyMedium.override(font: GoogleFonts.inter(), color: Colors.white, letterSpacing: 0.0)),
                              SizedBox(height: 8.0),
                              Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => safeSetState(() => _model.fivePercentPaid = true),
                                      child: Container(
                                        height: 44.0,
                                        decoration: BoxDecoration(
                                          color: _model.fivePercentPaid ? Color(0xFF2D6A4F) : Color(0xFF404040),
                                          borderRadius: BorderRadius.only(topLeft: Radius.circular(8.0), bottomLeft: Radius.circular(8.0)),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text('Sim', style: FlutterFlowTheme.of(context).bodyMedium.override(font: GoogleFonts.inter(), color: _model.fivePercentPaid ? Color(0xFF95D5B2) : Colors.white70, letterSpacing: 0.0, fontWeight: FontWeight.w600)),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 2.0),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => safeSetState(() => _model.fivePercentPaid = false),
                                      child: Container(
                                        height: 44.0,
                                        decoration: BoxDecoration(
                                          color: !_model.fivePercentPaid ? Color(0xFF6B1C1C) : Color(0xFF404040),
                                          borderRadius: BorderRadius.only(topRight: Radius.circular(8.0), bottomRight: Radius.circular(8.0)),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text('Não', style: FlutterFlowTheme.of(context).bodyMedium.override(font: GoogleFonts.inter(), color: !_model.fivePercentPaid ? Color(0xFFFF5963) : Colors.white70, letterSpacing: 0.0, fontWeight: FontWeight.w600)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(height: 24.0),
                          Align(
                            alignment: AlignmentDirectional(1.0, 0.0),
                            child: FFButtonWidget(
                              onPressed: () async {
                                await _saveTrackingDetails({'five_percent_paid': _model.fivePercentPaid});
                                if (widget.idTracking != null) await widget.onConfirmStep?.call(widget.idTracking!);
                                Navigator.pop(context);
                              },
                              text: 'Confirmar',
                              options: FFButtonOptions(height: 48.0, padding: EdgeInsetsDirectional.fromSTEB(48.0, 0.0, 48.0, 0.0), color: FlutterFlowTheme.of(context).primary, textStyle: FlutterFlowTheme.of(context).titleSmall.override(font: GoogleFonts.inter(), color: FlutterFlowTheme.of(context).primaryText, fontSize: 14.0, letterSpacing: 0.0), elevation: 0.0, borderRadius: BorderRadius.circular(8.0)),
                            ),
                          ),
                        ],
                      ),
                    );
                  } else if (widget!.order == 10) {
                    return Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Aprovação de Crédito', style: FlutterFlowTheme.of(context).titleMedium.override(font: GoogleFonts.inter(), color: Colors.white, fontSize: 16.0, letterSpacing: 0.0)),
                          SizedBox(height: 16.0),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Financiamento Aprovado?', style: FlutterFlowTheme.of(context).bodyMedium.override(font: GoogleFonts.inter(), color: Colors.white, letterSpacing: 0.0)),
                              SizedBox(height: 8.0),
                              Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => safeSetState(() => _model.financingApproved = true),
                                      child: Container(
                                        height: 44.0,
                                        decoration: BoxDecoration(
                                          color: _model.financingApproved ? Color(0xFF2D6A4F) : Color(0xFF404040),
                                          borderRadius: BorderRadius.only(topLeft: Radius.circular(8.0), bottomLeft: Radius.circular(8.0)),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text('Sim', style: FlutterFlowTheme.of(context).bodyMedium.override(font: GoogleFonts.inter(), color: _model.financingApproved ? Color(0xFF95D5B2) : Colors.white70, letterSpacing: 0.0, fontWeight: FontWeight.w600)),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 2.0),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => safeSetState(() => _model.financingApproved = false),
                                      child: Container(
                                        height: 44.0,
                                        decoration: BoxDecoration(
                                          color: !_model.financingApproved ? Color(0xFF6B1C1C) : Color(0xFF404040),
                                          borderRadius: BorderRadius.only(topRight: Radius.circular(8.0), bottomRight: Radius.circular(8.0)),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text('Não', style: FlutterFlowTheme.of(context).bodyMedium.override(font: GoogleFonts.inter(), color: !_model.financingApproved ? Color(0xFFFF5963) : Colors.white70, letterSpacing: 0.0, fontWeight: FontWeight.w600)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(height: 24.0),
                          Align(
                            alignment: AlignmentDirectional(1.0, 0.0),
                            child: FFButtonWidget(
                              onPressed: () async {
                                await _saveTrackingDetails({'financing_approved': _model.financingApproved});
                                if (widget.idTracking != null) await widget.onConfirmStep?.call(widget.idTracking!);
                                Navigator.pop(context);
                              },
                              text: 'Confirmar',
                              options: FFButtonOptions(height: 48.0, padding: EdgeInsetsDirectional.fromSTEB(48.0, 0.0, 48.0, 0.0), color: FlutterFlowTheme.of(context).primary, textStyle: FlutterFlowTheme.of(context).titleSmall.override(font: GoogleFonts.inter(), color: FlutterFlowTheme.of(context).primaryText, fontSize: 14.0, letterSpacing: 0.0), elevation: 0.0, borderRadius: BorderRadius.circular(8.0)),
                            ),
                          ),
                        ],
                      ),
                    );
                  } else if (widget!.order == 11) {
                    return Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Assinatura do Pré-contrato', style: FlutterFlowTheme.of(context).titleMedium.override(font: GoogleFonts.inter(), color: Colors.white, fontSize: 16.0, letterSpacing: 0.0)),
                          SizedBox(height: 16.0),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Pré-contrato Assinado?', style: FlutterFlowTheme.of(context).bodyMedium.override(font: GoogleFonts.inter(), color: Colors.white, letterSpacing: 0.0)),
                              SizedBox(height: 8.0),
                              Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => safeSetState(() => _model.preContractSigned = true),
                                      child: Container(
                                        height: 44.0,
                                        decoration: BoxDecoration(
                                          color: _model.preContractSigned ? Color(0xFF2D6A4F) : Color(0xFF404040),
                                          borderRadius: BorderRadius.only(topLeft: Radius.circular(8.0), bottomLeft: Radius.circular(8.0)),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text('Sim', style: FlutterFlowTheme.of(context).bodyMedium.override(font: GoogleFonts.inter(), color: _model.preContractSigned ? Color(0xFF95D5B2) : Colors.white70, letterSpacing: 0.0, fontWeight: FontWeight.w600)),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 2.0),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => safeSetState(() => _model.preContractSigned = false),
                                      child: Container(
                                        height: 44.0,
                                        decoration: BoxDecoration(
                                          color: !_model.preContractSigned ? Color(0xFF6B1C1C) : Color(0xFF404040),
                                          borderRadius: BorderRadius.only(topRight: Radius.circular(8.0), bottomRight: Radius.circular(8.0)),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text('Não', style: FlutterFlowTheme.of(context).bodyMedium.override(font: GoogleFonts.inter(), color: !_model.preContractSigned ? Color(0xFFFF5963) : Colors.white70, letterSpacing: 0.0, fontWeight: FontWeight.w600)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(height: 24.0),
                          Align(
                            alignment: AlignmentDirectional(1.0, 0.0),
                            child: FFButtonWidget(
                              onPressed: () async {
                                await _saveTrackingDetails({'pre_contract_signed': _model.preContractSigned});
                                if (widget.idTracking != null) await widget.onConfirmStep?.call(widget.idTracking!);
                                Navigator.pop(context);
                              },
                              text: 'Confirmar',
                              options: FFButtonOptions(height: 48.0, padding: EdgeInsetsDirectional.fromSTEB(48.0, 0.0, 48.0, 0.0), color: FlutterFlowTheme.of(context).primary, textStyle: FlutterFlowTheme.of(context).titleSmall.override(font: GoogleFonts.inter(), color: FlutterFlowTheme.of(context).primaryText, fontSize: 14.0, letterSpacing: 0.0), elevation: 0.0, borderRadius: BorderRadius.circular(8.0)),
                            ),
                          ),
                        ],
                      ),
                    );
                  } else if (widget!.order == 13) {
                    return Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Apólice de Seguro (CASCO, LUC, RETA)', style: FlutterFlowTheme.of(context).titleMedium.override(font: GoogleFonts.inter(), color: Colors.white, fontSize: 16.0, letterSpacing: 0.0)),
                          SizedBox(height: 16.0),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Apólice Enviada?', style: FlutterFlowTheme.of(context).bodyMedium.override(font: GoogleFonts.inter(), color: Colors.white, letterSpacing: 0.0)),
                              SizedBox(height: 8.0),
                              Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => safeSetState(() => _model.insurancePolicySent = true),
                                      child: Container(
                                        height: 44.0,
                                        decoration: BoxDecoration(
                                          color: _model.insurancePolicySent ? Color(0xFF2D6A4F) : Color(0xFF404040),
                                          borderRadius: BorderRadius.only(topLeft: Radius.circular(8.0), bottomLeft: Radius.circular(8.0)),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text('Sim', style: FlutterFlowTheme.of(context).bodyMedium.override(font: GoogleFonts.inter(), color: _model.insurancePolicySent ? Color(0xFF95D5B2) : Colors.white70, letterSpacing: 0.0, fontWeight: FontWeight.w600)),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 2.0),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => safeSetState(() => _model.insurancePolicySent = false),
                                      child: Container(
                                        height: 44.0,
                                        decoration: BoxDecoration(
                                          color: !_model.insurancePolicySent ? Color(0xFF6B1C1C) : Color(0xFF404040),
                                          borderRadius: BorderRadius.only(topRight: Radius.circular(8.0), bottomRight: Radius.circular(8.0)),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text('Não', style: FlutterFlowTheme.of(context).bodyMedium.override(font: GoogleFonts.inter(), color: !_model.insurancePolicySent ? Color(0xFFFF5963) : Colors.white70, letterSpacing: 0.0, fontWeight: FontWeight.w600)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(height: 24.0),
                          Align(
                            alignment: AlignmentDirectional(1.0, 0.0),
                            child: FFButtonWidget(
                              onPressed: () async {
                                await _saveTrackingDetails({'insurance_policy_sent': _model.insurancePolicySent});
                                if (widget.idTracking != null) await widget.onConfirmStep?.call(widget.idTracking!);
                                Navigator.pop(context);
                              },
                              text: 'Confirmar',
                              options: FFButtonOptions(height: 48.0, padding: EdgeInsetsDirectional.fromSTEB(48.0, 0.0, 48.0, 0.0), color: FlutterFlowTheme.of(context).primary, textStyle: FlutterFlowTheme.of(context).titleSmall.override(font: GoogleFonts.inter(), color: FlutterFlowTheme.of(context).primaryText, fontSize: 14.0, letterSpacing: 0.0), elevation: 0.0, borderRadius: BorderRadius.circular(8.0)),
                            ),
                          ),
                        ],
                      ),
                    );
                  } else if (widget!.order == 14) {
                    return Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Pagamento Saldo de Entrada', style: FlutterFlowTheme.of(context).titleMedium.override(font: GoogleFonts.inter(), color: Colors.white, fontSize: 16.0, letterSpacing: 0.0)),
                          SizedBox(height: 16.0),
                          if (_model.entryPaymentInfo == 'confirmed') ...[
                            Row(
                              children: [
                                Icon(Icons.check_circle, color: Color(0xFF2D6A4F), size: 32.0),
                                SizedBox(width: 12.0),
                                Text('Pagamento confirmado', style: FlutterFlowTheme.of(context).bodyMedium.override(font: GoogleFonts.inter(), color: Color(0xFF95D5B2), fontSize: 16.0, letterSpacing: 0.0, fontWeight: FontWeight.w600)),
                              ],
                            ),
                            SizedBox(height: 8.0),
                          ],
                          Text('Confirme que o pagamento do saldo de entrada foi realizado.', style: FlutterFlowTheme.of(context).bodyMedium.override(font: GoogleFonts.inter(), color: Color(0x74FFFFFF), fontSize: 14.0, letterSpacing: 0.0)),
                          SizedBox(height: 24.0),
                          Align(
                            alignment: AlignmentDirectional(1.0, 0.0),
                            child: FFButtonWidget(
                              onPressed: () async {
                                await _saveTrackingDetails({'entry_payment_info': 'confirmed'});
                                if (widget.idTracking != null) await widget.onConfirmStep?.call(widget.idTracking!);
                                Navigator.pop(context);
                              },
                              text: _model.entryPaymentInfo == 'confirmed' ? 'Confirmado' : 'Confirmar Pagamento',
                              options: FFButtonOptions(height: 48.0, padding: EdgeInsetsDirectional.fromSTEB(48.0, 0.0, 48.0, 0.0), color: FlutterFlowTheme.of(context).primary, textStyle: FlutterFlowTheme.of(context).titleSmall.override(font: GoogleFonts.inter(), color: FlutterFlowTheme.of(context).primaryText, fontSize: 14.0, letterSpacing: 0.0), elevation: 0.0, borderRadius: BorderRadius.circular(8.0)),
                            ),
                          ),
                        ],
                      ),
                    );
                  } else if (widget!.order == 16) {
                    return Padding(
                      padding: EdgeInsets.all(24.0),
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Documentação para Oficina', style: FlutterFlowTheme.of(context).titleMedium.override(font: GoogleFonts.inter(), color: Colors.white, fontSize: 16.0, letterSpacing: 0.0)),
                            SizedBox(height: 16.0),
                            ..._buildDocChecklist(context, [
                              _DocItem('Invoice', _model.oficInvoice, () => safeSetState(() => _model.oficInvoice = true), () => safeSetState(() => _model.oficInvoice = false)),
                              _DocItem('Export Certificate', _model.oficExportCertificate, () => safeSetState(() => _model.oficExportCertificate = true), () => safeSetState(() => _model.oficExportCertificate = false)),
                              _DocItem('Bill of Sale', _model.oficBillOfSale, () => safeSetState(() => _model.oficBillOfSale = true), () => safeSetState(() => _model.oficBillOfSale = false)),
                              _DocItem('TECAT', _model.oficTecat, () => safeSetState(() => _model.oficTecat = true), () => safeSetState(() => _model.oficTecat = false)),
                              _DocItem('AADsAC', _model.oficAadsac, () => safeSetState(() => _model.oficAadsac = true), () => safeSetState(() => _model.oficAadsac = false)),
                              _DocItem('GENDEC', _model.oficGendec, () => safeSetState(() => _model.oficGendec = true), () => safeSetState(() => _model.oficGendec = false)),
                              _DocItem('Special Airworthness Certificate', _model.oficSpecialAirworthness, () => safeSetState(() => _model.oficSpecialAirworthness = true), () => safeSetState(() => _model.oficSpecialAirworthness = false)),
                              _DocItem('Seguro RETA - Endossado Brasil', _model.oficSeguroReta, () => safeSetState(() => _model.oficSeguroReta = true), () => safeSetState(() => _model.oficSeguroReta = false)),
                              _DocItem('Boleto do Seguro RETA', _model.oficBoletoReta, () => safeSetState(() => _model.oficBoletoReta = true), () => safeSetState(() => _model.oficBoletoReta = false)),
                              _DocItem('Comprovante Pgto Seguro RETA', _model.oficComprovanteReta, () => safeSetState(() => _model.oficComprovanteReta = true), () => safeSetState(() => _model.oficComprovanteReta = false)),
                              _DocItem('Todos docs do Despachante', _model.oficDocsDespachante, () => safeSetState(() => _model.oficDocsDespachante = true), () => safeSetState(() => _model.oficDocsDespachante = false)),
                              _DocItem('Cópia de Cadernetas', _model.oficCopiaCadernetas, () => safeSetState(() => _model.oficCopiaCadernetas = true), () => safeSetState(() => _model.oficCopiaCadernetas = false)),
                              _DocItem('Peso e Balanceamento', _model.oficPesoBalanceamento, () => safeSetState(() => _model.oficPesoBalanceamento = true), () => safeSetState(() => _model.oficPesoBalanceamento = false)),
                              _DocItem('Desregistro', _model.oficDesregistro, () => safeSetState(() => _model.oficDesregistro = true), () => safeSetState(() => _model.oficDesregistro = false)),
                              _DocItem('Flight Test', _model.oficFlightTest, () => safeSetState(() => _model.oficFlightTest = true), () => safeSetState(() => _model.oficFlightTest = false)),
                              _DocItem('Form 337', _model.oficForm337, () => safeSetState(() => _model.oficForm337 = true), () => safeSetState(() => _model.oficForm337 = false)),
                              _DocItem('Lista de Componentes', _model.oficListaComponentes, () => safeSetState(() => _model.oficListaComponentes = true), () => safeSetState(() => _model.oficListaComponentes = false)),
                              _DocItem('Lista de ADs', _model.oficListaAds, () => safeSetState(() => _model.oficListaAds = true), () => safeSetState(() => _model.oficListaAds = false)),
                            ]),
                            SizedBox(height: 24.0),
                            Align(
                              alignment: AlignmentDirectional(1.0, 0.0),
                              child: FFButtonWidget(
                                onPressed: () async {
                                  final oficData = {
                                    'ofic_invoice': _model.oficInvoice, 'ofic_export_certificate': _model.oficExportCertificate,
                                    'ofic_bill_of_sale': _model.oficBillOfSale, 'ofic_tecat': _model.oficTecat,
                                    'ofic_aadsac': _model.oficAadsac, 'ofic_gendec': _model.oficGendec,
                                    'ofic_special_airworthness': _model.oficSpecialAirworthness, 'ofic_seguro_reta': _model.oficSeguroReta,
                                    'ofic_boleto_reta': _model.oficBoletoReta, 'ofic_comprovante_reta': _model.oficComprovanteReta,
                                    'ofic_docs_despachante': _model.oficDocsDespachante, 'ofic_copia_cadernetas': _model.oficCopiaCadernetas,
                                    'ofic_peso_balanceamento': _model.oficPesoBalanceamento, 'ofic_desregistro': _model.oficDesregistro,
                                    'ofic_flight_test': _model.oficFlightTest, 'ofic_form_337': _model.oficForm337,
                                    'ofic_lista_componentes': _model.oficListaComponentes, 'ofic_lista_ads': _model.oficListaAds,
                                  };
                                  await _saveTrackingDetails(oficData);
                                  final allOficChecked = _model.oficInvoice && _model.oficExportCertificate && _model.oficBillOfSale && _model.oficTecat && _model.oficAadsac && _model.oficGendec && _model.oficSpecialAirworthness && _model.oficSeguroReta && _model.oficBoletoReta && _model.oficComprovanteReta && _model.oficDocsDespachante && _model.oficCopiaCadernetas && _model.oficPesoBalanceamento && _model.oficDesregistro && _model.oficFlightTest && _model.oficForm337 && _model.oficListaComponentes && _model.oficListaAds;
                                  if (allOficChecked) {
                                    if (widget.idTracking != null) await widget.onConfirmStep?.call(widget.idTracking!);
                                  }
                                  Navigator.pop(context);
                                },
                                text: 'Confirmar',
                                options: FFButtonOptions(height: 48.0, padding: EdgeInsetsDirectional.fromSTEB(48.0, 0.0, 48.0, 0.0), color: FlutterFlowTheme.of(context).primary, textStyle: FlutterFlowTheme.of(context).titleSmall.override(font: GoogleFonts.inter(), color: FlutterFlowTheme.of(context).primaryText, fontSize: 14.0, letterSpacing: 0.0), elevation: 0.0, borderRadius: BorderRadius.circular(8.0)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  } else if (widget!.order == 17) {
                    return Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Assinatura do Contrato Final', style: FlutterFlowTheme.of(context).titleMedium.override(font: GoogleFonts.inter(), color: Colors.white, fontSize: 16.0, letterSpacing: 0.0)),
                          SizedBox(height: 16.0),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Contrato Final Assinado?', style: FlutterFlowTheme.of(context).bodyMedium.override(font: GoogleFonts.inter(), color: Colors.white, letterSpacing: 0.0)),
                              SizedBox(height: 8.0),
                              Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => safeSetState(() => _model.finalContractSigned = true),
                                      child: Container(
                                        height: 44.0,
                                        decoration: BoxDecoration(
                                          color: _model.finalContractSigned ? Color(0xFF2D6A4F) : Color(0xFF404040),
                                          borderRadius: BorderRadius.only(topLeft: Radius.circular(8.0), bottomLeft: Radius.circular(8.0)),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text('Sim', style: FlutterFlowTheme.of(context).bodyMedium.override(font: GoogleFonts.inter(), color: _model.finalContractSigned ? Color(0xFF95D5B2) : Colors.white70, letterSpacing: 0.0, fontWeight: FontWeight.w600)),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 2.0),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => safeSetState(() => _model.finalContractSigned = false),
                                      child: Container(
                                        height: 44.0,
                                        decoration: BoxDecoration(
                                          color: !_model.finalContractSigned ? Color(0xFF6B1C1C) : Color(0xFF404040),
                                          borderRadius: BorderRadius.only(topRight: Radius.circular(8.0), bottomRight: Radius.circular(8.0)),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text('Não', style: FlutterFlowTheme.of(context).bodyMedium.override(font: GoogleFonts.inter(), color: !_model.finalContractSigned ? Color(0xFFFF5963) : Colors.white70, letterSpacing: 0.0, fontWeight: FontWeight.w600)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(height: 24.0),
                          Align(
                            alignment: AlignmentDirectional(1.0, 0.0),
                            child: FFButtonWidget(
                              onPressed: () async {
                                await _saveTrackingDetails({'final_contract_signed': _model.finalContractSigned});
                                if (widget.idTracking != null) await widget.onConfirmStep?.call(widget.idTracking!);
                                Navigator.pop(context);
                              },
                              text: 'Confirmar',
                              options: FFButtonOptions(height: 48.0, padding: EdgeInsetsDirectional.fromSTEB(48.0, 0.0, 48.0, 0.0), color: FlutterFlowTheme.of(context).primary, textStyle: FlutterFlowTheme.of(context).titleSmall.override(font: GoogleFonts.inter(), color: FlutterFlowTheme.of(context).primaryText, fontSize: 14.0, letterSpacing: 0.0), elevation: 0.0, borderRadius: BorderRadius.circular(8.0)),
                            ),
                          ),
                        ],
                      ),
                    );
                  } else if (widget!.order == 18) {
                    return Padding(
                      padding: EdgeInsets.all(24.0),
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Documentação do Despachante', style: FlutterFlowTheme.of(context).titleMedium.override(font: GoogleFonts.inter(), color: Colors.white, fontSize: 16.0, letterSpacing: 0.0)),
                            SizedBox(height: 16.0),
                            ..._buildDocChecklist(context, [
                              _DocItem('CND (Certidão Negativa de Débito)', _model.despCnd, () => safeSetState(() => _model.despCnd = true), () => safeSetState(() => _model.despCnd = false)),
                              _DocItem('Invoice', _model.despInvoice, () => safeSetState(() => _model.despInvoice = true), () => safeSetState(() => _model.despInvoice = false)),
                              _DocItem('Export Certificate', _model.despExportCertificate, () => safeSetState(() => _model.despExportCertificate = true), () => safeSetState(() => _model.despExportCertificate = false)),
                              _DocItem('Bill of Sale', _model.despBillOfSale, () => safeSetState(() => _model.despBillOfSale = true), () => safeSetState(() => _model.despBillOfSale = false)),
                              _DocItem('TECAT', _model.despTecat, () => safeSetState(() => _model.despTecat = true), () => safeSetState(() => _model.despTecat = false)),
                              _DocItem('AVANAC', _model.despAvanac, () => safeSetState(() => _model.despAvanac = true), () => safeSetState(() => _model.despAvanac = false)),
                              _DocItem('GENDEC', _model.despGendec, () => safeSetState(() => _model.despGendec = true), () => safeSetState(() => _model.despGendec = false)),
                              _DocItem('Special Airworthness Certificate', _model.despSpecialAirworthness, () => safeSetState(() => _model.despSpecialAirworthness = true), () => safeSetState(() => _model.despSpecialAirworthness = false)),
                              _DocItem('Seguro RETA - Endossado Brasil', _model.despSeguroReta, () => safeSetState(() => _model.despSeguroReta = true), () => safeSetState(() => _model.despSeguroReta = false)),
                              _DocItem('Boleto do Seguro RETA', _model.despBoletoReta, () => safeSetState(() => _model.despBoletoReta = true), () => safeSetState(() => _model.despBoletoReta = false)),
                              _DocItem('Comprovante Pgto Seguro RETA', _model.despComprovanteReta, () => safeSetState(() => _model.despComprovanteReta = true), () => safeSetState(() => _model.despComprovanteReta = false)),
                            ]),
                            SizedBox(height: 24.0),
                            Align(
                              alignment: AlignmentDirectional(1.0, 0.0),
                              child: FFButtonWidget(
                                onPressed: () async {
                                  final despData = {
                                    'desp_cnd': _model.despCnd,
                                    'desp_invoice': _model.despInvoice, 'desp_export_certificate': _model.despExportCertificate,
                                    'desp_bill_of_sale': _model.despBillOfSale, 'desp_tecat': _model.despTecat,
                                    'desp_avanac': _model.despAvanac, 'desp_gendec': _model.despGendec,
                                    'desp_special_airworthness': _model.despSpecialAirworthness, 'desp_seguro_reta': _model.despSeguroReta,
                                    'desp_boleto_reta': _model.despBoletoReta, 'desp_comprovante_reta': _model.despComprovanteReta,
                                  };
                                  await _saveTrackingDetails(despData);
                                  final allDespChecked = _model.despCnd && _model.despInvoice && _model.despExportCertificate && _model.despBillOfSale && _model.despTecat && _model.despAvanac && _model.despGendec && _model.despSpecialAirworthness && _model.despSeguroReta && _model.despBoletoReta && _model.despComprovanteReta;
                                  if (allDespChecked && widget.idTracking != null) {
                                    await widget.onConfirmStep?.call(widget.idTracking!);
                                  }
                                  Navigator.pop(context);
                                },
                                text: 'Confirmar',
                                options: FFButtonOptions(height: 48.0, padding: EdgeInsetsDirectional.fromSTEB(48.0, 0.0, 48.0, 0.0), color: FlutterFlowTheme.of(context).primary, textStyle: FlutterFlowTheme.of(context).titleSmall.override(font: GoogleFonts.inter(), color: FlutterFlowTheme.of(context).primaryText, fontSize: 14.0, letterSpacing: 0.0), elevation: 0.0, borderRadius: BorderRadius.circular(8.0)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  } else if (widget!.order == 19) {
                    return Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Desembaraço Aduaneiro', style: FlutterFlowTheme.of(context).titleMedium.override(font: GoogleFonts.inter(), color: Colors.white, fontSize: 16.0, letterSpacing: 0.0)),
                          SizedBox(height: 16.0),
                          Text('Status:', style: FlutterFlowTheme.of(context).bodyMedium.override(font: GoogleFonts.inter(), color: Color(0x73FFFFFF), letterSpacing: 0.0)),
                          SizedBox(height: 8.0),
                          Wrap(
                            spacing: 8.0, runSpacing: 8.0,
                            children: ['Canal Verde', 'Canal Amarelo', 'Canal Vermelho', 'Liberado'].map((status) {
                              final isSelected = _model.customsStatus == status;
                              final statusColor = status == 'Canal Verde' ? Color(0xFF2D6A4F) : status == 'Canal Amarelo' ? Color(0xFFB8860B) : status == 'Canal Vermelho' ? Color(0xFFFF5963) : Color(0xFF1E88E5);
                              return GestureDetector(
                                onTap: () => safeSetState(() => _model.customsStatus = status),
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                                  decoration: BoxDecoration(
                                    color: isSelected ? statusColor : Color(0xFF404040),
                                    borderRadius: BorderRadius.circular(8.0),
                                    border: isSelected ? Border.all(color: Colors.white, width: 2.0) : null,
                                  ),
                                  child: Text(status, style: FlutterFlowTheme.of(context).bodyMedium.override(font: GoogleFonts.inter(), color: Colors.white, letterSpacing: 0.0, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
                                ),
                              );
                            }).toList(),
                          ),
                          SizedBox(height: 16.0),
                          GestureDetector(
                            onTap: () => safeSetState(() => _model.customsCnd = !_model.customsCnd),
                            child: Row(
                              children: [
                                Container(
                                  width: 24.0, height: 24.0,
                                  decoration: BoxDecoration(
                                    color: _model.customsCnd ? FlutterFlowTheme.of(context).primary : Colors.transparent,
                                    borderRadius: BorderRadius.circular(4.0),
                                    border: Border.all(color: _model.customsCnd ? FlutterFlowTheme.of(context).primary : Color(0x73FFFFFF), width: 2.0),
                                  ),
                                  child: _model.customsCnd ? Icon(Icons.check, size: 16.0, color: Colors.white) : null,
                                ),
                                SizedBox(width: 12.0),
                                Text('CND (Certidão Negativa de Débito)', style: FlutterFlowTheme.of(context).bodyMedium.override(font: GoogleFonts.inter(), color: Colors.white, letterSpacing: 0.0)),
                              ],
                            ),
                          ),
                          SizedBox(height: 24.0),
                          Align(
                            alignment: AlignmentDirectional(1.0, 0.0),
                            child: FFButtonWidget(
                              onPressed: () async {
                                await _saveTrackingDetails({'customs_status': _model.customsStatus, 'customs_cnd': _model.customsCnd});
                                if (widget.idTracking != null) await widget.onConfirmStep?.call(widget.idTracking!);
                                Navigator.pop(context);
                              },
                              text: 'Confirmar',
                              options: FFButtonOptions(height: 48.0, padding: EdgeInsetsDirectional.fromSTEB(48.0, 0.0, 48.0, 0.0), color: FlutterFlowTheme.of(context).primary, textStyle: FlutterFlowTheme.of(context).titleSmall.override(font: GoogleFonts.inter(), color: FlutterFlowTheme.of(context).primaryText, fontSize: 14.0, letterSpacing: 0.0), elevation: 0.0, borderRadius: BorderRadius.circular(8.0)),
                            ),
                          ),
                        ],
                      ),
                    );
                  } else if (widget!.order == 20) {
                    return Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Liberação para Voo', style: FlutterFlowTheme.of(context).titleMedium.override(font: GoogleFonts.inter(), color: Colors.white, fontSize: 16.0, letterSpacing: 0.0)),
                          SizedBox(height: 16.0),
                          // Upload CA
                          Text('Certificado de Aeronavegabilidade (CA)', style: FlutterFlowTheme.of(context).bodyMedium.override(font: GoogleFonts.inter(), color: Color(0x73FFFFFF), letterSpacing: 0.0)),
                          SizedBox(height: 8.0),
                          if (_model.uploadedFileUrl_caDoc.isEmpty)
                            FFButtonWidget(
                              onPressed: () async {
                                final selectedFiles = await selectFiles(storageFolderPath: '', multiFile: false);
                                if (selectedFiles != null) {
                                  safeSetState(() => _model.isDataUploading_caDoc = true);
                                  var selectedUploadedFiles = <FFUploadedFile>[];
                                  var downloadUrls = <String>[];
                                  try {
                                    selectedUploadedFiles = selectedFiles.map((m) => FFUploadedFile(name: m.storagePath.split('/').last, bytes: m.bytes, originalFilename: m.originalFilename)).toList();
                                    downloadUrls = await uploadSupabaseStorageFiles(bucketName: 'AGSur', selectedFiles: selectedFiles);
                                  } finally {
                                    _model.isDataUploading_caDoc = false;
                                  }
                                  if (selectedUploadedFiles.length == selectedFiles.length && downloadUrls.length == selectedFiles.length) {
                                    safeSetState(() {
                                      _model.uploadedLocalFile_caDoc = selectedUploadedFiles.first;
                                      _model.uploadedFileUrl_caDoc = downloadUrls.first;
                                    });
                                  }
                                }
                              },
                              text: 'Selecionar arquivo',
                              icon: Icon(Icons.upload_file, size: 18.0),
                              options: FFButtonOptions(width: 220.0, height: 40.0, padding: EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0), color: FlutterFlowTheme.of(context).primary, textStyle: FlutterFlowTheme.of(context).titleSmall.override(font: GoogleFonts.inter(), color: FlutterFlowTheme.of(context).primaryText, fontSize: 14.0, letterSpacing: 0.0), elevation: 0.0, borderRadius: BorderRadius.circular(8.0)),
                            ),
                          if (_model.uploadedFileUrl_caDoc.isNotEmpty)
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(12.0),
                              decoration: BoxDecoration(color: Color(0xFF2D6A4F), borderRadius: BorderRadius.circular(8.0)),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Row(children: [
                                      Icon(Icons.check_circle, color: Color(0xFF95D5B2), size: 20.0),
                                      SizedBox(width: 8.0),
                                      Expanded(child: Text(_model.uploadedLocalFile_caDoc.originalFilename ?? 'Arquivo enviado', overflow: TextOverflow.ellipsis, style: FlutterFlowTheme.of(context).bodyMedium.override(font: GoogleFonts.inter(), color: Colors.white, fontSize: 13.0, letterSpacing: 0.0))),
                                    ]),
                                  ),
                                  InkWell(
                                    onTap: () => safeSetState(() {
                                      _model.uploadedFileUrl_caDoc = '';
                                      _model.uploadedLocalFile_caDoc = FFUploadedFile(bytes: Uint8List.fromList([]), originalFilename: '');
                                    }),
                                    child: Icon(Icons.delete_outline, color: Color(0xFFFF5963), size: 22.0),
                                  ),
                                ],
                              ),
                            ),
                          SizedBox(height: 20.0),
                          // Upload CM
                          Text('Certificado de Matrícula (CM)', style: FlutterFlowTheme.of(context).bodyMedium.override(font: GoogleFonts.inter(), color: Color(0x73FFFFFF), letterSpacing: 0.0)),
                          SizedBox(height: 8.0),
                          if (_model.uploadedFileUrl_cmDoc.isEmpty)
                            FFButtonWidget(
                              onPressed: () async {
                                final selectedFiles = await selectFiles(storageFolderPath: '', multiFile: false);
                                if (selectedFiles != null) {
                                  safeSetState(() => _model.isDataUploading_cmDoc = true);
                                  var selectedUploadedFiles = <FFUploadedFile>[];
                                  var downloadUrls = <String>[];
                                  try {
                                    selectedUploadedFiles = selectedFiles.map((m) => FFUploadedFile(name: m.storagePath.split('/').last, bytes: m.bytes, originalFilename: m.originalFilename)).toList();
                                    downloadUrls = await uploadSupabaseStorageFiles(bucketName: 'AGSur', selectedFiles: selectedFiles);
                                  } finally {
                                    _model.isDataUploading_cmDoc = false;
                                  }
                                  if (selectedUploadedFiles.length == selectedFiles.length && downloadUrls.length == selectedFiles.length) {
                                    safeSetState(() {
                                      _model.uploadedLocalFile_cmDoc = selectedUploadedFiles.first;
                                      _model.uploadedFileUrl_cmDoc = downloadUrls.first;
                                    });
                                  }
                                }
                              },
                              text: 'Selecionar arquivo',
                              icon: Icon(Icons.upload_file, size: 18.0),
                              options: FFButtonOptions(width: 220.0, height: 40.0, padding: EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0), color: FlutterFlowTheme.of(context).primary, textStyle: FlutterFlowTheme.of(context).titleSmall.override(font: GoogleFonts.inter(), color: FlutterFlowTheme.of(context).primaryText, fontSize: 14.0, letterSpacing: 0.0), elevation: 0.0, borderRadius: BorderRadius.circular(8.0)),
                            ),
                          if (_model.uploadedFileUrl_cmDoc.isNotEmpty)
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(12.0),
                              decoration: BoxDecoration(color: Color(0xFF2D6A4F), borderRadius: BorderRadius.circular(8.0)),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Row(children: [
                                      Icon(Icons.check_circle, color: Color(0xFF95D5B2), size: 20.0),
                                      SizedBox(width: 8.0),
                                      Expanded(child: Text(_model.uploadedLocalFile_cmDoc.originalFilename ?? 'Arquivo enviado', overflow: TextOverflow.ellipsis, style: FlutterFlowTheme.of(context).bodyMedium.override(font: GoogleFonts.inter(), color: Colors.white, fontSize: 13.0, letterSpacing: 0.0))),
                                    ]),
                                  ),
                                  InkWell(
                                    onTap: () => safeSetState(() {
                                      _model.uploadedFileUrl_cmDoc = '';
                                      _model.uploadedLocalFile_cmDoc = FFUploadedFile(bytes: Uint8List.fromList([]), originalFilename: '');
                                    }),
                                    child: Icon(Icons.delete_outline, color: Color(0xFFFF5963), size: 22.0),
                                  ),
                                ],
                              ),
                            ),
                          SizedBox(height: 24.0),
                          Align(
                            alignment: AlignmentDirectional(1.0, 0.0),
                            child: FFButtonWidget(
                              onPressed: () async {
                                final docData = {
                                  'ca_document_url': _model.uploadedFileUrl_caDoc.isNotEmpty ? _model.uploadedFileUrl_caDoc : null,
                                  'cm_document_url': _model.uploadedFileUrl_cmDoc.isNotEmpty ? _model.uploadedFileUrl_cmDoc : null,
                                };
                                await _saveTrackingDetails(docData);
                                if (widget.idTracking != null) await widget.onConfirmStep?.call(widget.idTracking!);
                                Navigator.pop(context);
                              },
                              text: 'Confirmar',
                              options: FFButtonOptions(height: 48.0, padding: EdgeInsetsDirectional.fromSTEB(48.0, 0.0, 48.0, 0.0), color: FlutterFlowTheme.of(context).primary, textStyle: FlutterFlowTheme.of(context).titleSmall.override(font: GoogleFonts.inter(), color: FlutterFlowTheme.of(context).primaryText, fontSize: 14.0, letterSpacing: 0.0), elevation: 0.0, borderRadius: BorderRadius.circular(8.0)),
                            ),
                          ),
                        ],
                      ),
                    );
                  } else {
                    return Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Color(0xFF2D6A4F),
                            size: 64.0,
                          ),
                          SizedBox(height: 16.0),
                          Text(
                            'Etapa confirmada',
                            style: FlutterFlowTheme.of(context).titleMedium.override(
                              font: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                              ),
                              color: Color(0xFF95D5B2),
                              fontSize: 18.0,
                              letterSpacing: 0.0,
                            ),
                          ),
                          SizedBox(height: 8.0),
                          Text(
                            'Esta etapa já foi concluída com sucesso.',
                            style: FlutterFlowTheme.of(context).bodyMedium.override(
                              font: GoogleFonts.inter(),
                              color: Color(0x74FFFFFF),
                              fontSize: 14.0,
                              letterSpacing: 0.0,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                },
              ),
              ),
            ].divide(SizedBox(height: 8.0)),
          ),
        ).animateOnPageLoad(animationsMap['containerOnPageLoadAnimation']!),
      ),
    );
  }

  Future<void> _saveTrackingDetails(Map<String, dynamic> data) async {
    try {
      if (_model.existingDetailsId != null) {
        await TrackingDetailsTable().update(
          data: data,
          matchingRows: (q) => q.eq('id', _model.existingDetailsId!),
        );
      } else {
        if (widget.idTracking == null) return;
        final inserted = await TrackingDetailsTable().insert({
          'tracking_id': widget!.idTracking,
          ...data,
        });
        _model.existingDetailsId = inserted.id;
      }
    } catch (e) {
      debugPrint('Erro ao salvar tracking details: $e');
    }
  }

  List<Widget> _buildDocChecklist(BuildContext context, List<_DocItem> items) {
    return items.map((item) => Padding(
      padding: EdgeInsets.only(bottom: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.label, style: FlutterFlowTheme.of(context).bodySmall.override(font: GoogleFonts.inter(), color: Colors.white, letterSpacing: 0.0)),
          SizedBox(height: 4.0),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: item.onTapYes,
                  child: Container(
                    height: 36.0,
                    decoration: BoxDecoration(
                      color: item.value ? Color(0xFF2D6A4F) : Color(0xFF404040),
                      borderRadius: BorderRadius.only(topLeft: Radius.circular(6.0), bottomLeft: Radius.circular(6.0)),
                    ),
                    alignment: Alignment.center,
                    child: Text('Sim', style: FlutterFlowTheme.of(context).bodySmall.override(font: GoogleFonts.inter(), color: item.value ? Color(0xFF95D5B2) : Colors.white70, letterSpacing: 0.0, fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
              SizedBox(width: 2.0),
              Expanded(
                child: GestureDetector(
                  onTap: item.onTapNo,
                  child: Container(
                    height: 36.0,
                    decoration: BoxDecoration(
                      color: !item.value ? Color(0xFF6B1C1C) : Color(0xFF404040),
                      borderRadius: BorderRadius.only(topRight: Radius.circular(6.0), bottomRight: Radius.circular(6.0)),
                    ),
                    alignment: Alignment.center,
                    child: Text('Não', style: FlutterFlowTheme.of(context).bodySmall.override(font: GoogleFonts.inter(), color: !item.value ? Color(0xFFFF5963) : Colors.white70, letterSpacing: 0.0, fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    )).toList();
  }
}

class _DocItem {
  final String label;
  final bool value;
  final VoidCallback onTapYes;
  final VoidCallback onTapNo;
  _DocItem(this.label, this.value, this.onTapYes, this.onTapNo);
}
