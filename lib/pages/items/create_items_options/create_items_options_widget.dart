import '/auth/supabase_auth/auth_util.dart';
import '/backend/schema/enums/enums.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_drop_down.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/form_field_controller.dart';
import '/pages/shared/alert_dialog/alert_dialog_widget.dart';
import '/pages/shared/empty_all_lists/empty_all_lists_widget.dart';
import '/security/write_guard.dart';
import '/flutter_flow/custom_functions.dart' as functions;
import 'dart:async';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import '/core_ui/core_ui.dart';
import 'create_items_options_model.dart';
export 'create_items_options_model.dart';

class CreateItemsOptionsWidget extends StatefulWidget {
  const CreateItemsOptionsWidget({super.key, this.categoryId});

  /// Pré-seleciona a categoria (vindo da tela Categorias).
  final String? categoryId;

  static String routeName = 'CreateItemsOptions';
  static String routePath = '/createItemsOptions';

  @override
  State<CreateItemsOptionsWidget> createState() =>
      _CreateItemsOptionsWidgetState();
}

class _CreateItemsOptionsWidgetState extends State<CreateItemsOptionsWidget> {
  late CreateItemsOptionsModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => CreateItemsOptionsModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  // Dados de apoio memoizados (uma query só, compartilhada por toda a tela).
  Future<List<AircraftsRow>> get _aircraftsFuture =>
      _model.aircraftsFuture ??= AircraftsTable().queryRows(
        queryFn: (q) => q
            .eqOrNull('active', true)
            .eqOrNull('deleted', false)
            .order('aircraft_model', ascending: true),
      );

  Future<List<AircraftItemLinksRow>> get _linksFuture =>
      _model.aircraftLinksFuture ??= AircraftItemLinksTable().queryRows(
        queryFn: (q) => q,
      );

  /// Modelos das aeronaves vinculadas ao item, ou aviso de item legado
  /// sem vínculo. Usa os futures memoizados — nenhuma query por linha.
  Widget _linkedModelsText(String aircraftItemId) {
    return FutureBuilder<List<List<dynamic>>>(
      future: Future.wait([_aircraftsFuture, _linksFuture]),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return SizedBox.shrink();
        }
        final aircraftRows = snapshot.data![0].cast<AircraftsRow>();
        final linkRows = snapshot.data![1].cast<AircraftItemLinksRow>();
        final modelById = {
          for (final a in aircraftRows) a.id: a.aircraftModel,
        };
        final models = linkRows
            .where((l) => l.aircraftItemId == aircraftItemId)
            .map((l) => modelById[l.aircraftId])
            .whereType<String>()
            .toList()
          ..sort();
        final hasLinks = models.isNotEmpty;
        return Padding(
          padding: EdgeInsetsDirectional.fromSTEB(0.0, 4.0, 0.0, 0.0),
          child: Text(
            hasLinks
                ? 'Aeronaves: ${models.join(', ')}'
                : 'Sem aeronave vinculada',
            style: FlutterFlowTheme.of(context).bodySmall.override(
                  font: GoogleFonts.inter(
                    fontWeight: FontWeight.normal,
                    fontStyle:
                        FlutterFlowTheme.of(context).bodySmall.fontStyle,
                  ),
                  color: hasLinks
                      ? Color(0x73FFFFFF)
                      : FlutterFlowTheme.of(context).error,
                  fontSize: 12.0,
                  letterSpacing: 0.0,
                  fontWeight: FontWeight.normal,
                  fontStyle: FlutterFlowTheme.of(context).bodySmall.fontStyle,
                ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppDetailsScaffold(
      title: 'Itens — opções',
      body: Container(
              width: MediaQuery.sizeOf(context).width * 1.0,
              decoration: BoxDecoration(),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Padding(
                      padding: EdgeInsetsDirectional.fromSTEB(
                          16.0, 36.0, 16.0, 16.0),
                      child: Container(
                        width: MediaQuery.sizeOf(context).width * 1.0,
                        constraints: BoxConstraints(
                          maxWidth: double.infinity,
                        ),
                        decoration: BoxDecoration(
                          color: Color(0xFF404040),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(24.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              Expanded(
                                child: Text(
                                  'Cadastrar itens opcionais de Aeronaves',
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
                                        color: FlutterFlowTheme.of(context)
                                            .secondaryBackground,
                                        fontSize: 18.0,
                                        letterSpacing: 0.0,
                                        fontWeight: FontWeight.w500,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .fontStyle,
                                      ),
                                ),
                              ),
                              AppPrimaryButton(
                                label: 'Adicionar item',
                                icon: Icons.add,
                                onPressed: () async {
                                  final categoryRows =
                                      await CategoryTable().queryRows(
                                    queryFn: (q) => q
                                        .eqOrNull('item_type', 'optional')
                                        .order('category_name',
                                            ascending: true),
                                  );
                                  final aircraftRows = await _aircraftsFuture;
                                  if (!context.mounted) {
                                    return;
                                  }
                                  final created = await showDialog<bool>(
                                    context: context,
                                    builder: (dialogContext) {
                                      return Dialog(
                                        elevation: 0,
                                        insetPadding: EdgeInsets.zero,
                                        backgroundColor: Colors.transparent,
                                        alignment:
                                            AlignmentDirectional(0.0, 0.0)
                                                .resolve(Directionality.of(
                                                    context)),
                                        child: _CreateOptionalItemDialog(
                                          categories: categoryRows,
                                          aircrafts: aircraftRows,
                                          initialCategoryId: widget.categoryId,
                                        ),
                                      );
                                    },
                                  );
                                  if (created == true) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Item opcional cadastrado com sucesso!',
                                            style: TextStyle(
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .primaryText,
                                            ),
                                          ),
                                          duration:
                                              Duration(milliseconds: 4000),
                                          backgroundColor:
                                              FlutterFlowTheme.of(context)
                                                  .primary,
                                        ),
                                      );
                                    }
                                    safeSetState(() {
                                      _model.aircraftLinksFuture = null;
                                      _model.itemsByCategory.clear();
                                    });
                                  }
                                },
                              ),
                            ].divide(SizedBox(width: 16.0)),
                          ),
                        ),
                      ),
                    ),
                    FutureBuilder<List<CategoryRow>>(
                      future: CategoryTable().queryRows(
                        queryFn: (q) => q
                            .eqOrNull(
                              'item_type',
                              AircraftItemType.optional.name,
                            )
                            .order('category_name', ascending: true),
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
                        List<CategoryRow> cTStructureCategoryCategoryRowList =
                            snapshot.data!;

                        return Container(
                          width: MediaQuery.sizeOf(context).width * 1.0,
                          constraints: BoxConstraints(
                            maxWidth: double.infinity,
                          ),
                          decoration: BoxDecoration(),
                          child: Builder(
                            builder: (context) {
                              final cTStructureCategoryVar =
                                  cTStructureCategoryCategoryRowList.toList();

                              return ListView.separated(
                                padding: EdgeInsets.zero,
                                primary: false,
                                shrinkWrap: true,
                                scrollDirection: Axis.vertical,
                                itemCount: cTStructureCategoryVar.length,
                                separatorBuilder: (_, __) =>
                                    SizedBox(height: 28.0),
                                itemBuilder:
                                    (context, cTStructureCategoryVarIndex) {
                                  final cTStructureCategoryVarItem =
                                      cTStructureCategoryVar[
                                          cTStructureCategoryVarIndex];
                                  return Container(
                                    constraints: BoxConstraints(
                                      maxWidth: double.infinity,
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
                                              padding: EdgeInsets.all(12.0),
                                              child: RichText(
                                                textScaler:
                                                    MediaQuery.of(context)
                                                        .textScaler,
                                                text: TextSpan(
                                                  children: [
                                                    TextSpan(
                                                      text: valueOrDefault<
                                                          String>(
                                                        cTStructureCategoryVarItem
                                                            .categoryName,
                                                        'CATEGORY',
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
                                                    TextSpan(
                                                      text: ' / ',
                                                      style: TextStyle(
                                                        color: FlutterFlowTheme
                                                                .of(context)
                                                            .secondaryBackground,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 18.0,
                                                      ),
                                                    ),
                                                    TextSpan(
                                                      text:
                                                          'Lista de itens opcionais',
                                                      style: TextStyle(),
                                                    )
                                                  ],
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
                                                        color:
                                                            Color(0x73FFFFFF),
                                                        fontSize: 14.0,
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
                                          ),
                                          Divider(
                                            thickness: 2.0,
                                            color: Color(0x74FFFFFF),
                                          ),
                                          Padding(
                                            padding:
                                                EdgeInsetsDirectional.fromSTEB(
                                                    0.0, 12.0, 0.0, 12.0),
                                            child: FutureBuilder<
                                                List<AircraftItemsRow>>(
                                              future: _model.itemsByCategory[
                                                      cTStructureCategoryVarItem
                                                          .id] ??=
                                                  AircraftItemsTable()
                                                      .queryRows(
                                                queryFn: (q) => q
                                                    .eqOrNull(
                                                      'category_id',
                                                      cTStructureCategoryVarItem
                                                          .id,
                                                    )
                                                    .eqOrNull(
                                                      'item_type',
                                                      ItemType.optional.name,
                                                    )
                                                    .eqOrNull(
                                                      'deleted',
                                                      false,
                                                    )
                                                    .eqOrNull(
                                                      'active',
                                                      true,
                                                    )
                                                    .order('item_name',
                                                        ascending: true),
                                              ),
                                              builder: (context, snapshot) {
                                                // Customize what your widget looks like when it's loading.
                                                if (!snapshot.hasData) {
                                                  return Center(
                                                    child: SizedBox(
                                                      width: 40.0,
                                                      height: 40.0,
                                                      child: SpinKitFoldingCube(
                                                        color:
                                                            Color(0xFFC2D51C),
                                                        size: 40.0,
                                                      ),
                                                    ),
                                                  );
                                                }
                                                List<AircraftItemsRow>
                                                    lVOptionalItemsAircraftItemsRowList =
                                                    snapshot.data!;

                                                if (lVOptionalItemsAircraftItemsRowList
                                                    .isEmpty) {
                                                  return EmptyAllListsWidget();
                                                }

                                                return ListView.separated(
                                                  padding: EdgeInsets.zero,
                                                  primary: false,
                                                  shrinkWrap: true,
                                                  scrollDirection:
                                                      Axis.vertical,
                                                  itemCount:
                                                      lVOptionalItemsAircraftItemsRowList
                                                          .length,
                                                  separatorBuilder: (_, __) =>
                                                      SizedBox(height: 8.0),
                                                  itemBuilder: (context,
                                                      lVOptionalItemsIndex) {
                                                    final lVOptionalItemsAircraftItemsRow =
                                                        lVOptionalItemsAircraftItemsRowList[
                                                            lVOptionalItemsIndex];
                                                    return Container(
                                                      decoration:
                                                          BoxDecoration(),
                                                      child: Padding(
                                                        padding:
                                                            EdgeInsetsDirectional
                                                                .fromSTEB(
                                                                    12.0,
                                                                    0.0,
                                                                    12.0,
                                                                    8.0),
                                                        child: Column(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Row(
                                                          mainAxisSize:
                                                              MainAxisSize.max,
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .spaceBetween,
                                                          children: [
                                                            Expanded(
                                                              child: Row(
                                                                mainAxisSize:
                                                                    MainAxisSize
                                                                        .max,
                                                                children: [
                                                                  Expanded(
                                                                    child: Align(
                                                                    alignment:
                                                                        AlignmentDirectional(
                                                                            -1.0,
                                                                            0.0),
                                                                    child:
                                                                        RichText(
                                                                      textScaler:
                                                                          MediaQuery.of(context)
                                                                              .textScaler,
                                                                      text:
                                                                          TextSpan(
                                                                        children: [
                                                                          TextSpan(
                                                                            text:
                                                                                'Item / ',
                                                                            style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                  font: GoogleFonts.inter(
                                                                                    fontWeight: FontWeight.normal,
                                                                                    fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                  ),
                                                                                  color: FlutterFlowTheme.of(context).secondaryBackground,
                                                                                  fontSize: 14.0,
                                                                                  letterSpacing: 0.0,
                                                                                  fontWeight: FontWeight.normal,
                                                                                  fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                ),
                                                                          ),
                                                                          TextSpan(
                                                                            text:
                                                                                lVOptionalItemsAircraftItemsRow.itemName,
                                                                            style:
                                                                                TextStyle(
                                                                              fontSize: 14.0,
                                                                            ),
                                                                          )
                                                                        ],
                                                                        style: FlutterFlowTheme.of(context)
                                                                            .bodyMedium
                                                                            .override(
                                                                              font: GoogleFonts.inter(
                                                                                fontWeight: FontWeight.normal,
                                                                                fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                              ),
                                                                              color: Color(0x73FFFFFF),
                                                                              fontSize: 14.0,
                                                                              letterSpacing: 0.0,
                                                                              fontWeight: FontWeight.normal,
                                                                              fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                            ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  ),
                                                                  SizedBox(
                                                                    width: 100.0,
                                                                    child: Align(
                                                                    alignment:
                                                                        AlignmentDirectional(
                                                                            -1.0,
                                                                            0.0),
                                                                    child:
                                                                        RichText(
                                                                      textScaler:
                                                                          MediaQuery.of(context)
                                                                              .textScaler,
                                                                      text:
                                                                          TextSpan(
                                                                        children: [
                                                                          TextSpan(
                                                                            text:
                                                                                'Qtd: ',
                                                                            style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                  font: GoogleFonts.inter(
                                                                                    fontWeight: FontWeight.normal,
                                                                                    fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                  ),
                                                                                  color: FlutterFlowTheme.of(context).secondaryBackground,
                                                                                  fontSize: 14.0,
                                                                                  letterSpacing: 0.0,
                                                                                  fontWeight: FontWeight.normal,
                                                                                  fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                ),
                                                                          ),
                                                                          TextSpan(
                                                                            text:
                                                                                valueOrDefault<String>(
                                                                              lVOptionalItemsAircraftItemsRow.qty.toString(),
                                                                              '0',
                                                                            ),
                                                                            style:
                                                                                TextStyle(
                                                                              color: Color(0x73FFFFFF),
                                                                              fontSize: 14.0,
                                                                            ),
                                                                          )
                                                                        ],
                                                                        style: FlutterFlowTheme.of(context)
                                                                            .bodyMedium
                                                                            .override(
                                                                              font: GoogleFonts.inter(
                                                                                fontWeight: FontWeight.normal,
                                                                                fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                              ),
                                                                              color: FlutterFlowTheme.of(context).secondaryBackground,
                                                                              fontSize: 16.0,
                                                                              letterSpacing: 0.0,
                                                                              fontWeight: FontWeight.normal,
                                                                              fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                            ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  ),
                                                                  SizedBox(
                                                                    width: 170.0,
                                                                    child: Align(
                                                                    alignment:
                                                                        AlignmentDirectional(
                                                                            -1.0,
                                                                            0.0),
                                                                    child:
                                                                        RichText(
                                                                      textScaler:
                                                                          MediaQuery.of(context)
                                                                              .textScaler,
                                                                      text:
                                                                          TextSpan(
                                                                        children: [
                                                                          TextSpan(
                                                                            text:
                                                                                'Preço: ',
                                                                            style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                  font: GoogleFonts.inter(
                                                                                    fontWeight: FontWeight.normal,
                                                                                    fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                  ),
                                                                                  color: FlutterFlowTheme.of(context).secondaryBackground,
                                                                                  fontSize: 14.0,
                                                                                  letterSpacing: 0.0,
                                                                                  fontWeight: FontWeight.normal,
                                                                                  fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                ),
                                                                          ),
                                                                          TextSpan(
                                                                            text:
                                                                                valueOrDefault<String>(
                                                                              formatNumber(
                                                                                lVOptionalItemsAircraftItemsRow.price,
                                                                                formatType: FormatType.decimal,
                                                                                decimalType: DecimalType.periodDecimal,
                                                                                currency: '\$',
                                                                              ),
                                                                              '\$ 0.00',
                                                                            ),
                                                                            style:
                                                                                TextStyle(
                                                                              color: Color(0x73FFFFFF),
                                                                              fontSize: 14.0,
                                                                            ),
                                                                          )
                                                                        ],
                                                                        style: FlutterFlowTheme.of(context)
                                                                            .bodyMedium
                                                                            .override(
                                                                              font: GoogleFonts.inter(
                                                                                fontWeight: FontWeight.normal,
                                                                                fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                              ),
                                                                              color: FlutterFlowTheme.of(context).secondaryBackground,
                                                                              fontSize: 16.0,
                                                                              letterSpacing: 0.0,
                                                                              fontWeight: FontWeight.normal,
                                                                              fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                            ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  ),
                                                                ].divide(SizedBox(
                                                                    width:
                                                                        16.0)),
                                                              ),
                                                            ),
                                                            Row(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .max,
                                                              children: [
                                                                InkWell(
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
                                                                    final aircraftRows =
                                                                        await _aircraftsFuture;
                                                                    final linkRows =
                                                                        await _linksFuture;
                                                                    final linkedIds = linkRows
                                                                        .where((l) =>
                                                                            l.aircraftItemId ==
                                                                            lVOptionalItemsAircraftItemsRow
                                                                                .id)
                                                                        .map((l) =>
                                                                            l.aircraftId)
                                                                        .toList();
                                                                    if (!context
                                                                        .mounted) {
                                                                      return;
                                                                    }
                                                                    final saved =
                                                                        await showDialog<
                                                                            bool>(
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
                                                                              _EditOptionalItemDialog(
                                                                            item:
                                                                                lVOptionalItemsAircraftItemsRow,
                                                                            aircrafts:
                                                                                aircraftRows,
                                                                            initialAircraftIds:
                                                                                linkedIds,
                                                                          ),
                                                                        );
                                                                      },
                                                                    );
                                                                    if (saved ==
                                                                        true) {
                                                                      safeSetState(
                                                                          () {
                                                                        _model.aircraftLinksFuture =
                                                                            null;
                                                                        _model
                                                                            .itemsByCategory
                                                                            .clear();
                                                                      });
                                                                    }
                                                                  },
                                                                  child: Icon(
                                                                    Icons.edit,
                                                                    color: FlutterFlowTheme.of(
                                                                            context)
                                                                        .primary,
                                                                    size: 20.0,
                                                                  ),
                                                                ),
                                                                InkWell(
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
                                                                    await showDialog(
                                                                      context:
                                                                          context,
                                                                      builder:
                                                                          (dialogContext) =>
                                                                              Dialog(
                                                                        elevation:
                                                                            0,
                                                                        insetPadding:
                                                                            EdgeInsets.zero,
                                                                        backgroundColor:
                                                                            Colors.transparent,
                                                                        alignment:
                                                                            Alignment.center,
                                                                        child:
                                                                            AlertDialogWidget(
                                                                          title:
                                                                              'Deseja excluir este item opcional?',
                                                                          iconColor:
                                                                              const Color(0xFFFF5963),
                                                                          btnColor:
                                                                              const Color(0xFFFF5963),
                                                                          confirmBtnAction:
                                                                              () async {
                                                                            // Soft-delete: itens referenciados por
                                                                            // propostas têm FK NO ACTION (hard-delete
                                                                            // dispara 23503). Marcar deleted=true some
                                                                            // da lista e preserva o histórico.
                                                                            final ok =
                                                                                await guardWrite(
                                                                              context,
                                                                              () => AircraftItemsTable().update(
                                                                                data: {'deleted': true},
                                                                                matchingRows: (rows) => rows.eqOrNull(
                                                                                  'id',
                                                                                  lVOptionalItemsAircraftItemsRow.id,
                                                                                ),
                                                                                returnRows: true,
                                                                              ),
                                                                            );
                                                                            if (!ok) {
                                                                              return; // bloqueado — mantém a modal
                                                                            }
                                                                            if (dialogContext.mounted) {
                                                                              Navigator.of(dialogContext).pop();
                                                                            }
                                                                            safeSetState(() => _model.itemsByCategory.clear());
                                                                          },
                                                                        ),
                                                                      ),
                                                                    );
                                                                  },
                                                                  child: Icon(
                                                                    Icons
                                                                        .delete,
                                                                    color: FlutterFlowTheme.of(
                                                                            context)
                                                                        .error,
                                                                    size: 20.0,
                                                                  ),
                                                                ),
                                                              ].divide(SizedBox(
                                                                  width: 8.0)),
                                                            ),
                                                          ].divide(SizedBox(
                                                              width: 56.0)),
                                                        ),
                                                            _linkedModelsText(
                                                                lVOptionalItemsAircraftItemsRow
                                                                    .id),
                                                          ],
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ]
                      .divide(SizedBox(height: 16.0))
                      .addToEnd(SizedBox(height: 32.0)),
                ),
              ),
            ),
    );
  }
}

/// Modal de edição de item opcional — nome, preço e vínculos de aeronave.
class _EditOptionalItemDialog extends StatefulWidget {
  const _EditOptionalItemDialog({
    required this.item,
    required this.aircrafts,
    required this.initialAircraftIds,
  });

  final AircraftItemsRow item;
  final List<AircraftsRow> aircrafts;
  final List<String> initialAircraftIds;

  @override
  State<_EditOptionalItemDialog> createState() =>
      _EditOptionalItemDialogState();
}

class _EditOptionalItemDialogState extends State<_EditOptionalItemDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _qtyController;
  late final TextEditingController _priceController;
  final FocusNode _priceFocusNode = FocusNode();
  late final FormFieldController<List<String>?> _aircraftsController;
  List<String>? _selectedAircraftIds;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.item.itemName);
    _qtyController =
        TextEditingController(text: widget.item.qty.toString());
    _priceController = TextEditingController(
      text: valueOrDefault<String>(
        functions.formatarMoedaEmDolar(widget.item.price.toStringAsFixed(2)),
        '\$ 0.00',
      ),
    );
    _selectedAircraftIds = List<String>.from(widget.initialAircraftIds);
    _aircraftsController = FormFieldController<List<String>?>(
        List<String>.from(widget.initialAircraftIds));
  }

  @override
  void dispose() {
    EasyDebounce.cancel('_editOptionalItemPrice');
    _titleController.dispose();
    _qtyController.dispose();
    _priceController.dispose();
    _priceFocusNode.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy) {
      return;
    }
    if (_titleController.text.trim().isEmpty) {
      showWriteError(context, 'Informe o nome do item.');
      return;
    }
    if (_priceController.text.trim().isEmpty) {
      showWriteError(context, 'Informe o preço do item.');
      return;
    }
    final qty = int.tryParse(_qtyController.text.trim());
    if (qty == null || qty < 1) {
      showWriteError(context, 'Informe uma quantidade válida (mínimo 1).');
      return;
    }
    final selectedAircrafts = _selectedAircraftIds?.toList() ?? [];
    if (selectedAircrafts.isEmpty) {
      showWriteError(context, 'Selecione ao menos uma aeronave.');
      return;
    }
    setState(() => _busy = true);
    try {
      final ok = await guardWrite(
        context,
        () => AircraftItemsTable().update(
          data: {
            'item_name': _titleController.text.trim(),
            'qty': qty,
            'price': valueOrDefault<double>(
              functions.textToNumeric(_priceController.text),
              0.0,
            ),
          },
          matchingRows: (rows) => rows.eqOrNull('id', widget.item.id),
          returnRows: true,
        ),
      );
      if (!ok) {
        return; // bloqueado — não fecha a modal
      }
      // Reescreve os vínculos: delete SEM guard (zero linhas é legítimo
      // para itens legados sem vínculo), depois insere os novos.
      await AircraftItemLinksTable().delete(
        matchingRows: (rows) =>
            rows.eqOrNull('aircraft_item_id', widget.item.id),
      );
      for (final aircraftId in selectedAircrafts) {
        await guardInsert(
          context,
          () => AircraftItemLinksTable().insert({
            'aircraft_item_id': widget.item.id,
            'aircraft_id': aircraftId,
            'created_by': currentUserUid,
          }),
        );
      }
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppModal(
      icon: Icons.edit_rounded,
      title: 'Editar item opcional',
      description: 'Atualize o nome, o preço e as aeronaves vinculadas.',
      maxWidth: 560,
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          AppSecondaryButton(
            label: 'Cancelar',
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: 10),
          AppPrimaryButton(
            label: 'Salvar alterações',
            icon: Icons.check_rounded,
            busy: _busy,
            onPressed: _save,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppFormField(
            controller: _titleController,
            label: 'Nome do item',
            placeholder: 'Nome do item',
            icon: Icons.settings_suggest_rounded,
            required: true,
          ),
          const SizedBox(height: 14),
          AppFormField(
            controller: _qtyController,
            label: 'Quantidade',
            placeholder: '1',
            icon: Icons.numbers_rounded,
            required: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 14),
          AppFormField(
            controller: _priceController,
            focusNode: _priceFocusNode,
            label: 'Preço',
            placeholder: '\$ 0.00',
            icon: Icons.attach_money_rounded,
            required: true,
            keyboardType: TextInputType.number,
            onChanged: (_) => EasyDebounce.debounce(
              '_editOptionalItemPrice',
              Duration(milliseconds: 0),
              () {
                setState(() {
                  _priceController.text = valueOrDefault<String>(
                    functions.formatarMoedaEmDolar(valueOrDefault<String>(
                      _priceController.text,
                      '0',
                    )),
                    '\$ 0.00',
                  );
                  _priceFocusNode.requestFocus();
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _priceController.selection = TextSelection.collapsed(
                      offset: _priceController.text.length,
                    );
                  });
                });
              },
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: EdgeInsetsDirectional.fromSTEB(2.0, 0.0, 0.0, 6.0),
            child: Text(
              'Aeronaves *',
              style: FlutterFlowTheme.of(context).labelMedium.override(
                    font: GoogleFonts.inter(
                      fontWeight: FontWeight.w500,
                      fontStyle:
                          FlutterFlowTheme.of(context).labelMedium.fontStyle,
                    ),
                    color: FlutterFlowTheme.of(context).secondaryBackground,
                    fontSize: 12.5,
                    letterSpacing: 0.0,
                    fontWeight: FontWeight.w500,
                    fontStyle:
                        FlutterFlowTheme.of(context).labelMedium.fontStyle,
                  ),
            ),
          ),
          FlutterFlowDropDown<String>(
            multiSelectController: _aircraftsController,
            options:
                List<String>.from(widget.aircrafts.map((e) => e.id).toList()),
            optionLabels:
                widget.aircrafts.map((e) => e.aircraftModel).toList(),
            onMultiSelectChanged: (val) =>
                setState(() => _selectedAircraftIds = val),
            height: 48.0,
            textStyle: FlutterFlowTheme.of(context).bodyMedium.override(
                  font: GoogleFonts.inter(
                    fontWeight:
                        FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                    fontStyle:
                        FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                  ),
                  color: FlutterFlowTheme.of(context).secondaryBackground,
                  letterSpacing: 0.0,
                  fontWeight:
                      FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                  fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                ),
            hintText: 'Selecione as aeronaves',
            icon: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Color(0x73FFFFFF),
              size: 24.0,
            ),
            fillColor: Color(0xFF404040),
            elevation: 2.0,
            borderColor: Color(0x73FFFFFF),
            borderWidth: 1.0,
            borderRadius: 8.0,
            margin: EdgeInsetsDirectional.fromSTEB(12.0, 0.0, 12.0, 0.0),
            hidesUnderline: true,
            isOverButton: false,
            isSearchable: false,
            isMultiSelect: true,
          ),
        ],
      ),
    );
  }
}

/// Modal de criação de item opcional — categoria, nome, preço e vínculos
/// de aeronave.
class _CreateOptionalItemDialog extends StatefulWidget {
  const _CreateOptionalItemDialog({
    required this.categories,
    required this.aircrafts,
    this.initialCategoryId,
  });

  final List<CategoryRow> categories;
  final List<AircraftsRow> aircrafts;

  /// Pré-seleciona a categoria (vindo da tela Categorias).
  final String? initialCategoryId;

  @override
  State<_CreateOptionalItemDialog> createState() =>
      _CreateOptionalItemDialogState();
}

class _CreateOptionalItemDialogState extends State<_CreateOptionalItemDialog> {
  late final TextEditingController _titleController;
  // qty é NOT NULL sem default no banco — sem este campo o insert falha (23502)
  // e a proposta multiplica price*qty. Default 1.
  late final TextEditingController _qtyController;
  late final TextEditingController _priceController;
  final FocusNode _priceFocusNode = FocusNode();
  late final FormFieldController<String> _categoryController;
  late final FormFieldController<List<String>?> _aircraftsController;
  String? _categoryId;
  List<String>? _selectedAircraftIds;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _qtyController = TextEditingController(text: '1');
    _priceController = TextEditingController();
    _categoryId = (widget.initialCategoryId ?? '').isNotEmpty
        ? widget.initialCategoryId
        : null;
    _categoryController = FormFieldController<String>(_categoryId ?? '');
    _aircraftsController = FormFieldController<List<String>?>(null);
  }

  @override
  void dispose() {
    EasyDebounce.cancel('_createOptionalItemPrice');
    _titleController.dispose();
    _qtyController.dispose();
    _priceController.dispose();
    _priceFocusNode.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy) {
      return;
    }
    if ((_categoryId ?? '').isEmpty) {
      showWriteError(context, 'Selecione a categoria.');
      return;
    }
    if (_titleController.text.trim().isEmpty) {
      showWriteError(context, 'Informe o nome do item.');
      return;
    }
    if (_priceController.text.trim().isEmpty) {
      showWriteError(context, 'Informe o preço do item.');
      return;
    }
    final qty = int.tryParse(_qtyController.text.trim());
    if (qty == null || qty < 1) {
      showWriteError(context, 'Informe uma quantidade válida (mínimo 1).');
      return;
    }
    final selectedAircrafts = _selectedAircraftIds?.toList() ?? [];
    if (selectedAircrafts.isEmpty) {
      showWriteError(context, 'Selecione ao menos uma aeronave.');
      return;
    }
    setState(() => _busy = true);
    try {
      final createdItem = await guardInsert(
        context,
        () => AircraftItemsTable().insert({
          'category_id': _categoryId,
          'item_name': _titleController.text.trim(),
          'qty': qty,
          'price': valueOrDefault<double>(
            functions.textToNumeric(_priceController.text),
            0.0,
          ),
          'item_type': ItemType.optional.name,
          'created_by': currentUserUid,
        }),
      );
      if (createdItem == null) {
        return; // bloqueado — não fecha a modal
      }
      for (final aircraftId in selectedAircrafts) {
        await guardInsert(
          context,
          () => AircraftItemLinksTable().insert({
            'aircraft_item_id': createdItem.id,
            'aircraft_id': aircraftId,
            'created_by': currentUserUid,
          }),
        );
      }
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Widget _fieldLabel(String label) {
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(2.0, 0.0, 0.0, 6.0),
      child: Text(
        label,
        style: FlutterFlowTheme.of(context).labelMedium.override(
              font: GoogleFonts.inter(
                fontWeight: FontWeight.w500,
                fontStyle: FlutterFlowTheme.of(context).labelMedium.fontStyle,
              ),
              color: FlutterFlowTheme.of(context).secondaryBackground,
              fontSize: 12.5,
              letterSpacing: 0.0,
              fontWeight: FontWeight.w500,
              fontStyle: FlutterFlowTheme.of(context).labelMedium.fontStyle,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppModal(
      icon: Icons.add_rounded,
      title: 'Adicionar item opcional',
      description:
          'Informe a categoria, o nome, a quantidade, o preço e as aeronaves vinculadas.',
      maxWidth: 560,
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          AppSecondaryButton(
            label: 'Cancelar',
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: 10),
          AppPrimaryButton(
            label: 'Cadastrar item',
            icon: Icons.check_rounded,
            busy: _busy,
            onPressed: _save,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _fieldLabel('Categoria *'),
          FlutterFlowDropDown<String>(
            controller: _categoryController,
            options:
                List<String>.from(widget.categories.map((e) => e.id).toList()),
            optionLabels:
                widget.categories.map((e) => e.categoryName).toList(),
            onChanged: (val) => setState(() => _categoryId = val),
            height: 48.0,
            textStyle: FlutterFlowTheme.of(context).bodyMedium.override(
                  font: GoogleFonts.inter(
                    fontWeight:
                        FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                    fontStyle:
                        FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                  ),
                  color: FlutterFlowTheme.of(context).secondaryBackground,
                  letterSpacing: 0.0,
                  fontWeight:
                      FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                  fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                ),
            hintText: 'Selecione a categoria',
            icon: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Color(0x73FFFFFF),
              size: 24.0,
            ),
            fillColor: Color(0xFF404040),
            elevation: 2.0,
            borderColor: Color(0x73FFFFFF),
            borderWidth: 1.0,
            borderRadius: 8.0,
            margin: EdgeInsetsDirectional.fromSTEB(12.0, 0.0, 12.0, 0.0),
            hidesUnderline: true,
            isOverButton: false,
            isSearchable: false,
            isMultiSelect: false,
          ),
          const SizedBox(height: 14),
          AppFormField(
            controller: _titleController,
            label: 'Nome do item',
            placeholder: 'Nome do item',
            icon: Icons.settings_suggest_rounded,
            required: true,
          ),
          const SizedBox(height: 14),
          AppFormField(
            controller: _qtyController,
            label: 'Quantidade',
            placeholder: '1',
            icon: Icons.numbers_rounded,
            required: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 14),
          AppFormField(
            controller: _priceController,
            focusNode: _priceFocusNode,
            label: 'Preço',
            placeholder: '\$ 0.00',
            icon: Icons.attach_money_rounded,
            required: true,
            keyboardType: TextInputType.number,
            onChanged: (_) => EasyDebounce.debounce(
              '_createOptionalItemPrice',
              Duration(milliseconds: 0),
              () {
                setState(() {
                  _priceController.text = valueOrDefault<String>(
                    functions.formatarMoedaEmDolar(valueOrDefault<String>(
                      _priceController.text,
                      '0',
                    )),
                    '\$ 0.00',
                  );
                  _priceFocusNode.requestFocus();
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _priceController.selection = TextSelection.collapsed(
                      offset: _priceController.text.length,
                    );
                  });
                });
              },
            ),
          ),
          const SizedBox(height: 14),
          _fieldLabel('Aeronaves *'),
          FlutterFlowDropDown<String>(
            multiSelectController: _aircraftsController,
            options:
                List<String>.from(widget.aircrafts.map((e) => e.id).toList()),
            optionLabels:
                widget.aircrafts.map((e) => e.aircraftModel).toList(),
            onMultiSelectChanged: (val) =>
                setState(() => _selectedAircraftIds = val),
            height: 48.0,
            textStyle: FlutterFlowTheme.of(context).bodyMedium.override(
                  font: GoogleFonts.inter(
                    fontWeight:
                        FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                    fontStyle:
                        FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                  ),
                  color: FlutterFlowTheme.of(context).secondaryBackground,
                  letterSpacing: 0.0,
                  fontWeight:
                      FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                  fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                ),
            hintText: 'Selecione as aeronaves',
            icon: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Color(0x73FFFFFF),
              size: 24.0,
            ),
            fillColor: Color(0xFF404040),
            elevation: 2.0,
            borderColor: Color(0x73FFFFFF),
            borderWidth: 1.0,
            borderRadius: 8.0,
            margin: EdgeInsetsDirectional.fromSTEB(12.0, 0.0, 12.0, 0.0),
            hidesUnderline: true,
            isOverButton: false,
            isSearchable: false,
            isMultiSelect: true,
          ),
        ],
      ),
    );
  }
}
