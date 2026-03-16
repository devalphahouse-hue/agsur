import '/auth/supabase_auth/auth_util.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/upload_data.dart';
import 'dart:ui';
import '/flutter_flow/custom_functions.dart' as functions;
import '/index.dart';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'aircraft_details_model.dart';
export 'aircraft_details_model.dart';

class AircraftDetailsWidget extends StatefulWidget {
  const AircraftDetailsWidget({
    super.key,
    required this.aircraftId,
  });

  final String? aircraftId;

  static String routeName = 'AircraftDetails';
  static String routePath = '/aircraftDetails';

  @override
  State<AircraftDetailsWidget> createState() => _AircraftDetailsWidgetState();
}

class _AircraftDetailsWidgetState extends State<AircraftDetailsWidget> {
  late AircraftDetailsModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AircraftDetailsModel());

    _model.tFAircraftNameFocusNode ??= FocusNode();

    _model.tFPriceFocusNode ??= FocusNode();

    _model.tFAircraftHopperFocusNode ??= FocusNode();

    _model.tFDescriptionFocusNode ??= FocusNode();

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
            'Detalhes da aeronave',
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
          child: Builder(
            builder: (context) {
              if (_model.isEdit) {
                return Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(0.0, 28.0, 0.0, 0.0),
                  child: FutureBuilder<List<VwMyAircraftDetailsRow>>(
                    future: VwMyAircraftDetailsTable().querySingleRow(
                      queryFn: (q) => q.eqOrNull(
                        'aircraft_id',
                        widget!.aircraftId,
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
                      List<VwMyAircraftDetailsRow>
                          containerVwMyAircraftDetailsRowList = snapshot.data!;

                      final containerVwMyAircraftDetailsRow =
                          containerVwMyAircraftDetailsRowList.isNotEmpty
                              ? containerVwMyAircraftDetailsRowList.first
                              : null;

                      return Container(
                        width: MediaQuery.sizeOf(context).width * 1.0,
                        decoration: BoxDecoration(),
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              Form(
                                key: _model.formKey,
                                autovalidateMode: AutovalidateMode.disabled,
                                child: Padding(
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      16.0, 36.0, 16.0, 16.0),
                                  child: Container(
                                    width:
                                        MediaQuery.sizeOf(context).width * 1.0,
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
                                            alignment:
                                                AlignmentDirectional(-1.0, 0.0),
                                            child: Padding(
                                              padding: EdgeInsetsDirectional
                                                  .fromSTEB(
                                                      12.0, 0.0, 12.0, 0.0),
                                              child: Text(
                                                'Dados Cadastrais da Aeronave',
                                                style: FlutterFlowTheme.of(
                                                        context)
                                                    .bodyMedium
                                                    .override(
                                                      font: GoogleFonts.roboto(
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        fontStyle:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .bodyMedium
                                                                .fontStyle,
                                                      ),
                                                      color: FlutterFlowTheme
                                                              .of(context)
                                                          .secondaryBackground,
                                                      fontSize: 18.0,
                                                      letterSpacing: 0.0,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      fontStyle:
                                                          FlutterFlowTheme.of(
                                                                  context)
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
                                          if ((containerVwMyAircraftDetailsRow
                                                          ?.aircraftPhotoUrl !=
                                                      null &&
                                                  containerVwMyAircraftDetailsRow
                                                          ?.aircraftPhotoUrl !=
                                                      '') ||
                                              (_model.uploadedFileUrl_uploadUpdateAircraft !=
                                                      null &&
                                                  _model.uploadedFileUrl_uploadUpdateAircraft !=
                                                      ''))
                                            Padding(
                                              padding: EdgeInsets.all(12.0),
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(12.0),
                                                child: Image.network(
                                                  containerVwMyAircraftDetailsRow
                                                                  ?.aircraftPhotoUrl !=
                                                              null &&
                                                          containerVwMyAircraftDetailsRow
                                                                  ?.aircraftPhotoUrl !=
                                                              ''
                                                      ? containerVwMyAircraftDetailsRow!
                                                          .aircraftPhotoUrl!
                                                      : _model
                                                          .uploadedFileUrl_uploadUpdateAircraft,
                                                  width:
                                                      MediaQuery.sizeOf(context)
                                                              .width *
                                                          2.0,
                                                  height: 200.0,
                                                  fit: BoxFit.contain,
                                                ),
                                              ),
                                            ),
                                          Padding(
                                            padding:
                                                EdgeInsetsDirectional.fromSTEB(
                                                    0.0, 0.0, 0.0, 16.0),
                                            child: Container(
                                              width: double.infinity,
                                              height: 50.0,
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(8.0),
                                                border: Border.all(
                                                  color: valueOrDefault<Color>(
                                                    _model.uploadedFileUrl_uploadUpdateAircraft !=
                                                                null &&
                                                            _model.uploadedFileUrl_uploadUpdateAircraft !=
                                                                ''
                                                        ? Color(0x72FFFFFF)
                                                        : FlutterFlowTheme.of(
                                                                context)
                                                            .error,
                                                    Color(0x73FFFFFF),
                                                  ),
                                                  width: 2.0,
                                                ),
                                              ),
                                              child: Builder(
                                                builder: (context) {
                                                  if (containerVwMyAircraftDetailsRow
                                                              ?.aircraftPhotoUrl ==
                                                          null ||
                                                      containerVwMyAircraftDetailsRow
                                                              ?.aircraftPhotoUrl ==
                                                          '') {
                                                    return InkWell(
                                                      splashColor:
                                                          Colors.transparent,
                                                      focusColor:
                                                          Colors.transparent,
                                                      hoverColor:
                                                          Colors.transparent,
                                                      highlightColor:
                                                          Colors.transparent,
                                                      onTap: () async {
                                                        final selectedMedia =
                                                            await selectMedia(
                                                          storageFolderPath: '',
                                                          mediaSource:
                                                              MediaSource
                                                                  .photoGallery,
                                                          multiImage: false,
                                                        );
                                                        if (selectedMedia !=
                                                                null &&
                                                            selectedMedia.every((m) =>
                                                                validateFileFormat(
                                                                    m.storagePath,
                                                                    context))) {
                                                          safeSetState(() =>
                                                              _model.isDataUploading_uploadUpdateAircraft =
                                                                  true);
                                                          var selectedUploadedFiles =
                                                              <FFUploadedFile>[];

                                                          var downloadUrls =
                                                              <String>[];
                                                          try {
                                                            selectedUploadedFiles =
                                                                selectedMedia
                                                                    .map((m) =>
                                                                        FFUploadedFile(
                                                                          name: m
                                                                              .storagePath
                                                                              .split('/')
                                                                              .last,
                                                                          bytes:
                                                                              m.bytes,
                                                                          height: m
                                                                              .dimensions
                                                                              ?.height,
                                                                          width: m
                                                                              .dimensions
                                                                              ?.width,
                                                                          blurHash:
                                                                              m.blurHash,
                                                                          originalFilename:
                                                                              m.originalFilename,
                                                                        ))
                                                                    .toList();

                                                            downloadUrls =
                                                                await uploadSupabaseStorageFiles(
                                                              bucketName:
                                                                  'AGSur',
                                                              selectedFiles:
                                                                  selectedMedia,
                                                            );
                                                          } finally {
                                                            _model.isDataUploading_uploadUpdateAircraft =
                                                                false;
                                                          }
                                                          if (selectedUploadedFiles
                                                                      .length ==
                                                                  selectedMedia
                                                                      .length &&
                                                              downloadUrls
                                                                      .length ==
                                                                  selectedMedia
                                                                      .length) {
                                                            safeSetState(() {
                                                              _model.uploadedLocalFile_uploadUpdateAircraft =
                                                                  selectedUploadedFiles
                                                                      .first;
                                                              _model.uploadedFileUrl_uploadUpdateAircraft =
                                                                  downloadUrls
                                                                      .first;
                                                            });
                                                          } else {
                                                            safeSetState(() {});
                                                            return;
                                                          }
                                                        }
                                                      },
                                                      child: Container(
                                                        width: 300.0,
                                                        height: 50.0,
                                                        decoration:
                                                            BoxDecoration(
                                                          image:
                                                              DecorationImage(
                                                            fit: BoxFit.contain,
                                                            image: Image.asset(
                                                              'assets/images/Clique_aqui_para_adicionar_uma_foto_(1).png',
                                                            ).image,
                                                          ),
                                                        ),
                                                      ),
                                                    );
                                                  } else {
                                                    return Align(
                                                      alignment:
                                                          AlignmentDirectional(
                                                              0.0, 0.0),
                                                      child: InkWell(
                                                        splashColor:
                                                            Colors.transparent,
                                                        focusColor:
                                                            Colors.transparent,
                                                        hoverColor:
                                                            Colors.transparent,
                                                        highlightColor:
                                                            Colors.transparent,
                                                        onTap: () async {
                                                          await AircraftsTable()
                                                              .update(
                                                            data: {
                                                              'aircraft_photo_url':
                                                                  '',
                                                            },
                                                            matchingRows:
                                                                (rows) => rows
                                                                    .eqOrNull(
                                                              'id',
                                                              widget!
                                                                  .aircraftId,
                                                            ),
                                                          );
                                                          safeSetState(() {
                                                            _model.isDataUploading_uploadUpdateAircraft =
                                                                false;
                                                            _model.uploadedLocalFile_uploadUpdateAircraft =
                                                                FFUploadedFile(
                                                                    bytes: Uint8List
                                                                        .fromList(
                                                                            []),
                                                                    originalFilename:
                                                                        '');
                                                            _model.uploadedFileUrl_uploadUpdateAircraft =
                                                                '';
                                                          });

                                                          safeSetState(() {});
                                                        },
                                                        child: Container(
                                                          decoration:
                                                              BoxDecoration(),
                                                          child: Text(
                                                            'Deletar imagem',
                                                            style: FlutterFlowTheme
                                                                    .of(context)
                                                                .bodyMedium
                                                                .override(
                                                                  font:
                                                                      GoogleFonts
                                                                          .inter(
                                                                    fontWeight: FlutterFlowTheme.of(
                                                                            context)
                                                                        .bodyMedium
                                                                        .fontWeight,
                                                                    fontStyle: FlutterFlowTheme.of(
                                                                            context)
                                                                        .bodyMedium
                                                                        .fontStyle,
                                                                  ),
                                                                  color: FlutterFlowTheme.of(
                                                                          context)
                                                                      .error,
                                                                  letterSpacing:
                                                                      0.0,
                                                                  fontWeight: FlutterFlowTheme.of(
                                                                          context)
                                                                      .bodyMedium
                                                                      .fontWeight,
                                                                  fontStyle: FlutterFlowTheme.of(
                                                                          context)
                                                                      .bodyMedium
                                                                      .fontStyle,
                                                                ),
                                                          ),
                                                        ),
                                                      ),
                                                    );
                                                  }
                                                },
                                              ),
                                            ),
                                          ),
                                          TextFormField(
                                            controller: _model
                                                    .tFAircraftNameTextController ??=
                                                TextEditingController(
                                              text:
                                                  containerVwMyAircraftDetailsRow
                                                      ?.name,
                                            ),
                                            focusNode:
                                                _model.tFAircraftNameFocusNode,
                                            autofocus: false,
                                            obscureText: false,
                                            decoration: InputDecoration(
                                              isDense: false,
                                              labelText: 'Modelo da Aeronave',
                                              labelStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .labelMedium
                                                      .override(
                                                        font: GoogleFonts.inter(
                                                          fontWeight:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .labelMedium
                                                                  .fontWeight,
                                                          fontStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .labelMedium
                                                                  .fontStyle,
                                                        ),
                                                        color: FlutterFlowTheme
                                                                .of(context)
                                                            .secondaryBackground,
                                                        letterSpacing: 0.0,
                                                        fontWeight:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .labelMedium
                                                                .fontWeight,
                                                        fontStyle:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .labelMedium
                                                                .fontStyle,
                                                      ),
                                              hintText: 'Modelo da Aeronave',
                                              hintStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .labelMedium
                                                      .override(
                                                        font: GoogleFonts.inter(
                                                          fontWeight:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .labelMedium
                                                                  .fontWeight,
                                                          fontStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .labelMedium
                                                                  .fontStyle,
                                                        ),
                                                        color: FlutterFlowTheme
                                                                .of(context)
                                                            .secondaryBackground,
                                                        letterSpacing: 0.0,
                                                        fontWeight:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .labelMedium
                                                                .fontWeight,
                                                        fontStyle:
                                                            FlutterFlowTheme.of(
                                                                    context)
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
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .primary,
                                                  width: 1.0,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(8.0),
                                              ),
                                              errorBorder: OutlineInputBorder(
                                                borderSide: BorderSide(
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .error,
                                                  width: 1.0,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(8.0),
                                              ),
                                              focusedErrorBorder:
                                                  OutlineInputBorder(
                                                borderSide: BorderSide(
                                                  color: FlutterFlowTheme.of(
                                                          context)
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
                                                      .secondaryBackground,
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
                                            cursorColor:
                                                FlutterFlowTheme.of(context)
                                                    .secondaryBackground,
                                            validator: _model
                                                .tFAircraftNameTextControllerValidator
                                                .asValidator(context),
                                          ),
                                          TextFormField(
                                            controller:
                                                _model.tFPriceTextController ??=
                                                    TextEditingController(
                                              text: valueOrDefault<String>(
                                                formatNumber(
                                                  containerVwMyAircraftDetailsRow
                                                      ?.price,
                                                  formatType:
                                                      FormatType.decimal,
                                                  decimalType:
                                                      DecimalType.periodDecimal,
                                                  currency: '\$',
                                                ),
                                                '\$0,00',
                                              ),
                                            ),
                                            focusNode: _model.tFPriceFocusNode,
                                            onChanged: (_) =>
                                                EasyDebounce.debounce(
                                              '_model.tFPriceTextController',
                                              Duration(milliseconds: 0),
                                              () async {
                                                safeSetState(() {
                                                  _model.tFPriceTextController
                                                          ?.text =
                                                      valueOrDefault<String>(
                                                    functions.formatarMoedaEmDolar(
                                                        _model
                                                            .tFPriceTextController
                                                            .text),
                                                    '0',
                                                  );
                                                  _model.tFPriceFocusNode
                                                      ?.requestFocus();
                                                  WidgetsBinding.instance
                                                      .addPostFrameCallback(
                                                          (_) {
                                                    _model.tFPriceTextController
                                                            ?.selection =
                                                        TextSelection.collapsed(
                                                      offset: _model
                                                          .tFPriceTextController!
                                                          .text
                                                          .length,
                                                    );
                                                  });
                                                });
                                              },
                                            ),
                                            autofocus: false,
                                            obscureText: false,
                                            decoration: InputDecoration(
                                              isDense: false,
                                              labelText: 'Preço de Venda',
                                              labelStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .labelMedium
                                                      .override(
                                                        font: GoogleFonts.inter(
                                                          fontWeight:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .labelMedium
                                                                  .fontWeight,
                                                          fontStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .labelMedium
                                                                  .fontStyle,
                                                        ),
                                                        color: FlutterFlowTheme
                                                                .of(context)
                                                            .secondaryBackground,
                                                        letterSpacing: 0.0,
                                                        fontWeight:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .labelMedium
                                                                .fontWeight,
                                                        fontStyle:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .labelMedium
                                                                .fontStyle,
                                                      ),
                                              hintText: '\$ 0.00',
                                              hintStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .labelMedium
                                                      .override(
                                                        font: GoogleFonts.inter(
                                                          fontWeight:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .labelMedium
                                                                  .fontWeight,
                                                          fontStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .labelMedium
                                                                  .fontStyle,
                                                        ),
                                                        color: FlutterFlowTheme
                                                                .of(context)
                                                            .secondaryBackground,
                                                        letterSpacing: 0.0,
                                                        fontWeight:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .labelMedium
                                                                .fontWeight,
                                                        fontStyle:
                                                            FlutterFlowTheme.of(
                                                                    context)
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
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .primary,
                                                  width: 1.0,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(8.0),
                                              ),
                                              errorBorder: OutlineInputBorder(
                                                borderSide: BorderSide(
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .error,
                                                  width: 1.0,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(8.0),
                                              ),
                                              focusedErrorBorder:
                                                  OutlineInputBorder(
                                                borderSide: BorderSide(
                                                  color: FlutterFlowTheme.of(
                                                          context)
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
                                                      .secondaryBackground,
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
                                            cursorColor:
                                                FlutterFlowTheme.of(context)
                                                    .secondaryBackground,
                                            validator: _model
                                                .tFPriceTextControllerValidator
                                                .asValidator(context),
                                          ),
                                        ].divide(SizedBox(height: 16.0)),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    16.0, 0.0, 16.0, 16.0),
                                child: Container(
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
                                          alignment:
                                              AlignmentDirectional(-1.0, 0.0),
                                          child: Padding(
                                            padding:
                                                EdgeInsetsDirectional.fromSTEB(
                                                    12.0, 0.0, 12.0, 0.0),
                                            child: Text(
                                              'Descrição da Aeronave',
                                              style: FlutterFlowTheme.of(
                                                      context)
                                                  .bodyMedium
                                                  .override(
                                                    font: GoogleFonts.roboto(
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      fontStyle:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .bodyMedium
                                                              .fontStyle,
                                                    ),
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .secondaryBackground,
                                                    fontSize: 18.0,
                                                    letterSpacing: 0.0,
                                                    fontWeight: FontWeight.w500,
                                                    fontStyle:
                                                        FlutterFlowTheme.of(
                                                                context)
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
                                        TextFormField(
                                          controller: _model
                                                  .tFAircraftHopperTextController ??=
                                              TextEditingController(
                                            text:
                                                containerVwMyAircraftDetailsRow
                                                    ?.hopper
                                                    ?.toString(),
                                          ),
                                          focusNode:
                                              _model.tFAircraftHopperFocusNode,
                                          autofocus: false,
                                          obscureText: false,
                                          decoration: InputDecoration(
                                            isDense: false,
                                            labelText: 'Hopper',
                                            labelStyle:
                                                FlutterFlowTheme.of(context)
                                                    .labelMedium
                                                    .override(
                                                      font: GoogleFonts.inter(
                                                        fontWeight:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .labelMedium
                                                                .fontWeight,
                                                        fontStyle:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .labelMedium
                                                                .fontStyle,
                                                      ),
                                                      color: FlutterFlowTheme
                                                              .of(context)
                                                          .secondaryBackground,
                                                      letterSpacing: 0.0,
                                                      fontWeight:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .labelMedium
                                                              .fontWeight,
                                                      fontStyle:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .labelMedium
                                                              .fontStyle,
                                                    ),
                                            hintText: 'Hopper',
                                            hintStyle:
                                                FlutterFlowTheme.of(context)
                                                    .labelMedium
                                                    .override(
                                                      font: GoogleFonts.inter(
                                                        fontWeight:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .labelMedium
                                                                .fontWeight,
                                                        fontStyle:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .labelMedium
                                                                .fontStyle,
                                                      ),
                                                      color: FlutterFlowTheme
                                                              .of(context)
                                                          .secondaryBackground,
                                                      letterSpacing: 0.0,
                                                      fontWeight:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .labelMedium
                                                              .fontWeight,
                                                      fontStyle:
                                                          FlutterFlowTheme.of(
                                                                  context)
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
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .primary,
                                                width: 1.0,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                            ),
                                            errorBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .error,
                                                width: 1.0,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                            ),
                                            focusedErrorBorder:
                                                OutlineInputBorder(
                                              borderSide: BorderSide(
                                                color:
                                                    FlutterFlowTheme.of(context)
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
                                                color:
                                                    FlutterFlowTheme.of(context)
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
                                          keyboardType: TextInputType.number,
                                          cursorColor:
                                              FlutterFlowTheme.of(context)
                                                  .secondaryBackground,
                                          validator: _model
                                              .tFAircraftHopperTextControllerValidator
                                              .asValidator(context),
                                          inputFormatters: [
                                            FilteringTextInputFormatter.allow(
                                                RegExp('[0-9]'))
                                          ],
                                        ),
                                        TextFormField(
                                          controller: _model
                                                  .tFDescriptionTextController ??=
                                              TextEditingController(
                                            text:
                                                containerVwMyAircraftDetailsRow
                                                    ?.aircraftDescription,
                                          ),
                                          focusNode:
                                              _model.tFDescriptionFocusNode,
                                          autofocus: false,
                                          obscureText: false,
                                          decoration: InputDecoration(
                                            isDense: false,
                                            labelText: 'Descrição',
                                            labelStyle:
                                                FlutterFlowTheme.of(context)
                                                    .labelMedium
                                                    .override(
                                                      font: GoogleFonts.inter(
                                                        fontWeight:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .labelMedium
                                                                .fontWeight,
                                                        fontStyle:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .labelMedium
                                                                .fontStyle,
                                                      ),
                                                      color: FlutterFlowTheme
                                                              .of(context)
                                                          .secondaryBackground,
                                                      letterSpacing: 0.0,
                                                      fontWeight:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .labelMedium
                                                              .fontWeight,
                                                      fontStyle:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .labelMedium
                                                              .fontStyle,
                                                    ),
                                            hintText:
                                                'Adicione a descrição da aeronave aqui',
                                            hintStyle:
                                                FlutterFlowTheme.of(context)
                                                    .labelMedium
                                                    .override(
                                                      font: GoogleFonts.inter(
                                                        fontWeight:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .labelMedium
                                                                .fontWeight,
                                                        fontStyle:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .labelMedium
                                                                .fontStyle,
                                                      ),
                                                      color: FlutterFlowTheme
                                                              .of(context)
                                                          .secondaryBackground,
                                                      letterSpacing: 0.0,
                                                      fontWeight:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .labelMedium
                                                              .fontWeight,
                                                      fontStyle:
                                                          FlutterFlowTheme.of(
                                                                  context)
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
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .primary,
                                                width: 1.0,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                            ),
                                            errorBorder: OutlineInputBorder(
                                              borderSide: BorderSide(
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .error,
                                                width: 1.0,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                            ),
                                            focusedErrorBorder:
                                                OutlineInputBorder(
                                              borderSide: BorderSide(
                                                color:
                                                    FlutterFlowTheme.of(context)
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
                                                color:
                                                    FlutterFlowTheme.of(context)
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
                                          maxLines: null,
                                          minLines: 5,
                                          cursorColor:
                                              FlutterFlowTheme.of(context)
                                                  .secondaryBackground,
                                          validator: _model
                                              .tFDescriptionTextControllerValidator
                                              .asValidator(context),
                                        ),
                                      ].divide(SizedBox(height: 16.0)),
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    16.0, 0.0, 16.0, 16.0),
                                child: Container(
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
                                      mainAxisSize: MainAxisSize.max,
                                      children: [
                                        Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.max,
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Container(
                                                  height: 50.0,
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8.0),
                                                    border: Border.all(
                                                      color: Color(0x73FFFFFF),
                                                      width: 2.0,
                                                    ),
                                                  ),
                                                  child: Builder(
                                                    builder: (context) {
                                                      if (containerVwMyAircraftDetailsRow
                                                              ?.ownerManuals ==
                                                          null) {
                                                        return Visibility(
                                                          visible: _model
                                                                      .uploadedFileUrl_uploadUpdateOEM ==
                                                                  null ||
                                                              _model.uploadedFileUrl_uploadUpdateOEM ==
                                                                  '',
                                                          child: Container(
                                                            height: 50.0,
                                                            constraints:
                                                                BoxConstraints(
                                                              minWidth: 200.0,
                                                              maxWidth: 300.0,
                                                            ),
                                                            decoration:
                                                                BoxDecoration(
                                                              image:
                                                                  DecorationImage(
                                                                fit: BoxFit
                                                                    .contain,
                                                                image:
                                                                    Image.asset(
                                                                  'assets/images/OEM.png',
                                                                ).image,
                                                              ),
                                                            ),
                                                          ),
                                                        );
                                                      } else {
                                                        return Align(
                                                          alignment:
                                                              AlignmentDirectional(
                                                                  0.0, 0.0),
                                                          child: Text(
                                                            _model.uploadedFileUrl_uploadUpdateOEM !=
                                                                        null &&
                                                                    _model.uploadedFileUrl_uploadUpdateOEM !=
                                                                        ''
                                                                ? valueOrDefault<
                                                                    String>(
                                                                    functions.fileNamePath(
                                                                        _model
                                                                            .uploadedFileUrl_uploadUpdateOEM),
                                                                    'arquivo.pdf',
                                                                  )
                                                                : valueOrDefault<
                                                                    String>(
                                                                    functions.fileNamePath(containerVwMyAircraftDetailsRow!
                                                                        .ownerManuals!
                                                                        .toString()),
                                                                    'arquivo.pdf',
                                                                  ),
                                                            style: FlutterFlowTheme
                                                                    .of(context)
                                                                .bodyMedium
                                                                .override(
                                                                  font:
                                                                      GoogleFonts
                                                                          .inter(
                                                                    fontWeight: FlutterFlowTheme.of(
                                                                            context)
                                                                        .bodyMedium
                                                                        .fontWeight,
                                                                    fontStyle: FlutterFlowTheme.of(
                                                                            context)
                                                                        .bodyMedium
                                                                        .fontStyle,
                                                                  ),
                                                                  color: FlutterFlowTheme.of(
                                                                          context)
                                                                      .secondaryBackground,
                                                                  letterSpacing:
                                                                      0.0,
                                                                  fontWeight: FlutterFlowTheme.of(
                                                                          context)
                                                                      .bodyMedium
                                                                      .fontWeight,
                                                                  fontStyle: FlutterFlowTheme.of(
                                                                          context)
                                                                      .bodyMedium
                                                                      .fontStyle,
                                                                ),
                                                          ),
                                                        );
                                                      }
                                                    },
                                                  ),
                                                ),
                                              ),
                                              Builder(
                                                builder: (context) {
                                                  if (containerVwMyAircraftDetailsRow
                                                          ?.ownerManuals !=
                                                      null) {
                                                    return Row(
                                                      mainAxisSize:
                                                          MainAxisSize.max,
                                                      children: [
                                                        FlutterFlowIconButton(
                                                          borderRadius: 8.0,
                                                          buttonSize: 44.0,
                                                          fillColor:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .primary,
                                                          icon: Icon(
                                                            Icons.check_rounded,
                                                            color: FlutterFlowTheme
                                                                    .of(context)
                                                                .primaryText,
                                                            size: 28.0,
                                                          ),
                                                          onPressed: () {
                                                            print(
                                                                'IconButtonCheckProprietario pressed ...');
                                                          },
                                                        ),
                                                        FlutterFlowIconButton(
                                                          borderRadius: 8.0,
                                                          buttonSize: 44.0,
                                                          fillColor:
                                                              Color(0xFF313131),
                                                          icon: Icon(
                                                            Icons.upload_file,
                                                            color: Color(
                                                                0x72FFFFFF),
                                                            size: 28.0,
                                                          ),
                                                          onPressed: () async {
                                                            final selectedFiles =
                                                                await selectFiles(
                                                              storageFolderPath:
                                                                  '',
                                                              allowedExtensions: [
                                                                'pdf'
                                                              ],
                                                              multiFile: false,
                                                            );
                                                            if (selectedFiles !=
                                                                null) {
                                                              safeSetState(() =>
                                                                  _model.isDataUploading_uploadUpdateOEM =
                                                                      true);
                                                              var selectedUploadedFiles =
                                                                  <FFUploadedFile>[];

                                                              var downloadUrls =
                                                                  <String>[];
                                                              try {
                                                                selectedUploadedFiles =
                                                                    selectedFiles
                                                                        .map((m) =>
                                                                            FFUploadedFile(
                                                                              name: m.storagePath.split('/').last,
                                                                              bytes: m.bytes,
                                                                              originalFilename: m.originalFilename,
                                                                            ))
                                                                        .toList();

                                                                downloadUrls =
                                                                    await uploadSupabaseStorageFiles(
                                                                  bucketName:
                                                                      'AGSur',
                                                                  selectedFiles:
                                                                      selectedFiles,
                                                                );
                                                              } finally {
                                                                _model.isDataUploading_uploadUpdateOEM =
                                                                    false;
                                                              }
                                                              if (selectedUploadedFiles
                                                                          .length ==
                                                                      selectedFiles
                                                                          .length &&
                                                                  downloadUrls
                                                                          .length ==
                                                                      selectedFiles
                                                                          .length) {
                                                                safeSetState(
                                                                    () {
                                                                  _model.uploadedLocalFile_uploadUpdateOEM =
                                                                      selectedUploadedFiles
                                                                          .first;
                                                                  _model.uploadedFileUrl_uploadUpdateOEM =
                                                                      downloadUrls
                                                                          .first;
                                                                });
                                                              } else {
                                                                safeSetState(
                                                                    () {});
                                                                return;
                                                              }
                                                            }
                                                          },
                                                        ),
                                                      ].divide(
                                                          SizedBox(width: 8.0)),
                                                    );
                                                  } else {
                                                    return FlutterFlowIconButton(
                                                      borderRadius: 8.0,
                                                      buttonSize: 44.0,
                                                      fillColor:
                                                          Color(0xFF313131),
                                                      icon: Icon(
                                                        Icons
                                                            .assignment_outlined,
                                                        color:
                                                            Color(0x72FFFFFF),
                                                        size: 28.0,
                                                      ),
                                                      onPressed: () {
                                                        print(
                                                            'IconButtonProprietario pressed ...');
                                                      },
                                                    );
                                                  }
                                                },
                                              ),
                                            ].divide(SizedBox(width: 16.0)),
                                          ),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.max,
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Container(
                                                  height: 50.0,
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8.0),
                                                    border: Border.all(
                                                      color: Color(0x73FFFFFF),
                                                      width: 2.0,
                                                    ),
                                                  ),
                                                  child: Builder(
                                                    builder: (context) {
                                                      if (containerVwMyAircraftDetailsRow
                                                              ?.flightManuals ==
                                                          null) {
                                                        return Visibility(
                                                          visible: _model
                                                                      .uploadedFileUrl_uploadUpdateManualVoo ==
                                                                  null ||
                                                              _model.uploadedFileUrl_uploadUpdateManualVoo ==
                                                                  '',
                                                          child: Container(
                                                            height: 50.0,
                                                            constraints:
                                                                BoxConstraints(
                                                              minWidth: 200.0,
                                                              maxWidth: 300.0,
                                                            ),
                                                            decoration:
                                                                BoxDecoration(
                                                              image:
                                                                  DecorationImage(
                                                                fit: BoxFit
                                                                    .contain,
                                                                image:
                                                                    Image.asset(
                                                                  'assets/images/AFM.png',
                                                                ).image,
                                                              ),
                                                            ),
                                                          ),
                                                        );
                                                      } else {
                                                        return Align(
                                                          alignment:
                                                              AlignmentDirectional(
                                                                  0.0, 0.0),
                                                          child: Text(
                                                            _model.uploadedFileUrl_uploadUpdateManualVoo !=
                                                                        null &&
                                                                    _model.uploadedFileUrl_uploadUpdateManualVoo !=
                                                                        ''
                                                                ? valueOrDefault<
                                                                    String>(
                                                                    functions.fileNamePath(
                                                                        _model
                                                                            .uploadedFileUrl_uploadUpdateManualVoo),
                                                                    'arquivo.pdf',
                                                                  )
                                                                : valueOrDefault<
                                                                    String>(
                                                                    functions.fileNamePath(containerVwMyAircraftDetailsRow!
                                                                        .flightManuals!
                                                                        .toString()),
                                                                    'arquivo.pdf',
                                                                  ),
                                                            style: FlutterFlowTheme
                                                                    .of(context)
                                                                .bodyMedium
                                                                .override(
                                                                  font:
                                                                      GoogleFonts
                                                                          .inter(
                                                                    fontWeight: FlutterFlowTheme.of(
                                                                            context)
                                                                        .bodyMedium
                                                                        .fontWeight,
                                                                    fontStyle: FlutterFlowTheme.of(
                                                                            context)
                                                                        .bodyMedium
                                                                        .fontStyle,
                                                                  ),
                                                                  color: FlutterFlowTheme.of(
                                                                          context)
                                                                      .secondaryBackground,
                                                                  letterSpacing:
                                                                      0.0,
                                                                  fontWeight: FlutterFlowTheme.of(
                                                                          context)
                                                                      .bodyMedium
                                                                      .fontWeight,
                                                                  fontStyle: FlutterFlowTheme.of(
                                                                          context)
                                                                      .bodyMedium
                                                                      .fontStyle,
                                                                ),
                                                          ),
                                                        );
                                                      }
                                                    },
                                                  ),
                                                ),
                                              ),
                                              Builder(
                                                builder: (context) {
                                                  if (containerVwMyAircraftDetailsRow
                                                          ?.flightManuals !=
                                                      null) {
                                                    return Row(
                                                      mainAxisSize:
                                                          MainAxisSize.max,
                                                      children: [
                                                        FlutterFlowIconButton(
                                                          borderRadius: 8.0,
                                                          buttonSize: 44.0,
                                                          fillColor:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .primary,
                                                          icon: Icon(
                                                            Icons.check_rounded,
                                                            color: FlutterFlowTheme
                                                                    .of(context)
                                                                .primaryText,
                                                            size: 28.0,
                                                          ),
                                                          onPressed: () {
                                                            print(
                                                                'IconButtonCheckVoo pressed ...');
                                                          },
                                                        ),
                                                        FlutterFlowIconButton(
                                                          borderRadius: 8.0,
                                                          buttonSize: 44.0,
                                                          fillColor:
                                                              Color(0xFF313131),
                                                          icon: Icon(
                                                            Icons.upload_file,
                                                            color: Color(
                                                                0x72FFFFFF),
                                                            size: 28.0,
                                                          ),
                                                          onPressed: () async {
                                                            final selectedFiles =
                                                                await selectFiles(
                                                              storageFolderPath:
                                                                  '',
                                                              allowedExtensions: [
                                                                'pdf'
                                                              ],
                                                              multiFile: false,
                                                            );
                                                            if (selectedFiles !=
                                                                null) {
                                                              safeSetState(() =>
                                                                  _model.isDataUploading_uploadUpdateManualVoo =
                                                                      true);
                                                              var selectedUploadedFiles =
                                                                  <FFUploadedFile>[];

                                                              var downloadUrls =
                                                                  <String>[];
                                                              try {
                                                                selectedUploadedFiles =
                                                                    selectedFiles
                                                                        .map((m) =>
                                                                            FFUploadedFile(
                                                                              name: m.storagePath.split('/').last,
                                                                              bytes: m.bytes,
                                                                              originalFilename: m.originalFilename,
                                                                            ))
                                                                        .toList();

                                                                downloadUrls =
                                                                    await uploadSupabaseStorageFiles(
                                                                  bucketName:
                                                                      'AGSur',
                                                                  selectedFiles:
                                                                      selectedFiles,
                                                                );
                                                              } finally {
                                                                _model.isDataUploading_uploadUpdateManualVoo =
                                                                    false;
                                                              }
                                                              if (selectedUploadedFiles
                                                                          .length ==
                                                                      selectedFiles
                                                                          .length &&
                                                                  downloadUrls
                                                                          .length ==
                                                                      selectedFiles
                                                                          .length) {
                                                                safeSetState(
                                                                    () {
                                                                  _model.uploadedLocalFile_uploadUpdateManualVoo =
                                                                      selectedUploadedFiles
                                                                          .first;
                                                                  _model.uploadedFileUrl_uploadUpdateManualVoo =
                                                                      downloadUrls
                                                                          .first;
                                                                });
                                                              } else {
                                                                safeSetState(
                                                                    () {});
                                                                return;
                                                              }
                                                            }
                                                          },
                                                        ),
                                                      ].divide(
                                                          SizedBox(width: 8.0)),
                                                    );
                                                  } else {
                                                    return FlutterFlowIconButton(
                                                      borderRadius: 8.0,
                                                      buttonSize: 44.0,
                                                      fillColor:
                                                          Color(0xFF313131),
                                                      icon: Icon(
                                                        Icons
                                                            .assignment_outlined,
                                                        color:
                                                            Color(0x72FFFFFF),
                                                        size: 28.0,
                                                      ),
                                                      onPressed: () {
                                                        print(
                                                            'IconButtonVoo pressed ...');
                                                      },
                                                    );
                                                  }
                                                },
                                              ),
                                            ].divide(SizedBox(width: 16.0)),
                                          ),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.max,
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Container(
                                                  height: 50.0,
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8.0),
                                                    border: Border.all(
                                                      color: Color(0x73FFFFFF),
                                                      width: 2.0,
                                                    ),
                                                  ),
                                                  child: Builder(
                                                    builder: (context) {
                                                      if (containerVwMyAircraftDetailsRow
                                                              ?.partsManuals ==
                                                          null) {
                                                        return Visibility(
                                                          visible: _model
                                                                      .uploadedFileUrl_uploadUpdateManualPeca ==
                                                                  null ||
                                                              _model.uploadedFileUrl_uploadUpdateManualPeca ==
                                                                  '',
                                                          child: Container(
                                                            height: 50.0,
                                                            constraints:
                                                                BoxConstraints(
                                                              minWidth: 200.0,
                                                              maxWidth: 300.0,
                                                            ),
                                                            decoration:
                                                                BoxDecoration(
                                                              image:
                                                                  DecorationImage(
                                                                fit: BoxFit
                                                                    .contain,
                                                                image:
                                                                    Image.asset(
                                                                  'assets/images/IPC.png',
                                                                ).image,
                                                              ),
                                                            ),
                                                          ),
                                                        );
                                                      } else {
                                                        return Align(
                                                          alignment:
                                                              AlignmentDirectional(
                                                                  0.0, 0.0),
                                                          child: Text(
                                                            _model.uploadedFileUrl_uploadUpdateManualPeca !=
                                                                        null &&
                                                                    _model.uploadedFileUrl_uploadUpdateManualPeca !=
                                                                        ''
                                                                ? valueOrDefault<
                                                                    String>(
                                                                    functions.fileNamePath(
                                                                        _model
                                                                            .uploadedFileUrl_uploadUpdateManualPeca),
                                                                    'arquivo.pdf',
                                                                  )
                                                                : valueOrDefault<
                                                                    String>(
                                                                    functions.fileNamePath(containerVwMyAircraftDetailsRow!
                                                                        .partsManuals!
                                                                        .toString()),
                                                                    'arquivo.pdf',
                                                                  ),
                                                            style: FlutterFlowTheme
                                                                    .of(context)
                                                                .bodyMedium
                                                                .override(
                                                                  font:
                                                                      GoogleFonts
                                                                          .inter(
                                                                    fontWeight: FlutterFlowTheme.of(
                                                                            context)
                                                                        .bodyMedium
                                                                        .fontWeight,
                                                                    fontStyle: FlutterFlowTheme.of(
                                                                            context)
                                                                        .bodyMedium
                                                                        .fontStyle,
                                                                  ),
                                                                  color: FlutterFlowTheme.of(
                                                                          context)
                                                                      .secondaryBackground,
                                                                  letterSpacing:
                                                                      0.0,
                                                                  fontWeight: FlutterFlowTheme.of(
                                                                          context)
                                                                      .bodyMedium
                                                                      .fontWeight,
                                                                  fontStyle: FlutterFlowTheme.of(
                                                                          context)
                                                                      .bodyMedium
                                                                      .fontStyle,
                                                                ),
                                                          ),
                                                        );
                                                      }
                                                    },
                                                  ),
                                                ),
                                              ),
                                              Builder(
                                                builder: (context) {
                                                  if (containerVwMyAircraftDetailsRow
                                                          ?.partsManuals !=
                                                      null) {
                                                    return Row(
                                                      mainAxisSize:
                                                          MainAxisSize.max,
                                                      children: [
                                                        FlutterFlowIconButton(
                                                          borderRadius: 8.0,
                                                          buttonSize: 44.0,
                                                          fillColor:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .primary,
                                                          icon: Icon(
                                                            Icons.check_rounded,
                                                            color: FlutterFlowTheme
                                                                    .of(context)
                                                                .primaryText,
                                                            size: 28.0,
                                                          ),
                                                          onPressed: () {
                                                            print(
                                                                'IconButtonCheckPeca pressed ...');
                                                          },
                                                        ),
                                                        FlutterFlowIconButton(
                                                          borderRadius: 8.0,
                                                          buttonSize: 44.0,
                                                          fillColor:
                                                              Color(0xFF313131),
                                                          icon: Icon(
                                                            Icons.upload_file,
                                                            color: Color(
                                                                0x72FFFFFF),
                                                            size: 28.0,
                                                          ),
                                                          onPressed: () async {
                                                            final selectedFiles =
                                                                await selectFiles(
                                                              storageFolderPath:
                                                                  '',
                                                              allowedExtensions: [
                                                                'pdf'
                                                              ],
                                                              multiFile: false,
                                                            );
                                                            if (selectedFiles !=
                                                                null) {
                                                              safeSetState(() =>
                                                                  _model.isDataUploading_uploadUpdateManualPeca =
                                                                      true);
                                                              var selectedUploadedFiles =
                                                                  <FFUploadedFile>[];

                                                              var downloadUrls =
                                                                  <String>[];
                                                              try {
                                                                selectedUploadedFiles =
                                                                    selectedFiles
                                                                        .map((m) =>
                                                                            FFUploadedFile(
                                                                              name: m.storagePath.split('/').last,
                                                                              bytes: m.bytes,
                                                                              originalFilename: m.originalFilename,
                                                                            ))
                                                                        .toList();

                                                                downloadUrls =
                                                                    await uploadSupabaseStorageFiles(
                                                                  bucketName:
                                                                      'AGSur',
                                                                  selectedFiles:
                                                                      selectedFiles,
                                                                );
                                                              } finally {
                                                                _model.isDataUploading_uploadUpdateManualPeca =
                                                                    false;
                                                              }
                                                              if (selectedUploadedFiles
                                                                          .length ==
                                                                      selectedFiles
                                                                          .length &&
                                                                  downloadUrls
                                                                          .length ==
                                                                      selectedFiles
                                                                          .length) {
                                                                safeSetState(
                                                                    () {
                                                                  _model.uploadedLocalFile_uploadUpdateManualPeca =
                                                                      selectedUploadedFiles
                                                                          .first;
                                                                  _model.uploadedFileUrl_uploadUpdateManualPeca =
                                                                      downloadUrls
                                                                          .first;
                                                                });
                                                              } else {
                                                                safeSetState(
                                                                    () {});
                                                                return;
                                                              }
                                                            }
                                                          },
                                                        ),
                                                      ].divide(
                                                          SizedBox(width: 8.0)),
                                                    );
                                                  } else {
                                                    return FlutterFlowIconButton(
                                                      borderRadius: 8.0,
                                                      buttonSize: 44.0,
                                                      fillColor:
                                                          Color(0xFF313131),
                                                      icon: Icon(
                                                        Icons
                                                            .assignment_outlined,
                                                        color:
                                                            Color(0x72FFFFFF),
                                                        size: 28.0,
                                                      ),
                                                      onPressed: () {
                                                        print(
                                                            'IconButtonPeca pressed ...');
                                                      },
                                                    );
                                                  }
                                                },
                                              ),
                                            ].divide(SizedBox(width: 16.0)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    16.0, 0.0, 16.0, 16.0),
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
                                        alignment:
                                            AlignmentDirectional(1.0, 0.0),
                                        child: FFButtonWidget(
                                          onPressed: () async {
                                            await AircraftsTable().update(
                                              data: {
                                                'aircraft_model': _model
                                                    .tFAircraftNameTextController
                                                    .text,
                                                'aircraft_description': _model
                                                    .tFDescriptionTextController
                                                    .text,
                                                'hopper':
                                                    valueOrDefault<double>(
                                                  double.tryParse(_model
                                                      .tFAircraftHopperTextController
                                                      .text),
                                                  0.0,
                                                ),
                                                'price': valueOrDefault<double>(
                                                  functions.parsePriceToDouble(
                                                      _model
                                                          .tFPriceTextController
                                                          .text),
                                                  0.0,
                                                ),
                                                'created_by': currentUserUid,
                                              },
                                              matchingRows: (rows) =>
                                                  rows.eqOrNull(
                                                'id',
                                                containerVwMyAircraftDetailsRow
                                                    ?.aircraftId,
                                              ),
                                            );
                                            if (_model.uploadedFileUrl_uploadUpdateAircraft !=
                                                    null &&
                                                _model.uploadedFileUrl_uploadUpdateAircraft !=
                                                    '') {
                                              await AircraftsTable().update(
                                                data: {
                                                  'aircraft_photo_url': _model
                                                      .uploadedFileUrl_uploadUpdateAircraft,
                                                },
                                                matchingRows: (rows) =>
                                                    rows.eqOrNull(
                                                  'id',
                                                  containerVwMyAircraftDetailsRow
                                                      ?.aircraftId,
                                                ),
                                              );
                                            }
                                            if (_model.uploadedFileUrl_uploadUpdateOEM !=
                                                    null &&
                                                _model.uploadedFileUrl_uploadUpdateOEM !=
                                                    '') {
                                              final oemManualId = containerVwMyAircraftDetailsRow?.ownerManuals != null
                                                  ? getJsonField(containerVwMyAircraftDetailsRow?.ownerManuals, r'''$[0].id''')?.toString()
                                                  : null;
                                              if (oemManualId != null && oemManualId != 'null' && oemManualId.isNotEmpty) {
                                                await AircraftManualsTable().update(
                                                  data: {
                                                    'documention_name': valueOrDefault<String>(
                                                      functions.fileNamePath(_model.uploadedFileUrl_uploadUpdateOEM),
                                                      'arquivo.pdf',
                                                    ),
                                                    'documention_url': _model.uploadedFileUrl_uploadUpdateOEM,
                                                    'type': 'Manual do proprietário',
                                                  },
                                                  matchingRows: (rows) => rows.eqOrNull('id', oemManualId),
                                                );
                                              } else {
                                                await AircraftManualsTable().insert({
                                                  'aircraft_id': containerVwMyAircraftDetailsRow?.aircraftId,
                                                  'documention_name': valueOrDefault<String>(
                                                    functions.fileNamePath(_model.uploadedFileUrl_uploadUpdateOEM),
                                                    'arquivo.pdf',
                                                  ),
                                                  'documention_url': _model.uploadedFileUrl_uploadUpdateOEM,
                                                  'type': 'Manual do proprietário',
                                                });
                                              }
                                            }
                                            if (_model.uploadedFileUrl_uploadUpdateManualVoo !=
                                                    null &&
                                                _model.uploadedFileUrl_uploadUpdateManualVoo !=
                                                    '') {
                                              final flightManualId = containerVwMyAircraftDetailsRow?.flightManuals != null
                                                  ? getJsonField(containerVwMyAircraftDetailsRow?.flightManuals, r'''$[0].id''')?.toString()
                                                  : null;
                                              if (flightManualId != null && flightManualId != 'null' && flightManualId.isNotEmpty) {
                                                await AircraftManualsTable().update(
                                                  data: {
                                                    'documention_name': valueOrDefault<String>(
                                                      functions.fileNamePath(_model.uploadedFileUrl_uploadUpdateManualVoo),
                                                      'arquivo.pdf',
                                                    ),
                                                    'documention_url': _model.uploadedFileUrl_uploadUpdateManualVoo,
                                                    'type': 'Manual de voo',
                                                  },
                                                  matchingRows: (rows) => rows.eqOrNull('id', flightManualId),
                                                );
                                              } else {
                                                await AircraftManualsTable().insert({
                                                  'aircraft_id': containerVwMyAircraftDetailsRow?.aircraftId,
                                                  'documention_name': valueOrDefault<String>(
                                                    functions.fileNamePath(_model.uploadedFileUrl_uploadUpdateManualVoo),
                                                    'arquivo.pdf',
                                                  ),
                                                  'documention_url': _model.uploadedFileUrl_uploadUpdateManualVoo,
                                                  'type': 'Manual de voo',
                                                });
                                              }
                                            }
                                            if (_model.uploadedFileUrl_uploadUpdateManualPeca !=
                                                    null &&
                                                _model.uploadedFileUrl_uploadUpdateManualPeca !=
                                                    '') {
                                              final partsManualId = containerVwMyAircraftDetailsRow?.partsManuals != null
                                                  ? getJsonField(containerVwMyAircraftDetailsRow?.partsManuals, r'''$[0].id''')?.toString()
                                                  : null;
                                              if (partsManualId != null && partsManualId != 'null' && partsManualId.isNotEmpty) {
                                                await AircraftManualsTable().update(
                                                  data: {
                                                    'documention_name': valueOrDefault<String>(
                                                      functions.fileNamePath(_model.uploadedFileUrl_uploadUpdateManualPeca),
                                                      'arquivo.pdf',
                                                    ),
                                                    'documention_url': _model.uploadedFileUrl_uploadUpdateManualPeca,
                                                    'type': 'Manual de peças',
                                                  },
                                                  matchingRows: (rows) => rows.eqOrNull('id', partsManualId),
                                                );
                                              } else {
                                                await AircraftManualsTable().insert({
                                                  'aircraft_id': containerVwMyAircraftDetailsRow?.aircraftId,
                                                  'documention_name': valueOrDefault<String>(
                                                    functions.fileNamePath(_model.uploadedFileUrl_uploadUpdateManualPeca),
                                                    'arquivo.pdf',
                                                  ),
                                                  'documention_url': _model.uploadedFileUrl_uploadUpdateManualPeca,
                                                  'type': 'Manual de peças',
                                                });
                                              }
                                            }
                                            _model.isEdit = false;
                                            safeSetState(() {});
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Aeronave editada com sucesso!',
                                                  style: TextStyle(
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .primaryText,
                                                  ),
                                                ),
                                                duration: Duration(
                                                    milliseconds: 4000),
                                                backgroundColor:
                                                    FlutterFlowTheme.of(context)
                                                        .secondary,
                                              ),
                                            );

                                            context.goNamed(
                                              AircraftDetailsWidget.routeName,
                                              queryParameters: {
                                                'aircraftId': serializeParam(
                                                  widget!.aircraftId,
                                                  ParamType.String,
                                                ),
                                              }.withoutNulls,
                                              extra: <String, dynamic>{
                                                '__transition_info__':
                                                    TransitionInfo(
                                                  hasTransition: true,
                                                  transitionType:
                                                      PageTransitionType.fade,
                                                  duration:
                                                      Duration(milliseconds: 0),
                                                ),
                                              },
                                            );

                                            safeSetState(() {});
                                          },
                                          text: 'Salvar Alterações',
                                          options: FFButtonOptions(
                                            height: 48.0,
                                            padding:
                                                EdgeInsetsDirectional.fromSTEB(
                                                    24.0, 0.0, 24.0, 0.0),
                                            iconPadding:
                                                EdgeInsetsDirectional.fromSTEB(
                                                    0.0, 0.0, 0.0, 0.0),
                                            color: FlutterFlowTheme.of(context)
                                                .primary,
                                            textStyle: FlutterFlowTheme.of(
                                                    context)
                                                .titleSmall
                                                .override(
                                                  font: GoogleFonts.roboto(
                                                    fontWeight: FontWeight.w500,
                                                    fontStyle:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .titleSmall
                                                            .fontStyle,
                                                  ),
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .primaryText,
                                                  fontSize: 14.0,
                                                  letterSpacing: 0.0,
                                                  fontWeight: FontWeight.w500,
                                                  fontStyle:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .titleSmall
                                                          .fontStyle,
                                                ),
                                            elevation: 0.0,
                                            borderRadius:
                                                BorderRadius.circular(12.0),
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
                      );
                    },
                  ),
                );
              } else {
                return FutureBuilder<List<VwMyAircraftDetailsRow>>(
                  future: VwMyAircraftDetailsTable().querySingleRow(
                    queryFn: (q) => q.eqOrNull(
                      'aircraft_id',
                      widget!.aircraftId,
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
                    List<VwMyAircraftDetailsRow>
                        cTMainVwMyAircraftDetailsRowList = snapshot.data!;

                    final cTMainVwMyAircraftDetailsRow =
                        cTMainVwMyAircraftDetailsRowList.isNotEmpty
                            ? cTMainVwMyAircraftDetailsRowList.first
                            : null;

                    return Container(
                      decoration: BoxDecoration(),
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                  16.0, 32.0, 16.0, 16.0),
                              child: Container(
                                width: MediaQuery.sizeOf(context).width * 1.0,
                                constraints: BoxConstraints(
                                  maxWidth: 800.0,
                                ),
                                decoration: BoxDecoration(
                                  color: Color(0xFF404040),
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                child: Padding(
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      0.0, 0.0, 0.0, 12.0),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Padding(
                                        padding: EdgeInsets.all(12.0),
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(16.0),
                                          child: Image.network(
                                            valueOrDefault<String>(
                                              cTMainVwMyAircraftDetailsRow
                                                  ?.aircraftPhotoUrl,
                                              'https://bkzybtmxxzpxtztesdye.supabase.co/storage/v1/object/public/AGSur//Design%20sem%20nome%20(13).png',
                                            ),
                                            width: MediaQuery.sizeOf(context)
                                                        .width >
                                                    kBreakpointSmall
                                                ? 800.0
                                                : 330.0,
                                            height: MediaQuery.sizeOf(context)
                                                        .width >
                                                    kBreakpointSmall
                                                ? 450.0
                                                : 186.0,
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: EdgeInsetsDirectional.fromSTEB(
                                            12.0, 0.0, 12.0, 0.0),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.max,
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Align(
                                              alignment: AlignmentDirectional(
                                                  -1.0, 0.0),
                                              child: Padding(
                                                padding: EdgeInsetsDirectional
                                                    .fromSTEB(
                                                        12.0, 12.0, 12.0, 12.0),
                                                child: Text(
                                                  valueOrDefault<String>(
                                                    cTMainVwMyAircraftDetailsRow
                                                        ?.name,
                                                    'Aircraft Name',
                                                  ),
                                                  style: FlutterFlowTheme.of(
                                                          context)
                                                      .bodyMedium
                                                      .override(
                                                        font:
                                                            GoogleFonts.roboto(
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          fontStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .bodyMedium
                                                                  .fontStyle,
                                                        ),
                                                        color: FlutterFlowTheme
                                                                .of(context)
                                                            .secondaryBackground,
                                                        fontSize: 18.0,
                                                        letterSpacing: 0.0,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontStyle:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .bodyMedium
                                                                .fontStyle,
                                                      ),
                                                ),
                                              ),
                                            ),
                                            FlutterFlowIconButton(
                                              borderRadius: 8.0,
                                              buttonSize: 36.0,
                                              fillColor: Color(0xFF313131),
                                              icon: Icon(
                                                Icons.edit,
                                                color: Color(0x72FFFFFF),
                                                size: 20.0,
                                              ),
                                              onPressed: () async {
                                                _model.isEdit = true;
                                                safeSetState(() {});
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                  16.0, 0.0, 16.0, 16.0),
                              child: Container(
                                width: MediaQuery.sizeOf(context).width * 1.0,
                                constraints: BoxConstraints(
                                  maxWidth: 800.0,
                                ),
                                decoration: BoxDecoration(
                                  color: Color(0xFF404040),
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.max,
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Align(
                                          alignment:
                                              AlignmentDirectional(-1.0, 0.0),
                                          child: Padding(
                                            padding: EdgeInsets.all(12.0),
                                            child: Text(
                                              'Descrição',
                                              style: FlutterFlowTheme.of(
                                                      context)
                                                  .bodyMedium
                                                  .override(
                                                    font: GoogleFonts.roboto(
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      fontStyle:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .bodyMedium
                                                              .fontStyle,
                                                    ),
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .secondaryBackground,
                                                    fontSize: 18.0,
                                                    letterSpacing: 0.0,
                                                    fontWeight: FontWeight.w500,
                                                    fontStyle:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .bodyMedium
                                                            .fontStyle,
                                                  ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Align(
                                      alignment:
                                          AlignmentDirectional(-1.0, 0.0),
                                      child: Padding(
                                        padding: EdgeInsets.all(12.0),
                                        child: Text(
                                          valueOrDefault<String>(
                                            cTMainVwMyAircraftDetailsRow
                                                ?.aircraftDescription,
                                            'Sem descrição',
                                          ),
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
                                                color:
                                                    FlutterFlowTheme.of(context)
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
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                  16.0, 0.0, 16.0, 24.0),
                              child: Container(
                                width: MediaQuery.sizeOf(context).width * 1.0,
                                constraints: BoxConstraints(
                                  maxWidth: 800.0,
                                ),
                                decoration: BoxDecoration(
                                  color: Color(0xFF404040),
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          0.0, 0.0, 12.0, 0.0),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.max,
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Align(
                                            alignment:
                                                AlignmentDirectional(-1.0, 0.0),
                                            child: Padding(
                                              padding: EdgeInsets.all(12.0),
                                              child: Text(
                                                'Lista de itens de série',
                                                style: FlutterFlowTheme.of(
                                                        context)
                                                    .bodyMedium
                                                    .override(
                                                      font: GoogleFonts.roboto(
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        fontStyle:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .bodyMedium
                                                                .fontStyle,
                                                      ),
                                                      color: FlutterFlowTheme
                                                              .of(context)
                                                          .secondaryBackground,
                                                      fontSize: 18.0,
                                                      letterSpacing: 0.0,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      fontStyle:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .bodyMedium
                                                              .fontStyle,
                                                    ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          0.0, 8.0, 0.0, 0.0),
                                      child: Builder(
                                        builder: (context) {
                                          final listaItensSerie =
                                              cTMainVwMyAircraftDetailsRow
                                                      ?.itemsSeries
                                                      ?.toList() ??
                                                  [];

                                          return Column(
                                            mainAxisSize: MainAxisSize.max,
                                            children: List.generate(
                                                listaItensSerie.length,
                                                (listaItensSerieIndex) {
                                              final listaItensSerieItem =
                                                  listaItensSerie[
                                                      listaItensSerieIndex];
                                              return Container(
                                                decoration: BoxDecoration(),
                                                child: Padding(
                                                  padding: EdgeInsetsDirectional
                                                      .fromSTEB(
                                                          12.0, 0.0, 12.0, 8.0),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.max,
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Align(
                                                        alignment:
                                                            AlignmentDirectional(
                                                                -1.0, 0.0),
                                                        child: RichText(
                                                          textScaler:
                                                              MediaQuery.of(
                                                                      context)
                                                                  .textScaler,
                                                          text: TextSpan(
                                                            children: [
                                                              TextSpan(
                                                                text: 'Item',
                                                                style: FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .override(
                                                                      font: GoogleFonts
                                                                          .inter(
                                                                        fontWeight:
                                                                            FontWeight.normal,
                                                                        fontStyle: FlutterFlowTheme.of(context)
                                                                            .bodyMedium
                                                                            .fontStyle,
                                                                      ),
                                                                      color: FlutterFlowTheme.of(
                                                                              context)
                                                                          .secondaryBackground,
                                                                      fontSize:
                                                                          14.0,
                                                                      letterSpacing:
                                                                          0.0,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .normal,
                                                                      fontStyle: FlutterFlowTheme.of(
                                                                              context)
                                                                          .bodyMedium
                                                                          .fontStyle,
                                                                    ),
                                                              ),
                                                              TextSpan(
                                                                text: ' / ',
                                                                style:
                                                                    TextStyle(
                                                                  color: FlutterFlowTheme.of(
                                                                          context)
                                                                      .secondaryBackground,
                                                                  fontSize:
                                                                      16.0,
                                                                ),
                                                              ),
                                                              TextSpan(
                                                                text:
                                                                    valueOrDefault<
                                                                        String>(
                                                                  getJsonField(
                                                                    listaItensSerieItem,
                                                                    r'''$.item_name''',
                                                                  )?.toString(),
                                                                  'Nome do item',
                                                                ),
                                                                style:
                                                                    TextStyle(
                                                                  color: Color(
                                                                      0x72FFFFFF),
                                                                  fontSize:
                                                                      14.0,
                                                                ),
                                                              )
                                                            ],
                                                            style: FlutterFlowTheme
                                                                    .of(context)
                                                                .bodyMedium
                                                                .override(
                                                                  font:
                                                                      GoogleFonts
                                                                          .inter(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .normal,
                                                                    fontStyle: FlutterFlowTheme.of(
                                                                            context)
                                                                        .bodyMedium
                                                                        .fontStyle,
                                                                  ),
                                                                  color: FlutterFlowTheme.of(
                                                                          context)
                                                                      .secondaryBackground,
                                                                  fontSize:
                                                                      14.0,
                                                                  letterSpacing:
                                                                      0.0,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .normal,
                                                                  fontStyle: FlutterFlowTheme.of(
                                                                          context)
                                                                      .bodyMedium
                                                                      .fontStyle,
                                                                ),
                                                          ),
                                                        ),
                                                      ),
                                                      Align(
                                                        alignment:
                                                            AlignmentDirectional(
                                                                -1.0, 0.0),
                                                        child: RichText(
                                                          textScaler:
                                                              MediaQuery.of(
                                                                      context)
                                                                  .textScaler,
                                                          text: TextSpan(
                                                            children: [
                                                              TextSpan(
                                                                text: 'Qtd:',
                                                                style: FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .override(
                                                                      font: GoogleFonts
                                                                          .inter(
                                                                        fontWeight:
                                                                            FontWeight.normal,
                                                                        fontStyle: FlutterFlowTheme.of(context)
                                                                            .bodyMedium
                                                                            .fontStyle,
                                                                      ),
                                                                      color: FlutterFlowTheme.of(
                                                                              context)
                                                                          .secondaryBackground,
                                                                      fontSize:
                                                                          14.0,
                                                                      letterSpacing:
                                                                          0.0,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .normal,
                                                                      fontStyle: FlutterFlowTheme.of(
                                                                              context)
                                                                          .bodyMedium
                                                                          .fontStyle,
                                                                    ),
                                                              ),
                                                              TextSpan(
                                                                text: ' ',
                                                                style:
                                                                    TextStyle(),
                                                              ),
                                                              TextSpan(
                                                                text:
                                                                    valueOrDefault<
                                                                        String>(
                                                                  getJsonField(
                                                                    listaItensSerieItem,
                                                                    r'''$.qty''',
                                                                  )?.toString(),
                                                                  '0',
                                                                ),
                                                                style:
                                                                    TextStyle(
                                                                  color: Color(
                                                                      0x72FFFFFF),
                                                                  fontSize:
                                                                      14.0,
                                                                ),
                                                              )
                                                            ],
                                                            style: FlutterFlowTheme
                                                                    .of(context)
                                                                .bodyMedium
                                                                .override(
                                                                  font:
                                                                      GoogleFonts
                                                                          .inter(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .normal,
                                                                    fontStyle: FlutterFlowTheme.of(
                                                                            context)
                                                                        .bodyMedium
                                                                        .fontStyle,
                                                                  ),
                                                                  color: FlutterFlowTheme.of(
                                                                          context)
                                                                      .secondaryBackground,
                                                                  fontSize:
                                                                      14.0,
                                                                  letterSpacing:
                                                                      0.0,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .normal,
                                                                  fontStyle: FlutterFlowTheme.of(
                                                                          context)
                                                                      .bodyMedium
                                                                      .fontStyle,
                                                                ),
                                                          ),
                                                        ),
                                                      ),
                                                    ].divide(
                                                        SizedBox(width: 48.0)),
                                                  ),
                                                ),
                                              );
                                            }).divide(SizedBox(height: 8.0)),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Align(
                              alignment: AlignmentDirectional(0.0, 0.0),
                              child: Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    0.0, 16.0, 0.0, 0.0),
                                child: Wrap(
                                  spacing: 0.0,
                                  runSpacing: 12.0,
                                  alignment: WrapAlignment.start,
                                  crossAxisAlignment: WrapCrossAlignment.start,
                                  direction: Axis.horizontal,
                                  runAlignment: WrapAlignment.start,
                                  verticalDirection: VerticalDirection.down,
                                  clipBehavior: Clip.none,
                                  children: [
                                    if (cTMainVwMyAircraftDetailsRow
                                            ?.ownerManuals !=
                                        null)
                                      Padding(
                                        padding: EdgeInsetsDirectional.fromSTEB(
                                            8.0, 0.0, 8.0, 0.0),
                                        child: FFButtonWidget(
                                          onPressed: () async {
                                            final manualUrl = getJsonField(
                                              cTMainVwMyAircraftDetailsRow!
                                                  .ownerManuals!,
                                              r'''$[0].documention_url''',
                                            )?.toString() ?? '';
                                            if (manualUrl.isNotEmpty && manualUrl != 'null' && manualUrl.startsWith('http')) {
                                              await launchURL(manualUrl);
                                            } else {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text('URL do manual não disponível'),
                                                  backgroundColor: FlutterFlowTheme.of(context).error,
                                                ),
                                              );
                                            }
                                          },
                                          text: 'Manual do proprietário',
                                          options: FFButtonOptions(
                                            width: () {
                                              if (MediaQuery.sizeOf(context)
                                                      .width >=
                                                  kBreakpointSmall) {
                                                return 250.0;
                                              } else if (MediaQuery.sizeOf(
                                                          context)
                                                      .width >
                                                  kBreakpointMedium) {
                                                return 350.0;
                                              } else {
                                                return 350.0;
                                              }
                                            }(),
                                            height: 50.0,
                                            padding:
                                                EdgeInsetsDirectional.fromSTEB(
                                                    24.0, 0.0, 24.0, 0.0),
                                            iconPadding:
                                                EdgeInsetsDirectional.fromSTEB(
                                                    0.0, 0.0, 0.0, 0.0),
                                            color: FlutterFlowTheme.of(context)
                                                .primary,
                                            textStyle: FlutterFlowTheme.of(
                                                    context)
                                                .titleSmall
                                                .override(
                                                  font: GoogleFonts.roboto(
                                                    fontWeight: FontWeight.w500,
                                                    fontStyle:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .titleSmall
                                                            .fontStyle,
                                                  ),
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .primaryText,
                                                  fontSize: 16.0,
                                                  letterSpacing: 0.0,
                                                  fontWeight: FontWeight.w500,
                                                  fontStyle:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .titleSmall
                                                          .fontStyle,
                                                ),
                                            elevation: 0.0,
                                            borderRadius:
                                                BorderRadius.circular(12.0),
                                          ),
                                        ),
                                      ),
                                    if (cTMainVwMyAircraftDetailsRow
                                            ?.flightManuals !=
                                        null)
                                    Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          8.0, 0.0, 8.0, 0.0),
                                      child: FFButtonWidget(
                                        onPressed: () async {
                                          final flightUrl = getJsonField(
                                            cTMainVwMyAircraftDetailsRow!
                                                .flightManuals!,
                                            r'''$[0].documention_url''',
                                          )?.toString() ?? '';
                                          if (flightUrl.isNotEmpty && flightUrl != 'null' && flightUrl.startsWith('http')) {
                                            await launchURL(flightUrl);
                                          } else {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('URL do manual não disponível'),
                                                backgroundColor: FlutterFlowTheme.of(context).error,
                                              ),
                                            );
                                          }
                                        },
                                        text: 'Manual de voo',
                                        options: FFButtonOptions(
                                          width: () {
                                            if (MediaQuery.sizeOf(context)
                                                    .width >=
                                                kBreakpointSmall) {
                                              return 250.0;
                                            } else if (MediaQuery.sizeOf(
                                                        context)
                                                    .width >
                                                kBreakpointMedium) {
                                              return 350.0;
                                            } else {
                                              return 350.0;
                                            }
                                          }(),
                                          height: 50.0,
                                          padding:
                                              EdgeInsetsDirectional.fromSTEB(
                                                  24.0, 0.0, 24.0, 0.0),
                                          iconPadding:
                                              EdgeInsetsDirectional.fromSTEB(
                                                  0.0, 0.0, 0.0, 0.0),
                                          color: FlutterFlowTheme.of(context)
                                              .primary,
                                          textStyle: FlutterFlowTheme.of(
                                                  context)
                                              .titleSmall
                                              .override(
                                                font: GoogleFonts.roboto(
                                                  fontWeight: FontWeight.w500,
                                                  fontStyle:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .titleSmall
                                                          .fontStyle,
                                                ),
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .primaryText,
                                                fontSize: 16.0,
                                                letterSpacing: 0.0,
                                                fontWeight: FontWeight.w500,
                                                fontStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .titleSmall
                                                        .fontStyle,
                                              ),
                                          elevation: 0.0,
                                          borderRadius:
                                              BorderRadius.circular(12.0),
                                        ),
                                      ),
                                    ),
                                    if (cTMainVwMyAircraftDetailsRow
                                            ?.partsManuals !=
                                        null)
                                    Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          8.0, 0.0, 8.0, 0.0),
                                      child: FFButtonWidget(
                                        onPressed: () async {
                                          final partsUrl = getJsonField(
                                            cTMainVwMyAircraftDetailsRow!
                                                .partsManuals!,
                                            r'''$[0].documention_url''',
                                          )?.toString() ?? '';
                                          if (partsUrl.isNotEmpty && partsUrl != 'null' && partsUrl.startsWith('http')) {
                                            await launchURL(partsUrl);
                                          } else {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('URL do manual não disponível'),
                                                backgroundColor: FlutterFlowTheme.of(context).error,
                                              ),
                                            );
                                          }
                                        },
                                        text: 'Manual de peças',
                                        options: FFButtonOptions(
                                          width: () {
                                            if (MediaQuery.sizeOf(context)
                                                    .width >=
                                                kBreakpointSmall) {
                                              return 250.0;
                                            } else if (MediaQuery.sizeOf(
                                                        context)
                                                    .width >
                                                kBreakpointMedium) {
                                              return 350.0;
                                            } else {
                                              return 350.0;
                                            }
                                          }(),
                                          height: 50.0,
                                          padding:
                                              EdgeInsetsDirectional.fromSTEB(
                                                  24.0, 0.0, 24.0, 0.0),
                                          iconPadding:
                                              EdgeInsetsDirectional.fromSTEB(
                                                  0.0, 0.0, 0.0, 0.0),
                                          color: FlutterFlowTheme.of(context)
                                              .primary,
                                          textStyle: FlutterFlowTheme.of(
                                                  context)
                                              .titleSmall
                                              .override(
                                                font: GoogleFonts.roboto(
                                                  fontWeight: FontWeight.w500,
                                                  fontStyle:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .titleSmall
                                                          .fontStyle,
                                                ),
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .primaryText,
                                                fontSize: 16.0,
                                                letterSpacing: 0.0,
                                                fontWeight: FontWeight.w500,
                                                fontStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .titleSmall
                                                        .fontStyle,
                                              ),
                                          elevation: 0.0,
                                          borderRadius:
                                              BorderRadius.circular(12.0),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ]
                              .divide(SizedBox(height: 16.0))
                              .addToEnd(SizedBox(height: 32.0)),
                        ),
                      ),
                    );
                  },
                );
              }
            },
          ),
        ),
      ),
    );
  }
}
