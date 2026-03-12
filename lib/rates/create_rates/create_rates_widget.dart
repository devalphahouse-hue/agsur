import '/auth/supabase_auth/auth_util.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import '/flutter_flow/custom_functions.dart' as functions;
import '/index.dart';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:provider/provider.dart';
import 'create_rates_model.dart';
export 'create_rates_model.dart';

class CreateRatesWidget extends StatefulWidget {
  const CreateRatesWidget({
    super.key,
    required this.idFinancialRate,
  });

  final String? idFinancialRate;

  static String routeName = 'CreateRates';
  static String routePath = '/createRates';

  @override
  State<CreateRatesWidget> createState() => _CreateRatesWidgetState();
}

class _CreateRatesWidgetState extends State<CreateRatesWidget> {
  late CreateRatesModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => CreateRatesModel());

    _model.tFPremiumRateFiveFocusNode ??= FocusNode();

    _model.tFPremiumRateFiveMask = MaskTextInputFormatter(mask: '##.###%');

    _model.tFPremiumRateSevenFocusNode ??= FocusNode();

    _model.tFPremiumRateSevenMask = MaskTextInputFormatter(mask: '##.###%');

    _model.tFSofrRateFocusNode ??= FocusNode();

    _model.tFSofrRateMask = MaskTextInputFormatter(mask: '##.###%');

    _model.tFInterestRateFocusNode ??= FocusNode();

    _model.tFInterestRateMask = MaskTextInputFormatter(mask: '##.###%');
    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: Color(0xFF313131),
        appBar: AppBar(
          backgroundColor: Color(0xFF313131),
          iconTheme: IconThemeData(color: FlutterFlowTheme.of(context).primary),
          automaticallyImplyLeading: true,
          title: Text(
            'Atualizar Taxas de Financiamento',
            textAlign: TextAlign.center,
            style: FlutterFlowTheme.of(context).headlineMedium.override(
                  font: GoogleFonts.inter(
                    fontWeight:
                        FlutterFlowTheme.of(context).headlineMedium.fontWeight,
                    fontStyle:
                        FlutterFlowTheme.of(context).headlineMedium.fontStyle,
                  ),
                  color: Color(0x73FFFFFF),
                  fontSize: 18.0,
                  letterSpacing: 0.0,
                  fontWeight:
                      FlutterFlowTheme.of(context).headlineMedium.fontWeight,
                  fontStyle:
                      FlutterFlowTheme.of(context).headlineMedium.fontStyle,
                ),
          ),
          actions: [
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
              child: InkWell(
                splashColor: Colors.transparent,
                focusColor: Colors.transparent,
                hoverColor: Colors.transparent,
                highlightColor: Colors.transparent,
                onTap: () async {
                  context.pushNamed(HomePageWidget.routeName);
                },
                child: Icon(
                  Icons.home,
                  color: FlutterFlowTheme.of(context).primary,
                  size: 24.0,
                ),
              ),
            ),
          ],
          centerTitle: true,
          elevation: 0.0,
        ),
        body: SafeArea(
          top: true,
          child: Padding(
            padding: EdgeInsetsDirectional.fromSTEB(0.0, 28.0, 0.0, 0.0),
            child: Container(
              width: MediaQuery.sizeOf(context).width * 1.0,
              decoration: BoxDecoration(),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Padding(
                      padding:
                          EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 16.0),
                      child: FutureBuilder<List<FinancingRatesRow>>(
                        future: FinancingRatesTable().querySingleRow(
                          queryFn: (q) => q.eqOrNull(
                            'id',
                            'ce659e4b-caee-4b88-8d99-46f15c7e9b69',
                          ),
                        ),
                        builder: (context, snapshot) {
                          // Customize what your widget looks like when it's loading.
                          if (!snapshot.hasData) {
                            return Center(
                              child: SizedBox(
                                width: 40.0,
                                height: 40.0,
                                child: SpinKitFoldingCube(
                                  color: Color(0xFFC2D51C),
                                  size: 40.0,
                                ),
                              ),
                            );
                          }
                          List<FinancingRatesRow>
                              cTCsrdAircraftFinancingRatesRowList =
                              snapshot.data!;

                          final cTCsrdAircraftFinancingRatesRow =
                              cTCsrdAircraftFinancingRatesRowList.isNotEmpty
                                  ? cTCsrdAircraftFinancingRatesRowList.first
                                  : null;

                          return Container(
                            width: MediaQuery.sizeOf(context).width * 1.0,
                            constraints: BoxConstraints(
                              maxWidth: 800.0,
                            ),
                            decoration: BoxDecoration(
                              color: Color(0xFF404040),
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(24.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Align(
                                    alignment: AlignmentDirectional(-1.0, 0.0),
                                    child: Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          12.0, 0.0, 12.0, 0.0),
                                      child: Text(
                                        'Taxas de Financiamento',
                                        style: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .override(
                                              font: GoogleFonts.roboto(
                                                fontWeight: FontWeight.w500,
                                                fontStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyMedium
                                                        .fontStyle,
                                              ),
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .secondaryBackground,
                                              fontSize: 18.0,
                                              letterSpacing: 0.0,
                                              fontWeight: FontWeight.w500,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyMedium
                                                      .fontStyle,
                                            ),
                                      ),
                                    ),
                                  ),
                                  Divider(
                                    thickness: 2.0,
                                    color: Color(0x74FFFFFF),
                                  ),
                                  Padding(
                                    padding: EdgeInsetsDirectional.fromSTEB(
                                        0.0, 12.0, 0.0, 0.0),
                                    child: TextFormField(
                                      controller: _model
                                              .tFPremiumRateFiveTextController ??=
                                          TextEditingController(
                                        text: valueOrDefault<String>(
                                          (double premiumFive) {
                                            return (premiumFive * 100)
                                                    .toStringAsFixed(2) +
                                                '%';
                                          }(cTCsrdAircraftFinancingRatesRow!
                                              .premiumRateFive),
                                          '0',
                                        ),
                                      ),
                                      focusNode:
                                          _model.tFPremiumRateFiveFocusNode,
                                      onChanged: (_) => EasyDebounce.debounce(
                                        '_model.tFPremiumRateFiveTextController',
                                        Duration(milliseconds: 0),
                                        () async {
                                          safeSetState(() {
                                            _model
                                                .tFPremiumRateFiveTextController
                                                ?.text = valueOrDefault<String>(
                                              functions.formatPercent(_model
                                                  .tFPremiumRateFiveTextController
                                                  .text),
                                              '0',
                                            );
                                            _model.tFPremiumRateFiveFocusNode
                                                ?.requestFocus();
                                            WidgetsBinding.instance
                                                .addPostFrameCallback((_) {
                                              _model.tFPremiumRateFiveTextController
                                                      ?.selection =
                                                  TextSelection.collapsed(
                                                offset: _model
                                                    .tFPremiumRateFiveTextController!
                                                    .text
                                                    .length,
                                              );
                                            });
                                            _model.tFPremiumRateFiveMask
                                                .updateMask(
                                              newValue: TextEditingValue(
                                                text: _model
                                                    .tFPremiumRateFiveTextController!
                                                    .text,
                                                selection:
                                                    TextSelection.collapsed(
                                                  offset: _model
                                                      .tFPremiumRateFiveTextController!
                                                      .text
                                                      .length,
                                                ),
                                              ),
                                            );
                                          });
                                        },
                                      ),
                                      autofocus: false,
                                      obscureText: false,
                                      decoration: InputDecoration(
                                        isDense: false,
                                        labelText: 'Taxa Premium 5 anos',
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
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .secondaryBackground,
                                              letterSpacing: 0.0,
                                              fontWeight:
                                                  FlutterFlowTheme.of(context)
                                                      .labelMedium
                                                      .fontWeight,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .labelMedium
                                                      .fontStyle,
                                            ),
                                        hintText: 'Taxa Premium',
                                        hintStyle: FlutterFlowTheme.of(context)
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
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .secondaryBackground,
                                              letterSpacing: 0.0,
                                              fontWeight:
                                                  FlutterFlowTheme.of(context)
                                                      .labelMedium
                                                      .fontWeight,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .labelMedium
                                                      .fontStyle,
                                            ),
                                        enabledBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: Color(0x73FFFFFF),
                                            width: 1.0,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: FlutterFlowTheme.of(context)
                                                .primary,
                                            width: 1.0,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                        ),
                                        errorBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: FlutterFlowTheme.of(context)
                                                .error,
                                            width: 1.0,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                        ),
                                        focusedErrorBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: FlutterFlowTheme.of(context)
                                                .error,
                                            width: 1.0,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                        ),
                                        filled: true,
                                        fillColor: Color(0xFF404040),
                                      ),
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
                                                .secondaryBackground,
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
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                              decimal: true),
                                      cursorColor: FlutterFlowTheme.of(context)
                                          .secondaryBackground,
                                      validator: _model
                                          .tFPremiumRateFiveTextControllerValidator
                                          .asValidator(context),
                                      inputFormatters: [
                                        _model.tFPremiumRateFiveMask
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsetsDirectional.fromSTEB(
                                        0.0, 12.0, 0.0, 0.0),
                                    child: TextFormField(
                                      controller: _model
                                              .tFPremiumRateSevenTextController ??=
                                          TextEditingController(
                                        text: valueOrDefault<String>(
                                          (double premiumSeven) {
                                            return (premiumSeven * 100)
                                                    .toStringAsFixed(2) +
                                                '%';
                                          }(cTCsrdAircraftFinancingRatesRow!
                                              .premiumRateSeven),
                                          '0',
                                        ),
                                      ),
                                      focusNode:
                                          _model.tFPremiumRateSevenFocusNode,
                                      onChanged: (_) => EasyDebounce.debounce(
                                        '_model.tFPremiumRateSevenTextController',
                                        Duration(milliseconds: 0),
                                        () async {
                                          safeSetState(() {
                                            _model
                                                .tFPremiumRateSevenTextController
                                                ?.text = valueOrDefault<String>(
                                              functions.formatPercent(_model
                                                  .tFPremiumRateSevenTextController
                                                  .text),
                                              '0',
                                            );
                                            _model.tFPremiumRateSevenFocusNode
                                                ?.requestFocus();
                                            WidgetsBinding.instance
                                                .addPostFrameCallback((_) {
                                              _model.tFPremiumRateSevenTextController
                                                      ?.selection =
                                                  TextSelection.collapsed(
                                                offset: _model
                                                    .tFPremiumRateSevenTextController!
                                                    .text
                                                    .length,
                                              );
                                            });
                                            _model.tFPremiumRateSevenMask
                                                .updateMask(
                                              newValue: TextEditingValue(
                                                text: _model
                                                    .tFPremiumRateSevenTextController!
                                                    .text,
                                                selection:
                                                    TextSelection.collapsed(
                                                  offset: _model
                                                      .tFPremiumRateSevenTextController!
                                                      .text
                                                      .length,
                                                ),
                                              ),
                                            );
                                          });
                                        },
                                      ),
                                      autofocus: false,
                                      obscureText: false,
                                      decoration: InputDecoration(
                                        isDense: false,
                                        labelText: 'Taxa Premium 7 anos',
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
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .secondaryBackground,
                                              letterSpacing: 0.0,
                                              fontWeight:
                                                  FlutterFlowTheme.of(context)
                                                      .labelMedium
                                                      .fontWeight,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .labelMedium
                                                      .fontStyle,
                                            ),
                                        hintText: 'Taxa Premium',
                                        hintStyle: FlutterFlowTheme.of(context)
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
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .secondaryBackground,
                                              letterSpacing: 0.0,
                                              fontWeight:
                                                  FlutterFlowTheme.of(context)
                                                      .labelMedium
                                                      .fontWeight,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .labelMedium
                                                      .fontStyle,
                                            ),
                                        enabledBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: Color(0x73FFFFFF),
                                            width: 1.0,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: FlutterFlowTheme.of(context)
                                                .primary,
                                            width: 1.0,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                        ),
                                        errorBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: FlutterFlowTheme.of(context)
                                                .error,
                                            width: 1.0,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                        ),
                                        focusedErrorBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: FlutterFlowTheme.of(context)
                                                .error,
                                            width: 1.0,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(8.0),
                                        ),
                                        filled: true,
                                        fillColor: Color(0xFF404040),
                                      ),
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
                                                .secondaryBackground,
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
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                              decimal: true),
                                      cursorColor: FlutterFlowTheme.of(context)
                                          .secondaryBackground,
                                      validator: _model
                                          .tFPremiumRateSevenTextControllerValidator
                                          .asValidator(context),
                                      inputFormatters: [
                                        _model.tFPremiumRateSevenMask
                                      ],
                                    ),
                                  ),
                                  TextFormField(
                                    controller:
                                        _model.tFSofrRateTextController ??=
                                            TextEditingController(
                                      text: valueOrDefault<String>(
                                        (double sofr) {
                                          return (sofr * 100)
                                                  .toStringAsFixed(2) +
                                              '%';
                                        }(cTCsrdAircraftFinancingRatesRow!
                                            .sofrRate),
                                        '0',
                                      ),
                                    ),
                                    focusNode: _model.tFSofrRateFocusNode,
                                    onChanged: (_) => EasyDebounce.debounce(
                                      '_model.tFSofrRateTextController',
                                      Duration(milliseconds: 0),
                                      () async {
                                        safeSetState(() {
                                          _model.tFSofrRateTextController
                                              ?.text = valueOrDefault<String>(
                                            functions.formatPercent(_model
                                                .tFSofrRateTextController.text),
                                            '0',
                                          );
                                          _model.tFSofrRateFocusNode
                                              ?.requestFocus();
                                          WidgetsBinding.instance
                                              .addPostFrameCallback((_) {
                                            _model.tFSofrRateTextController
                                                    ?.selection =
                                                TextSelection.collapsed(
                                              offset: _model
                                                  .tFSofrRateTextController!
                                                  .text
                                                  .length,
                                            );
                                          });
                                          _model.tFSofrRateMask.updateMask(
                                            newValue: TextEditingValue(
                                              text: _model
                                                  .tFSofrRateTextController!
                                                  .text,
                                              selection:
                                                  TextSelection.collapsed(
                                                offset: _model
                                                    .tFSofrRateTextController!
                                                    .text
                                                    .length,
                                              ),
                                            ),
                                          );
                                        });
                                      },
                                    ),
                                    autofocus: false,
                                    obscureText: false,
                                    decoration: InputDecoration(
                                      isDense: false,
                                      labelText: 'Taxa SOFR',
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
                                            fontWeight:
                                                FlutterFlowTheme.of(context)
                                                    .labelMedium
                                                    .fontWeight,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .labelMedium
                                                    .fontStyle,
                                          ),
                                      hintText: 'Taxa SOFR',
                                      hintStyle: FlutterFlowTheme.of(context)
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
                                            fontWeight:
                                                FlutterFlowTheme.of(context)
                                                    .labelMedium
                                                    .fontWeight,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .labelMedium
                                                    .fontStyle,
                                          ),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Color(0x73FFFFFF),
                                          width: 1.0,
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: FlutterFlowTheme.of(context)
                                              .primary,
                                          width: 1.0,
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                      ),
                                      errorBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: FlutterFlowTheme.of(context)
                                              .error,
                                          width: 1.0,
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                      ),
                                      focusedErrorBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: FlutterFlowTheme.of(context)
                                              .error,
                                          width: 1.0,
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                      ),
                                      filled: true,
                                      fillColor: Color(0xFF404040),
                                    ),
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
                                              .secondaryBackground,
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
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                            decimal: true),
                                    cursorColor: FlutterFlowTheme.of(context)
                                        .secondaryBackground,
                                    validator: _model
                                        .tFSofrRateTextControllerValidator
                                        .asValidator(context),
                                    inputFormatters: [_model.tFSofrRateMask],
                                  ),
                                  TextFormField(
                                    controller:
                                        _model.tFInterestRateTextController ??=
                                            TextEditingController(
                                      text: valueOrDefault<String>(
                                        (double interest) {
                                          return (interest * 100)
                                                  .toStringAsFixed(2) +
                                              '%';
                                        }(cTCsrdAircraftFinancingRatesRow!
                                            .interestRate),
                                        '0',
                                      ),
                                    ),
                                    focusNode: _model.tFInterestRateFocusNode,
                                    onChanged: (_) => EasyDebounce.debounce(
                                      '_model.tFInterestRateTextController',
                                      Duration(milliseconds: 0),
                                      () async {
                                        safeSetState(() {
                                          _model.tFInterestRateTextController
                                              ?.text = valueOrDefault<String>(
                                            functions.formatPercent(_model
                                                .tFInterestRateTextController
                                                .text),
                                            '0',
                                          );
                                          _model.tFInterestRateFocusNode
                                              ?.requestFocus();
                                          WidgetsBinding.instance
                                              .addPostFrameCallback((_) {
                                            _model.tFInterestRateTextController
                                                    ?.selection =
                                                TextSelection.collapsed(
                                              offset: _model
                                                  .tFInterestRateTextController!
                                                  .text
                                                  .length,
                                            );
                                          });
                                          _model.tFInterestRateMask.updateMask(
                                            newValue: TextEditingValue(
                                              text: _model
                                                  .tFInterestRateTextController!
                                                  .text,
                                              selection:
                                                  TextSelection.collapsed(
                                                offset: _model
                                                    .tFInterestRateTextController!
                                                    .text
                                                    .length,
                                              ),
                                            ),
                                          );
                                        });
                                      },
                                    ),
                                    autofocus: false,
                                    obscureText: false,
                                    decoration: InputDecoration(
                                      isDense: false,
                                      labelText: 'Taxa de Juros',
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
                                            fontWeight:
                                                FlutterFlowTheme.of(context)
                                                    .labelMedium
                                                    .fontWeight,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .labelMedium
                                                    .fontStyle,
                                          ),
                                      hintText: 'Taxa de Juros',
                                      hintStyle: FlutterFlowTheme.of(context)
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
                                            fontWeight:
                                                FlutterFlowTheme.of(context)
                                                    .labelMedium
                                                    .fontWeight,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .labelMedium
                                                    .fontStyle,
                                          ),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: Color(0x73FFFFFF),
                                          width: 1.0,
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: FlutterFlowTheme.of(context)
                                              .primary,
                                          width: 1.0,
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                      ),
                                      errorBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: FlutterFlowTheme.of(context)
                                              .error,
                                          width: 1.0,
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                      ),
                                      focusedErrorBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                          color: FlutterFlowTheme.of(context)
                                              .error,
                                          width: 1.0,
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                      ),
                                      filled: true,
                                      fillColor: Color(0xFF404040),
                                    ),
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
                                              .secondaryBackground,
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
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                            decimal: true),
                                    cursorColor: FlutterFlowTheme.of(context)
                                        .secondaryBackground,
                                    validator: _model
                                        .tFInterestRateTextControllerValidator
                                        .asValidator(context),
                                    inputFormatters: [
                                      _model.tFInterestRateMask
                                    ],
                                  ),
                                ].divide(SizedBox(height: 16.0)),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding:
                          EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 16.0),
                      child: Container(
                        width: MediaQuery.sizeOf(context).width * 1.0,
                        constraints: BoxConstraints(
                          maxWidth: 800.0,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Align(
                              alignment: AlignmentDirectional(1.0, 0.0),
                              child: FFButtonWidget(
                                onPressed: () async {
                                  await FinancingRatesTable().update(
                                    data: {
                                      'sofr_rate': valueOrDefault<double>(
                                        (String sofr) {
                                          return double.parse(
                                                  sofr.replaceAll('%', '')) /
                                              100;
                                        }(_model.tFSofrRateTextController.text),
                                        0.0,
                                      ),
                                      'interest_rate': valueOrDefault<double>(
                                        (String interest) {
                                          return double.parse(interest
                                                  .replaceAll('%', '')) /
                                              100;
                                        }(_model
                                            .tFInterestRateTextController.text),
                                        0.0,
                                      ),
                                      'created_at': supaSerialize<DateTime>(
                                          getCurrentTimestamp),
                                      'created_by': currentUserUid,
                                      'premium_rate_five':
                                          valueOrDefault<double>(
                                        (String premiumFive) {
                                          return double.parse(premiumFive
                                                  .replaceAll('%', '')) /
                                              100;
                                        }(_model.tFPremiumRateFiveTextController
                                            .text),
                                        0.0,
                                      ),
                                      'premium_rate_seven':
                                          valueOrDefault<double>(
                                        (String premiumSeven) {
                                          return double.parse(premiumSeven
                                                  .replaceAll('%', '')) /
                                              100;
                                        }(_model
                                            .tFPremiumRateSevenTextController
                                            .text),
                                        0.0,
                                      ),
                                    },
                                    matchingRows: (rows) => rows.eqOrNull(
                                      'id',
                                      'ce659e4b-caee-4b88-8d99-46f15c7e9b69',
                                    ),
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Taxas atualizadas com sucesso!',
                                        style: TextStyle(
                                          color: FlutterFlowTheme.of(context)
                                              .primaryText,
                                        ),
                                      ),
                                      duration: Duration(milliseconds: 4000),
                                      backgroundColor:
                                          FlutterFlowTheme.of(context).primary,
                                    ),
                                  );

                                  context
                                      .pushNamed(ViewEditRatesWidget.routeName);

                                  safeSetState(() {});
                                },
                                text: 'Atualizar taxas',
                                options: FFButtonOptions(
                                  height: 48.0,
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      24.0, 0.0, 24.0, 0.0),
                                  iconPadding: EdgeInsetsDirectional.fromSTEB(
                                      0.0, 0.0, 0.0, 0.0),
                                  color: FlutterFlowTheme.of(context).primary,
                                  textStyle: FlutterFlowTheme.of(context)
                                      .titleSmall
                                      .override(
                                        font: GoogleFonts.roboto(
                                          fontWeight: FontWeight.w500,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .titleSmall
                                                  .fontStyle,
                                        ),
                                        color: FlutterFlowTheme.of(context)
                                            .primaryText,
                                        fontSize: 14.0,
                                        letterSpacing: 0.0,
                                        fontWeight: FontWeight.w500,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .titleSmall
                                            .fontStyle,
                                      ),
                                  elevation: 0.0,
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                              ),
                            ),
                          ].divide(SizedBox(width: 24.0)),
                        ),
                      ),
                    ),
                  ]
                      .divide(SizedBox(height: 16.0))
                      .addToEnd(SizedBox(height: 32.0)),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
