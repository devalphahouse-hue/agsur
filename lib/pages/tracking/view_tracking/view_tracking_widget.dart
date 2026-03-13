import '/backend/api_requests/api_calls.dart';
import '/backend/schema/structs/index.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/pages/modal_tracking/modal_tracking_widget.dart';
import '/pages/shared/alert_dialog/alert_dialog_widget.dart';
import 'dart:ui';
import '/index.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '/auth/supabase_auth/auth_util.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
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

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ViewTrackingModel());

    SchedulerBinding.instance.addPostFrameCallback((_) async {
      _model.user = await UsersTable().queryRows(
        queryFn: (q) => q.eqOrNull('id', currentUserUid),
      );
      safeSetState(() {});
    });

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
            'Rastreamento',
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
          child: FutureBuilder<ApiCallResponse>(
            future: (_model.apiRequestCompleter ??= Completer<ApiCallResponse>()
                  ..complete(GetTrackingCall.call(
                    pAircraftId: widget!.userAircraftId,
                  )))
                .future,
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
              final containerGetTrackingResponse = snapshot.data!;

              return Container(
                width: MediaQuery.sizeOf(context).width * 1.0,
                decoration: BoxDecoration(),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Align(
                        alignment: AlignmentDirectional(-1.0, 0.0),
                        child: Padding(
                          padding: EdgeInsetsDirectional.fromSTEB(
                              36.0, 12.0, 36.0, 12.0),
                          child: Text(
                            'Etapas do rastreamento',
                            style: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .override(
                                  font: GoogleFonts.inter(
                                    fontWeight: FontWeight.w500,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontStyle,
                                  ),
                                  color: FlutterFlowTheme.of(context)
                                      .secondaryBackground,
                                  fontSize: 20.0,
                                  letterSpacing: 0.0,
                                  fontWeight: FontWeight.w500,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .fontStyle,
                                ),
                          ),
                        ),
                      ),
                      Align(
                        alignment: AlignmentDirectional(0.0, 0.0),
                        child: Padding(
                          padding: EdgeInsetsDirectional.fromSTEB(
                              12.0, 12.0, 12.0, 12.0),
                          child: Builder(
                            builder: (context) {
                              final listTracking =
                                  GetTrackingStruct.maybeFromMap(
                                              containerGetTrackingResponse
                                                  .jsonBody)
                                          ?.tracking
                                          ?.toList() ??
                                      [];

                              return Wrap(
                                spacing: 28.0,
                                runSpacing: 28.0,
                                alignment: WrapAlignment.start,
                                crossAxisAlignment: WrapCrossAlignment.start,
                                direction: Axis.horizontal,
                                runAlignment: WrapAlignment.start,
                                verticalDirection: VerticalDirection.down,
                                clipBehavior: Clip.none,
                                children: List.generate(listTracking.length,
                                    (listTrackingIndex) {
                                  final listTrackingItem =
                                      listTracking[listTrackingIndex];
                                  return Material(
                                    color: Colors.transparent,
                                    elevation: 0.0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12.0),
                                    ),
                                    child: Container(
                                      constraints: BoxConstraints(
                                        minWidth: 300.0,
                                        maxWidth: 430.0,
                                      ),
                                      decoration: BoxDecoration(
                                        color: valueOrDefault<Color>(
                                          listTrackingItem.isCheck
                                              ? Color(0xFF68896E)
                                              : Color(0xFF404040),
                                          Color(0xFF404040),
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(12.0),
                                        border: Border.all(
                                          color: Color(0xFF404040),
                                          width: 0.0,
                                        ),
                                      ),
                                      child: Padding(
                                        padding: EdgeInsetsDirectional.fromSTEB(
                                            12.0, 24.0, 12.0, 24.0),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Align(
                                              alignment: AlignmentDirectional(
                                                  0.0, 0.0),
                                              child: Padding(
                                                padding: EdgeInsetsDirectional
                                                    .fromSTEB(
                                                        0.0, 0.0, 0.0, 8.0),
                                                child: Text(
                                                  listTrackingItem
                                                      .trackingDescription,
                                                  style: FlutterFlowTheme.of(
                                                          context)
                                                      .bodyMedium
                                                      .override(
                                                        font:
                                                            GoogleFonts.roboto(
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
                                              color: Color(0x72FFFFFF),
                                            ),
                                            Padding(
                                              padding: EdgeInsetsDirectional
                                                  .fromSTEB(
                                                      0.0, 12.0, 0.0, 0.0),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.max,
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Column(
                                                    mainAxisSize:
                                                        MainAxisSize.max,
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.start,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .center,
                                                    children: [
                                                      Builder(
                                                        builder: (context) {
                                                          if (((int.tryParse(listTrackingItem.order) ?? -1) == 0) ||
                                                              ((int.tryParse(listTrackingItem.order) ?? -1) ==
                                                                  8) ||
                                                              ((int.tryParse(listTrackingItem.order) ?? -1) ==
                                                                  11) ||
                                                              ((int.tryParse(listTrackingItem.order) ?? -1) ==
                                                                  13) ||
                                                              ((int.tryParse(listTrackingItem.order) ?? -1) ==
                                                                  16) ||
                                                              ((int.tryParse(listTrackingItem.order) ?? -1) ==
                                                                  17)) {
                                                            return FlutterFlowIconButton(
                                                              borderRadius: 8.0,
                                                              buttonSize: 55.0,
                                                              fillColor:
                                                                  valueOrDefault<
                                                                      Color>(
                                                                listTrackingItem
                                                                        .isCheck
                                                                    ? Color(
                                                                        0xFF14471E)
                                                                    : FlutterFlowTheme.of(
                                                                            context)
                                                                        .primary,
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .primary,
                                                              ),
                                                              icon: Icon(
                                                                Icons.list_alt,
                                                                color:
                                                                    valueOrDefault<
                                                                        Color>(
                                                                  listTrackingItem.isCheck
                                                                      ? FlutterFlowTheme.of(
                                                                              context)
                                                                          .secondaryBackground
                                                                      : FlutterFlowTheme.of(
                                                                              context)
                                                                          .primaryText,
                                                                  FlutterFlowTheme.of(
                                                                          context)
                                                                      .primaryText,
                                                                ),
                                                                size: 24.0,
                                                              ),
                                                              onPressed: () {
                                                                print(
                                                                    'ICPainelList pressed ...');
                                                              },
                                                            );
                                                          } else if ((int.tryParse(listTrackingItem.order) ?? -1) ==
                                                              1) {
                                                            return FlutterFlowIconButton(
                                                              borderRadius: 8.0,
                                                              buttonSize: 55.0,
                                                              fillColor:
                                                                  valueOrDefault<
                                                                      Color>(
                                                                listTrackingItem
                                                                        .isCheck
                                                                    ? Color(
                                                                        0xFF14471E)
                                                                    : FlutterFlowTheme.of(
                                                                            context)
                                                                        .primary,
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .primary,
                                                              ),
                                                              icon: Icon(
                                                                Icons
                                                                    .airplanemode_active_sharp,
                                                                color:
                                                                    valueOrDefault<
                                                                        Color>(
                                                                  listTrackingItem.isCheck
                                                                      ? FlutterFlowTheme.of(
                                                                              context)
                                                                          .secondaryBackground
                                                                      : FlutterFlowTheme.of(
                                                                              context)
                                                                          .primaryText,
                                                                  FlutterFlowTheme.of(
                                                                          context)
                                                                      .primaryText,
                                                                ),
                                                                size: 24.0,
                                                              ),
                                                              onPressed: () {
                                                                print(
                                                                    'ICPainelAirplane pressed ...');
                                                              },
                                                            );
                                                          } else if ((int.tryParse(listTrackingItem.order) ?? -1) ==
                                                              2) {
                                                            return FlutterFlowIconButton(
                                                              borderRadius: 8.0,
                                                              buttonSize: 55.0,
                                                              fillColor:
                                                                  valueOrDefault<
                                                                      Color>(
                                                                listTrackingItem
                                                                        .isCheck
                                                                    ? Color(
                                                                        0xFF14471E)
                                                                    : FlutterFlowTheme.of(
                                                                            context)
                                                                        .primary,
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .primary,
                                                              ),
                                                              icon: Icon(
                                                                Icons
                                                                    .border_color,
                                                                color:
                                                                    valueOrDefault<
                                                                        Color>(
                                                                  listTrackingItem.isCheck
                                                                      ? FlutterFlowTheme.of(
                                                                              context)
                                                                          .secondaryBackground
                                                                      : FlutterFlowTheme.of(
                                                                              context)
                                                                          .primaryText,
                                                                  FlutterFlowTheme.of(
                                                                          context)
                                                                      .primaryText,
                                                                ),
                                                                size: 24.0,
                                                              ),
                                                              onPressed: () {
                                                                print(
                                                                    'ICPainelBorderColor pressed ...');
                                                              },
                                                            );
                                                          } else if ((int.tryParse(listTrackingItem.order) ?? -1) ==
                                                              3) {
                                                            return FlutterFlowIconButton(
                                                              borderRadius: 8.0,
                                                              buttonSize: 55.0,
                                                              fillColor:
                                                                  valueOrDefault<
                                                                      Color>(
                                                                listTrackingItem
                                                                        .isCheck
                                                                    ? Color(
                                                                        0xFF14471E)
                                                                    : FlutterFlowTheme.of(
                                                                            context)
                                                                        .primary,
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .primary,
                                                              ),
                                                              icon: Icon(
                                                                Icons
                                                                    .laptop_chromebook_sharp,
                                                                color:
                                                                    valueOrDefault<
                                                                        Color>(
                                                                  listTrackingItem.isCheck
                                                                      ? FlutterFlowTheme.of(
                                                                              context)
                                                                          .secondaryBackground
                                                                      : FlutterFlowTheme.of(
                                                                              context)
                                                                          .primaryText,
                                                                  FlutterFlowTheme.of(
                                                                          context)
                                                                      .primaryText,
                                                                ),
                                                                size: 24.0,
                                                              ),
                                                              onPressed: () {
                                                                print(
                                                                    'ICPainelNotebook pressed ...');
                                                              },
                                                            );
                                                          } else if (((int.tryParse(listTrackingItem.order) ?? -1) == 4) ||
                                                              ((int.tryParse(listTrackingItem.order) ?? -1) ==
                                                                  5) ||
                                                              ((int.tryParse(listTrackingItem.order) ?? -1) ==
                                                                  12)) {
                                                            return FlutterFlowIconButton(
                                                              borderRadius: 8.0,
                                                              buttonSize: 55.0,
                                                              fillColor:
                                                                  valueOrDefault<
                                                                      Color>(
                                                                listTrackingItem
                                                                        .isCheck
                                                                    ? Color(
                                                                        0xFF14471E)
                                                                    : FlutterFlowTheme.of(
                                                                            context)
                                                                        .primary,
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .primary,
                                                              ),
                                                              icon: Icon(
                                                                Icons
                                                                    .monetization_on_outlined,
                                                                color:
                                                                    valueOrDefault<
                                                                        Color>(
                                                                  listTrackingItem.isCheck
                                                                      ? FlutterFlowTheme.of(
                                                                              context)
                                                                          .secondaryBackground
                                                                      : FlutterFlowTheme.of(
                                                                              context)
                                                                          .primaryText,
                                                                  FlutterFlowTheme.of(
                                                                          context)
                                                                      .primaryText,
                                                                ),
                                                                size: 24.0,
                                                              ),
                                                              onPressed: () {
                                                                print(
                                                                    'ICPainelMoney pressed ...');
                                                              },
                                                            );
                                                          } else if (((int.tryParse(listTrackingItem.order) ?? -1) ==
                                                                  6) ||
                                                              ((int.tryParse(listTrackingItem.order) ?? -1) ==
                                                                  10)) {
                                                            return FlutterFlowIconButton(
                                                              borderRadius: 8.0,
                                                              buttonSize: 55.0,
                                                              fillColor:
                                                                  valueOrDefault<
                                                                      Color>(
                                                                listTrackingItem
                                                                        .isCheck
                                                                    ? Color(
                                                                        0xFF14471E)
                                                                    : FlutterFlowTheme.of(
                                                                            context)
                                                                        .primary,
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .primary,
                                                              ),
                                                              icon: Icon(
                                                                Icons
                                                                    .library_books_outlined,
                                                                color:
                                                                    valueOrDefault<
                                                                        Color>(
                                                                  listTrackingItem.isCheck
                                                                      ? FlutterFlowTheme.of(
                                                                              context)
                                                                          .secondaryBackground
                                                                      : FlutterFlowTheme.of(
                                                                              context)
                                                                          .primaryText,
                                                                  FlutterFlowTheme.of(
                                                                          context)
                                                                      .primaryText,
                                                                ),
                                                                size: 24.0,
                                                              ),
                                                              onPressed: () {
                                                                print(
                                                                    'ICPainelLibrary pressed ...');
                                                              },
                                                            );
                                                          } else if ((int.tryParse(listTrackingItem.order) ?? -1) ==
                                                              7) {
                                                            return FlutterFlowIconButton(
                                                              borderRadius: 8.0,
                                                              buttonSize: 55.0,
                                                              fillColor:
                                                                  valueOrDefault<
                                                                      Color>(
                                                                listTrackingItem
                                                                        .isCheck
                                                                    ? Color(
                                                                        0xFF14471E)
                                                                    : FlutterFlowTheme.of(
                                                                            context)
                                                                        .primary,
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .primary,
                                                              ),
                                                              icon: Icon(
                                                                Icons
                                                                    .history_sharp,
                                                                color:
                                                                    valueOrDefault<
                                                                        Color>(
                                                                  listTrackingItem.isCheck
                                                                      ? FlutterFlowTheme.of(
                                                                              context)
                                                                          .secondaryBackground
                                                                      : FlutterFlowTheme.of(
                                                                              context)
                                                                          .primaryText,
                                                                  FlutterFlowTheme.of(
                                                                          context)
                                                                      .primaryText,
                                                                ),
                                                                size: 24.0,
                                                              ),
                                                              onPressed: () {
                                                                print(
                                                                    'ICPainelHistory pressed ...');
                                                              },
                                                            );
                                                          } else if ((int.tryParse(listTrackingItem.order) ?? -1) ==
                                                              9) {
                                                            return FlutterFlowIconButton(
                                                              borderRadius: 8.0,
                                                              buttonSize: 55.0,
                                                              fillColor:
                                                                  valueOrDefault<
                                                                      Color>(
                                                                listTrackingItem
                                                                        .isCheck
                                                                    ? Color(
                                                                        0xFF14471E)
                                                                    : FlutterFlowTheme.of(
                                                                            context)
                                                                        .primary,
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .primary,
                                                              ),
                                                              icon: Icon(
                                                                Icons
                                                                    .numbers_rounded,
                                                                color:
                                                                    valueOrDefault<
                                                                        Color>(
                                                                  listTrackingItem.isCheck
                                                                      ? FlutterFlowTheme.of(
                                                                              context)
                                                                          .secondaryBackground
                                                                      : FlutterFlowTheme.of(
                                                                              context)
                                                                          .primaryText,
                                                                  FlutterFlowTheme.of(
                                                                          context)
                                                                      .primaryText,
                                                                ),
                                                                size: 24.0,
                                                              ),
                                                              onPressed: () {
                                                                print(
                                                                    'ICPainelNumber pressed ...');
                                                              },
                                                            );
                                                          } else if ((int.tryParse(listTrackingItem.order) ?? -1) ==
                                                              14) {
                                                            return FlutterFlowIconButton(
                                                              borderRadius: 8.0,
                                                              buttonSize: 55.0,
                                                              fillColor:
                                                                  valueOrDefault<
                                                                      Color>(
                                                                listTrackingItem
                                                                        .isCheck
                                                                    ? Color(
                                                                        0xFF14471E)
                                                                    : FlutterFlowTheme.of(
                                                                            context)
                                                                        .primary,
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .primary,
                                                              ),
                                                              icon: Icon(
                                                                Icons.link,
                                                                color:
                                                                    valueOrDefault<
                                                                        Color>(
                                                                  listTrackingItem.isCheck
                                                                      ? FlutterFlowTheme.of(
                                                                              context)
                                                                          .secondaryBackground
                                                                      : FlutterFlowTheme.of(
                                                                              context)
                                                                          .primaryText,
                                                                  FlutterFlowTheme.of(
                                                                          context)
                                                                      .primaryText,
                                                                ),
                                                                size: 24.0,
                                                              ),
                                                              onPressed: () {
                                                                print(
                                                                    'ICPainelLink pressed ...');
                                                              },
                                                            );
                                                          } else {
                                                            return FlutterFlowIconButton(
                                                              borderRadius: 8.0,
                                                              buttonSize: 55.0,
                                                              fillColor:
                                                                  valueOrDefault<
                                                                      Color>(
                                                                listTrackingItem
                                                                        .isCheck
                                                                    ? Color(
                                                                        0xFF14471E)
                                                                    : FlutterFlowTheme.of(
                                                                            context)
                                                                        .primary,
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .primary,
                                                              ),
                                                              icon: Icon(
                                                                Icons.check,
                                                                color:
                                                                    valueOrDefault<
                                                                        Color>(
                                                                  listTrackingItem.isCheck
                                                                      ? FlutterFlowTheme.of(
                                                                              context)
                                                                          .secondaryBackground
                                                                      : FlutterFlowTheme.of(
                                                                              context)
                                                                          .primaryText,
                                                                  FlutterFlowTheme.of(
                                                                          context)
                                                                      .primaryText,
                                                                ),
                                                                size: 24.0,
                                                              ),
                                                              onPressed: () {
                                                                print(
                                                                    'ICPainelCheck pressed ...');
                                                              },
                                                            );
                                                          }
                                                        },
                                                      ),
                                                    ].divide(
                                                        SizedBox(height: 8.0)),
                                                  ),
                                                  Column(
                                                    mainAxisSize:
                                                        MainAxisSize.max,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment.end,
                                                    children: [
                                                      Align(
                                                        alignment:
                                                            AlignmentDirectional(
                                                                -1.0, 0.0),
                                                        child: Padding(
                                                          padding:
                                                              EdgeInsetsDirectional
                                                                  .fromSTEB(
                                                                      12.0,
                                                                      0.0,
                                                                      12.0,
                                                                      0.0),
                                                          child: Text(
                                                            'ID',
                                                            style: FlutterFlowTheme
                                                                    .of(context)
                                                                .bodyMedium
                                                                .override(
                                                                  font: GoogleFonts
                                                                      .roboto(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .normal,
                                                                    fontStyle: FlutterFlowTheme.of(
                                                                            context)
                                                                        .bodyMedium
                                                                        .fontStyle,
                                                                  ),
                                                                  color: Color(
                                                                      0x72FFFFFF),
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
                                                        child: Padding(
                                                          padding:
                                                              EdgeInsetsDirectional
                                                                  .fromSTEB(
                                                                      12.0,
                                                                      0.0,
                                                                      12.0,
                                                                      8.0),
                                                          child: Text(
                                                            valueOrDefault<
                                                                String>(
                                                              GetTrackingStruct
                                                                      .maybeFromMap(
                                                                          containerGetTrackingResponse
                                                                              .jsonBody)
                                                                  ?.trackProposal
                                                                  ?.idRef,
                                                              '#000000',
                                                            ),
                                                            style: FlutterFlowTheme
                                                                    .of(context)
                                                                .bodyMedium
                                                                .override(
                                                                  font: GoogleFonts
                                                                      .roboto(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w500,
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
                                                                          .w500,
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
                                                        child: Padding(
                                                          padding:
                                                              EdgeInsetsDirectional
                                                                  .fromSTEB(
                                                                      12.0,
                                                                      0.0,
                                                                      12.0,
                                                                      0.0),
                                                          child: Text(
                                                            'Nome do cliente',
                                                            style: FlutterFlowTheme
                                                                    .of(context)
                                                                .bodyMedium
                                                                .override(
                                                                  font: GoogleFonts
                                                                      .roboto(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .normal,
                                                                    fontStyle: FlutterFlowTheme.of(
                                                                            context)
                                                                        .bodyMedium
                                                                        .fontStyle,
                                                                  ),
                                                                  color: Color(
                                                                      0x72FFFFFF),
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
                                                        child: Padding(
                                                          padding:
                                                              EdgeInsetsDirectional
                                                                  .fromSTEB(
                                                                      12.0,
                                                                      0.0,
                                                                      12.0,
                                                                      12.0),
                                                          child: Text(
                                                            valueOrDefault<
                                                                String>(
                                                              GetTrackingStruct
                                                                      .maybeFromMap(
                                                                          containerGetTrackingResponse
                                                                              .jsonBody)
                                                                  ?.trackCompany
                                                                  ?.companyName,
                                                              'Não cadastrado',
                                                            ),
                                                            style: FlutterFlowTheme
                                                                    .of(context)
                                                                .bodyMedium
                                                                .override(
                                                                  font: GoogleFonts
                                                                      .roboto(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w500,
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
                                                                          .w500,
                                                                  fontStyle: FlutterFlowTheme.of(
                                                                          context)
                                                                      .bodyMedium
                                                                      .fontStyle,
                                                                ),
                                                          ),
                                                        ),
                                                      ),
                                                      if (((int.tryParse(listTrackingItem.order) ?? -1) ==
                                                              15) &&
                                                          (valueOrDefault<
                                                                      String>(
                                                                    listTrackingItem.link,
                                                                    'Não cadastrado',
                                                                  ) !=
                                                                  null &&
                                                              valueOrDefault<
                                                                      String>(
                                                                    listTrackingItem.link,
                                                                    'Não cadastrado',
                                                                  ) !=
                                                                  ''))
                                                        Padding(
                                                          padding:
                                                              EdgeInsetsDirectional
                                                                  .fromSTEB(
                                                                      12.0,
                                                                      0.0,
                                                                      12.0,
                                                                      0.0),
                                                          child: Column(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .max,
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .end,
                                                            children: [
                                                              Align(
                                                                alignment:
                                                                    AlignmentDirectional(
                                                                        -1.0,
                                                                        0.0),
                                                                child: Text(
                                                                  'Link 1',
                                                                  style: FlutterFlowTheme.of(
                                                                          context)
                                                                      .bodyMedium
                                                                      .override(
                                                                        font: GoogleFonts
                                                                            .roboto(
                                                                          fontWeight:
                                                                              FontWeight.normal,
                                                                          fontStyle: FlutterFlowTheme.of(context)
                                                                              .bodyMedium
                                                                              .fontStyle,
                                                                        ),
                                                                        color: Color(
                                                                            0x72FFFFFF),
                                                                        fontSize:
                                                                            14.0,
                                                                        letterSpacing:
                                                                            0.0,
                                                                        fontWeight:
                                                                            FontWeight.normal,
                                                                        fontStyle: FlutterFlowTheme.of(context)
                                                                            .bodyMedium
                                                                            .fontStyle,
                                                                      ),
                                                                ),
                                                              ),
                                                              Align(
                                                                alignment:
                                                                    AlignmentDirectional(
                                                                        -1.0,
                                                                        0.0),
                                                                child: InkWell(
                                                                  splashColor:
                                                                      Colors
                                                                          .transparent,
                                                                  focusColor: Colors
                                                                      .transparent,
                                                                  hoverColor: Colors
                                                                      .transparent,
                                                                  highlightColor:
                                                                      Colors
                                                                          .transparent,
                                                                  onTap:
                                                                      () async {
                                                                    await launchURL(
                                                                        listTrackingItem
                                                                            .link);
                                                                  },
                                                                  child: Text(
                                                                    valueOrDefault<
                                                                        String>(
                                                                      listTrackingItem.link,
                                                                      'Não cadastrado',
                                                                    ),
                                                                    style: FlutterFlowTheme.of(
                                                                            context)
                                                                        .bodyMedium
                                                                        .override(
                                                                          font:
                                                                              GoogleFonts.roboto(
                                                                            fontWeight:
                                                                                FontWeight.w500,
                                                                            fontStyle:
                                                                                FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                          ),
                                                                          color:
                                                                              FlutterFlowTheme.of(context).secondaryBackground,
                                                                          fontSize:
                                                                              14.0,
                                                                          letterSpacing:
                                                                              0.0,
                                                                          fontWeight:
                                                                              FontWeight.w500,
                                                                          fontStyle: FlutterFlowTheme.of(context)
                                                                              .bodyMedium
                                                                              .fontStyle,
                                                                        ),
                                                                  ),
                                                                ),
                                                              ),
                                                              Align(
                                                                alignment:
                                                                    AlignmentDirectional(
                                                                        -1.0,
                                                                        0.0),
                                                                child: Padding(
                                                                  padding: EdgeInsetsDirectional
                                                                      .fromSTEB(
                                                                          0.0,
                                                                          4.0,
                                                                          0.0,
                                                                          0.0),
                                                                  child: Text(
                                                                    'Link 2',
                                                                    style: FlutterFlowTheme.of(
                                                                            context)
                                                                        .bodyMedium
                                                                        .override(
                                                                          font:
                                                                              GoogleFonts.roboto(
                                                                            fontWeight:
                                                                                FontWeight.normal,
                                                                            fontStyle:
                                                                                FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                          ),
                                                                          color:
                                                                              Color(0x72FFFFFF),
                                                                          fontSize:
                                                                              14.0,
                                                                          letterSpacing:
                                                                              0.0,
                                                                          fontWeight:
                                                                              FontWeight.normal,
                                                                          fontStyle: FlutterFlowTheme.of(context)
                                                                              .bodyMedium
                                                                              .fontStyle,
                                                                        ),
                                                                  ),
                                                                ),
                                                              ),
                                                              Align(
                                                                alignment:
                                                                    AlignmentDirectional(
                                                                        -1.0,
                                                                        0.0),
                                                                child: InkWell(
                                                                  splashColor:
                                                                      Colors
                                                                          .transparent,
                                                                  focusColor: Colors
                                                                      .transparent,
                                                                  hoverColor: Colors
                                                                      .transparent,
                                                                  highlightColor:
                                                                      Colors
                                                                          .transparent,
                                                                  onTap:
                                                                      () async {
                                                                    await launchURL(
                                                                        listTrackingItem
                                                                            .link2);
                                                                  },
                                                                  child: Text(
                                                                    valueOrDefault<
                                                                        String>(
                                                                      listTrackingItem.link2,
                                                                      'Não cadastrado',
                                                                    ),
                                                                    style: FlutterFlowTheme.of(
                                                                            context)
                                                                        .bodyMedium
                                                                        .override(
                                                                          font:
                                                                              GoogleFonts.roboto(
                                                                            fontWeight:
                                                                                FontWeight.w500,
                                                                            fontStyle:
                                                                                FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                          ),
                                                                          color:
                                                                              FlutterFlowTheme.of(context).secondaryBackground,
                                                                          fontSize:
                                                                              14.0,
                                                                          letterSpacing:
                                                                              0.0,
                                                                          fontWeight:
                                                                              FontWeight.w500,
                                                                          fontStyle: FlutterFlowTheme.of(context)
                                                                              .bodyMedium
                                                                              .fontStyle,
                                                                        ),
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Padding(
                                              padding: EdgeInsetsDirectional
                                                  .fromSTEB(12.0, 24.0, 12.0, 0.0),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.end,
                                                children: [
                                                  if (listTrackingItem.isCheck)
                                                    Padding(
                                                      padding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 8.0, 0.0),
                                                      child: Builder(
                                                        builder: (context) => InkWell(
                                                          splashColor: Colors.transparent,
                                                          focusColor: Colors.transparent,
                                                          hoverColor: Colors.transparent,
                                                          highlightColor: Colors.transparent,
                                                          onTap: () async {
                                                            await showDialog(
                                                              context: context,
                                                              builder: (dialogContext) {
                                                                return Dialog(
                                                                  elevation: 0,
                                                                  insetPadding: EdgeInsets.zero,
                                                                  backgroundColor: Colors.transparent,
                                                                  alignment: AlignmentDirectional(0.0, 0.0).resolve(Directionality.of(context)),
                                                                  child: GestureDetector(
                                                                    onTap: () {
                                                                      FocusScope.of(dialogContext).unfocus();
                                                                      FocusManager.instance.primaryFocus?.unfocus();
                                                                    },
                                                                    child: ModalTrackingWidget(
                                                                      title: listTrackingItem.trackingDescription,
                                                                      order: int.tryParse(listTrackingItem.order ?? '') ?? 0,
                                                                      idTracking: listTrackingItem.id,
                                                                      userAircraftId: widget.userAircraftId,
                                                                    ),
                                                                  ),
                                                                );
                                                              },
                                                            );
                                                          },
                                                          child: Container(
                                                            width: 48.0,
                                                            height: 48.0,
                                                            decoration: BoxDecoration(
                                                              color: Color(0xFF14471E),
                                                              borderRadius: BorderRadius.circular(12.0),
                                                            ),
                                                            child: Icon(
                                                              Icons.visibility,
                                                              color: FlutterFlowTheme.of(context).secondaryBackground,
                                                              size: 22.0,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  Builder(
                                                builder: (context) => FFButtonWidget(
                                                    onPressed:
                                                        (listTrackingItem.isCheck || _model.user?.firstOrNull?.profileType != 'Admin Master')
                                                            ? null
                                                            : () async {
                                                                if (listTrackingItem
                                                                        .order ==
                                                                    '1') {
                                                                  await showDialog(
                                                                    context:
                                                                        context,
                                                                    builder:
                                                                        (dialogContext) {
                                                                      return Dialog(
                                                                        elevation:
                                                                            0,
                                                                        insetPadding:
                                                                            EdgeInsets.zero,
                                                                        backgroundColor:
                                                                            Colors.transparent,
                                                                        alignment:
                                                                            AlignmentDirectional(0.0, 0.0).resolve(Directionality.of(context)),
                                                                        child:
                                                                            GestureDetector(
                                                                          onTap:
                                                                              () {
                                                                            FocusScope.of(dialogContext).unfocus();
                                                                            FocusManager.instance.primaryFocus?.unfocus();
                                                                          },
                                                                          child:
                                                                              ModalTrackingWidget(
                                                                            title:
                                                                                'Preencha os campos abaixo com dados do cliente',
                                                                            order:
                                                                                1,
                                                                            idTracking:
                                                                                listTrackingItem.id,
                                                                            userAircraftId:
                                                                                listTrackingItem.userAircraftId,
                                                                            onLinks: (link1,
                                                                                link2,
                                                                                isCheck,
                                                                                idTracking,
                                                                                useraircraftId) async {},
                                                                            onConfiguration: (stripeColor,
                                                                                filter,
                                                                                panel,
                                                                                isCheck,
                                                                                useraircraftId,
                                                                                trackingId) async {
                                                                              await UserAircraftTable().update(
                                                                                data: {
                                                                                  'stripe_color': stripeColor,
                                                                                  'air_filter': filter,
                                                                                  'panel': panel,
                                                                                },
                                                                                matchingRows: (rows) => rows.eqOrNull(
                                                                                  'id',
                                                                                  useraircraftId,
                                                                                ),
                                                                              );
                                                                              await TrackingTable().update(
                                                                                data: {
                                                                                  'isCheck': isCheck,
                                                                                },
                                                                                matchingRows: (rows) => rows.eqOrNull(
                                                                                  'id',
                                                                                  trackingId,
                                                                                ),
                                                                              );
                                                                              ScaffoldMessenger.of(context).showSnackBar(
                                                                                SnackBar(
                                                                                  content: Text(
                                                                                    'Dados atualizados com sucesso!',
                                                                                    style: TextStyle(
                                                                                      color: FlutterFlowTheme.of(context).primaryText,
                                                                                    ),
                                                                                  ),
                                                                                  duration: Duration(milliseconds: 4000),
                                                                                  backgroundColor: FlutterFlowTheme.of(context).primary,
                                                                                ),
                                                                              );
                                                                              safeSetState(() => _model.apiRequestCompleter = null);
                                                                              await _model.waitForApiRequestCompleted();
                                                                              Navigator.pop(context);
                                                                            },
                                                                          ),
                                                                        ),
                                                                      );
                                                                    },
                                                                  );
                                                                } else if (listTrackingItem
                                                                        .order ==
                                                                    '15') {
                                                                  await showDialog(
                                                                    context:
                                                                        context,
                                                                    builder:
                                                                        (dialogContext) {
                                                                      return Dialog(
                                                                        elevation:
                                                                            0,
                                                                        insetPadding:
                                                                            EdgeInsets.zero,
                                                                        backgroundColor:
                                                                            Colors.transparent,
                                                                        alignment:
                                                                            AlignmentDirectional(0.0, 0.0).resolve(Directionality.of(context)),
                                                                        child:
                                                                            GestureDetector(
                                                                          onTap:
                                                                              () {
                                                                            FocusScope.of(dialogContext).unfocus();
                                                                            FocusManager.instance.primaryFocus?.unfocus();
                                                                          },
                                                                          child:
                                                                              ModalTrackingWidget(
                                                                            title:
                                                                                'Preencha o campo com o link do cliente',
                                                                            order:
                                                                                15,
                                                                            idTracking:
                                                                                listTrackingItem.id,
                                                                            userAircraftId:
                                                                                listTrackingItem.userAircraftId,
                                                                            onLinks: (link1,
                                                                                link2,
                                                                                isCheck,
                                                                                idTracking,
                                                                                useraircraftId) async {
                                                                              await TrackingTable().update(
                                                                                data: {
                                                                                  'link': link1,
                                                                                  'link2': link2,
                                                                                  'isCheck': isCheck,
                                                                                },
                                                                                matchingRows: (rows) => rows.eqOrNull(
                                                                                  'id',
                                                                                  idTracking,
                                                                                ),
                                                                              );
                                                                              ScaffoldMessenger.of(context).showSnackBar(
                                                                                SnackBar(
                                                                                  content: Text(
                                                                                    'Link adicionado com sucesso!',
                                                                                    style: TextStyle(
                                                                                      color: FlutterFlowTheme.of(context).primaryText,
                                                                                    ),
                                                                                  ),
                                                                                  duration: Duration(milliseconds: 4000),
                                                                                  backgroundColor: FlutterFlowTheme.of(context).primary,
                                                                                ),
                                                                              );
                                                                              safeSetState(() => _model.apiRequestCompleter = null);
                                                                              await _model.waitForApiRequestCompleted();
                                                                              Navigator.pop(context);
                                                                            },
                                                                            onConfiguration: (stripeColor,
                                                                                filter,
                                                                                panel,
                                                                                isCheck,
                                                                                useraircraftId,
                                                                                trackingId) async {},
                                                                          ),
                                                                        ),
                                                                      );
                                                                    },
                                                                  );
                                                                } else if ([
                                                                    '2', '3', '4', '5',
                                                                    '6', '7', '8', '9',
                                                                    '10', '11', '12', '13', '14',
                                                                    '16', '17', '18', '19', '20'
                                                                  ].contains(listTrackingItem.order.toString())) {
                                                                  await showDialog(
                                                                    context:
                                                                        context,
                                                                    builder:
                                                                        (dialogContext) {
                                                                      return Dialog(
                                                                        elevation:
                                                                            0,
                                                                        insetPadding:
                                                                            EdgeInsets.zero,
                                                                        backgroundColor:
                                                                            Colors.transparent,
                                                                        alignment:
                                                                            AlignmentDirectional(0.0, 0.0).resolve(Directionality.of(context)),
                                                                        child:
                                                                            GestureDetector(
                                                                          onTap:
                                                                              () {
                                                                            FocusScope.of(dialogContext).unfocus();
                                                                            FocusManager.instance.primaryFocus?.unfocus();
                                                                          },
                                                                          child:
                                                                              ModalTrackingWidget(
                                                                            title:
                                                                                listTrackingItem.trackingDescription,
                                                                            order:
                                                                                int.parse(listTrackingItem.order.toString()),
                                                                            idTracking:
                                                                                listTrackingItem.id,
                                                                            userAircraftId:
                                                                                listTrackingItem.userAircraftId,
                                                                            onConfirmStep:
                                                                                (trackingId) async {
                                                                              await TrackingTable().update(
                                                                                data: {
                                                                                  'isCheck': true,
                                                                                },
                                                                                matchingRows: (rows) => rows.eqOrNull(
                                                                                  'id',
                                                                                  trackingId,
                                                                                ),
                                                                              );
                                                                              safeSetState(() {});
                                                                            },
                                                                          ),
                                                                        ),
                                                                      );
                                                                    },
                                                                  );
                                                                } else {
                                                                  await showDialog(
                                                                    context:
                                                                        context,
                                                                    builder:
                                                                        (dialogContext) {
                                                                      return Dialog(
                                                                        elevation:
                                                                            0,
                                                                        insetPadding:
                                                                            EdgeInsets.zero,
                                                                        backgroundColor:
                                                                            Colors.transparent,
                                                                        alignment:
                                                                            AlignmentDirectional(0.0, 0.0).resolve(Directionality.of(context)),
                                                                        child:
                                                                            GestureDetector(
                                                                          onTap:
                                                                              () {
                                                                            FocusScope.of(dialogContext).unfocus();
                                                                            FocusManager.instance.primaryFocus?.unfocus();
                                                                          },
                                                                          child:
                                                                              AlertDialogWidget(
                                                                            title:
                                                                                'Deseja confirmar esta etapa do processo?',
                                                                            iconColor:
                                                                                FlutterFlowTheme.of(context).primary,
                                                                            btnColor:
                                                                                FlutterFlowTheme.of(context).primary,
                                                                            confirmBtnAction:
                                                                                () async {
                                                                              await TrackingTable().update(
                                                                                data: {
                                                                                  'isCheck': true,
                                                                                },
                                                                                matchingRows: (rows) => rows.eqOrNull(
                                                                                  'id',
                                                                                  listTrackingItem.id,
                                                                                ),
                                                                              );
                                                                              Navigator.pop(context);
                                                                            },
                                                                          ),
                                                                        ),
                                                                      );
                                                                    },
                                                                  );
                                                                }

                                                                safeSetState(() =>
                                                                    _model.apiRequestCompleter =
                                                                        null);
                                                                await _model
                                                                    .waitForApiRequestCompleted();

                                                                safeSetState(
                                                                    () {});
                                                              },
                                                    text:
                                                        valueOrDefault<String>(
                                                      () {
                                                        final _configOrders = [
                                                          '1',
                                                          '2',
                                                          '3',
                                                          '4',
                                                          '5',
                                                          '6',
                                                          '7',
                                                          '8',
                                                          '9',
                                                          '10',
                                                          '11',
                                                          '12',
                                                          '13',
                                                          '14',
                                                          '15',
                                                          '16',
                                                          '17',
                                                          '18',
                                                          '19',
                                                          '20'
                                                        ];
                                                        final _isConfigOrder =
                                                            _configOrders
                                                                .contains(
                                                                    listTrackingItem
                                                                        .order
                                                                        .toString());
                                                        if (_isConfigOrder &&
                                                            listTrackingItem
                                                                .isCheck) {
                                                          return 'Configurado';
                                                        } else if (_isConfigOrder) {
                                                          return 'Configurar';
                                                        } else if (listTrackingItem
                                                            .isCheck) {
                                                          return 'Confirmado';
                                                        } else {
                                                          return 'Confirmar';
                                                        }
                                                      }(),
                                                      'Confirmar',
                                                    ),
                                                    options: FFButtonOptions(
                                                      height: 48.0,
                                                      padding:
                                                          EdgeInsetsDirectional
                                                              .fromSTEB(
                                                                  36.0,
                                                                  0.0,
                                                                  36.0,
                                                                  0.0),
                                                      iconPadding:
                                                          EdgeInsetsDirectional
                                                              .fromSTEB(
                                                                  0.0,
                                                                  0.0,
                                                                  0.0,
                                                                  0.0),
                                                      color:
                                                          valueOrDefault<Color>(
                                                        listTrackingItem.isCheck
                                                            ? Color(0xFF14471E)
                                                            : FlutterFlowTheme
                                                                    .of(context)
                                                                .primary,
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .primary,
                                                      ),
                                                      textStyle:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .titleSmall
                                                              .override(
                                                                font:
                                                                    GoogleFonts
                                                                        .inter(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500,
                                                                  fontStyle: FlutterFlowTheme.of(
                                                                          context)
                                                                      .titleSmall
                                                                      .fontStyle,
                                                                ),
                                                                color:
                                                                    valueOrDefault<
                                                                        Color>(
                                                                  listTrackingItem.isCheck
                                                                      ? FlutterFlowTheme.of(
                                                                              context)
                                                                          .secondaryBackground
                                                                      : FlutterFlowTheme.of(
                                                                              context)
                                                                          .primaryText,
                                                                  FlutterFlowTheme.of(
                                                                          context)
                                                                      .primaryText,
                                                                ),
                                                                fontSize: 14.0,
                                                                letterSpacing:
                                                                    0.0,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                                fontStyle: FlutterFlowTheme.of(
                                                                        context)
                                                                    .titleSmall
                                                                    .fontStyle,
                                                              ),
                                                      elevation: 0.0,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12.0),
                                                      hoverElevation: 6.0,
                                                    ),
                                                  ),
                                                ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              );
                            },
                          ),
                        ),
                      ),
                    ].divide(SizedBox(height: 8.0)),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
