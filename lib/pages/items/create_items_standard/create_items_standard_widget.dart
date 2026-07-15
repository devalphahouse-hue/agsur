import '/auth/supabase_auth/auth_util.dart';
import '/backend/schema/enums/enums.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_drop_down.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/form_field_controller.dart';
import '/security/write_guard.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import '/core_ui/core_ui.dart';
import 'create_items_standard_model.dart';
export 'create_items_standard_model.dart';

class CreateItemsStandardWidget extends StatefulWidget {
  const CreateItemsStandardWidget({super.key, this.categoryId});

  /// Pré-seleciona a categoria (vindo da tela Categorias).
  final String? categoryId;

  static String routeName = 'CreateItemsStandard';
  static String routePath = '/createItemsStandard';

  @override
  State<CreateItemsStandardWidget> createState() =>
      _CreateItemsStandardWidgetState();
}

class _CreateItemsStandardWidgetState extends State<CreateItemsStandardWidget> {
  late CreateItemsStandardModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => CreateItemsStandardModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  // Dados de apoio memoizados no model (padrão `??=` do projeto) — não
  // refazem a query a cada rebuild. Invalidação: `_model.xFuture = null`.
  Future<List<AircraftsRow>> get _aircraftsFuture =>
      _model.aircraftsFuture ??= AircraftsTable().queryRows(
        queryFn: (q) => q
            .eqOrNull('active', true)
            .eqOrNull('deleted', false)
            .order('aircraft_model', ascending: true),
      );

  Future<List<AircraftItemLinksRow>> get _itemLinksFuture =>
      _model.itemLinksFuture ??=
          AircraftItemLinksTable().queryRows(queryFn: (q) => q);

  /// Abre o modal de criação de item de série. Ao confirmar (`true`),
  /// invalida os vínculos memoizados e rebuilda a lista.
  Future<void> _openCreateDialog() async {
    final categories = await CategoryTable().queryRows(
      queryFn: (q) => q
          .eqOrNull('item_type', 'series')
          .order('category_name', ascending: true),
    );
    final aircrafts = await _aircraftsFuture;
    if (!mounted) return;
    final created = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          elevation: 0,
          insetPadding: EdgeInsets.zero,
          backgroundColor: Colors.transparent,
          alignment: AlignmentDirectional(0.0, 0.0)
              .resolve(Directionality.of(context)),
          child: _CreateItemSeriesDialog(
            categories: categories,
            aircrafts: aircrafts,
            initialCategoryId: widget.categoryId,
          ),
        );
      },
    );
    if (created == true) {
      _model.itemLinksFuture = null;
      safeSetState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppDetailsScaffold(
      title: 'Itens — padrão',
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
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Padding(
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      12.0, 0.0, 12.0, 0.0),
                                  child: Text(
                                    'Cadastrar itens de série de Aeronaves',
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
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .bodyMedium
                                                  .fontStyle,
                                        ),
                                  ),
                                ),
                              ),
                              AppPrimaryButton(
                                label: 'Adicionar item',
                                icon: Icons.add,
                                onPressed: _openCreateDialog,
                              ),
                            ].divide(SizedBox(width: 16.0)),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding:
                          EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 24.0),
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
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Align(
                                alignment: AlignmentDirectional(-1.0, 0.0),
                                child: Padding(
                                  padding: EdgeInsets.all(12.0),
                                  child: Text(
                                    'Lista de itens de série',
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
                                    0.0, 12.0, 0.0, 12.0),
                                child: FutureBuilder<List<List<dynamic>>>(
                                  future: Future.wait<List<dynamic>>([
                                    AircraftItemsTable().queryRows(
                                      queryFn: (q) => q
                                          .eqOrNull(
                                            'item_type',
                                            ItemType.series.name,
                                          )
                                          .eqOrNull('deleted', false)
                                          .eqOrNull('active', true)
                                          .order('item_name', ascending: true),
                                    ),
                                    // Memoizados no model — sem re-query por
                                    // rebuild nem FutureBuilder por linha.
                                    _itemLinksFuture,
                                    _aircraftsFuture,
                                  ]),
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
                                    final lVStructureDocumentsOwnerAircraftItemsRowList =
                                        snapshot.data![0]
                                            .cast<AircraftItemsRow>();
                                    final aircraftItemLinksRowList = snapshot
                                        .data![1]
                                        .cast<AircraftItemLinksRow>();
                                    final aircraftsRowList =
                                        snapshot.data![2].cast<AircraftsRow>();
                                    // Vínculos agrupados por item + modelo por
                                    // id de aeronave (tudo em memória).
                                    final linkedAircraftIdsByItem =
                                        <String, List<String>>{};
                                    for (final link
                                        in aircraftItemLinksRowList) {
                                      linkedAircraftIdsByItem
                                          .putIfAbsent(link.aircraftItemId,
                                              () => <String>[])
                                          .add(link.aircraftId);
                                    }
                                    final aircraftModelById = {
                                      for (final a in aircraftsRowList)
                                        a.id: a.aircraftModel,
                                    };

                                    return ListView.separated(
                                      padding: EdgeInsets.zero,
                                      primary: false,
                                      shrinkWrap: true,
                                      scrollDirection: Axis.vertical,
                                      itemCount:
                                          lVStructureDocumentsOwnerAircraftItemsRowList
                                              .length,
                                      separatorBuilder: (_, __) =>
                                          SizedBox(height: 8.0),
                                      itemBuilder: (context,
                                          lVStructureDocumentsOwnerIndex) {
                                        final lVStructureDocumentsOwnerAircraftItemsRow =
                                            lVStructureDocumentsOwnerAircraftItemsRowList[
                                                lVStructureDocumentsOwnerIndex];
                                        final linkedAircraftIds =
                                            linkedAircraftIdsByItem[
                                                    lVStructureDocumentsOwnerAircraftItemsRow
                                                        .id] ??
                                                const <String>[];
                                        final linkedModels = linkedAircraftIds
                                            .map((id) => aircraftModelById[id])
                                            .whereType<String>()
                                            .toList();
                                        return Container(
                                          decoration: BoxDecoration(),
                                          child: Padding(
                                            padding:
                                                EdgeInsetsDirectional.fromSTEB(
                                                    12.0, 0.0, 12.0, 8.0),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.max,
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Expanded(
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
                                                        child: Container(
                                                          width:
                                                              MediaQuery.sizeOf(
                                                                          context)
                                                                      .width *
                                                                  0.25,
                                                          decoration:
                                                              BoxDecoration(),
                                                          child: RichText(
                                                            textScaler:
                                                                MediaQuery.of(
                                                                        context)
                                                                    .textScaler,
                                                            text: TextSpan(
                                                              children: [
                                                                TextSpan(
                                                                  text:
                                                                      'Categoria / ',
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
                                                                        color: FlutterFlowTheme.of(context)
                                                                            .secondaryBackground,
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
                                                                TextSpan(
                                                                  text: valueOrDefault<
                                                                      String>(
                                                                    lVStructureDocumentsOwnerAircraftItemsRow
                                                                        .itemName,
                                                                    'Categoria',
                                                                  ),
                                                                  style:
                                                                      TextStyle(
                                                                    fontSize:
                                                                        14.0,
                                                                  ),
                                                                )
                                                              ],
                                                              style: FlutterFlowTheme
                                                                      .of(context)
                                                                  .bodyMedium
                                                                  .override(
                                                                    font: GoogleFonts
                                                                        .inter(
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .normal,
                                                                      fontStyle: FlutterFlowTheme.of(
                                                                              context)
                                                                          .bodyMedium
                                                                          .fontStyle,
                                                                    ),
                                                                    color: Color(
                                                                        0x74FFFFFF),
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
                                                      ),
                                                      Align(
                                                        alignment:
                                                            AlignmentDirectional(
                                                                -1.0, 0.0),
                                                        child: Container(
                                                          width:
                                                              MediaQuery.sizeOf(
                                                                          context)
                                                                      .width *
                                                                  0.1,
                                                          decoration:
                                                              BoxDecoration(),
                                                          child: RichText(
                                                            textScaler:
                                                                MediaQuery.of(
                                                                        context)
                                                                    .textScaler,
                                                            text: TextSpan(
                                                              children: [
                                                                TextSpan(
                                                                  text:
                                                                      'Item / ',
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
                                                                        color: FlutterFlowTheme.of(context)
                                                                            .secondaryBackground,
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
                                                                TextSpan(
                                                                  text: valueOrDefault<
                                                                      String>(
                                                                    lVStructureDocumentsOwnerAircraftItemsRow
                                                                        .itemName,
                                                                    'Nome do item',
                                                                  ),
                                                                  style:
                                                                      TextStyle(),
                                                                )
                                                              ],
                                                              style: FlutterFlowTheme
                                                                      .of(context)
                                                                  .bodyMedium
                                                                  .override(
                                                                    font: GoogleFonts
                                                                        .inter(
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .normal,
                                                                      fontStyle: FlutterFlowTheme.of(
                                                                              context)
                                                                          .bodyMedium
                                                                          .fontStyle,
                                                                    ),
                                                                    color: Color(
                                                                        0x73FFFFFF),
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
                                                                text: 'Qtd: ',
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
                                                                text:
                                                                    valueOrDefault<
                                                                        String>(
                                                                  lVStructureDocumentsOwnerAircraftItemsRow
                                                                      .qty
                                                                      .toString(),
                                                                  '0',
                                                                ),
                                                                style:
                                                                    TextStyle(
                                                                  color: Color(
                                                                      0x73FFFFFF),
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
                                                                      16.0,
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
                                                      Expanded(
                                                        child: Text(
                                                          linkedModels
                                                                  .isNotEmpty
                                                              ? linkedModels
                                                                  .join(', ')
                                                              : 'Sem aeronave vinculada',
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
                                                                color: linkedModels
                                                                        .isNotEmpty
                                                                    ? Color(
                                                                        0x73FFFFFF)
                                                                    : FlutterFlowTheme.of(
                                                                            context)
                                                                        .error,
                                                                fontSize: 12.0,
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
                                                    ].divide(
                                                        SizedBox(width: 16.0)),
                                                  ),
                                                ),
                                                Row(
                                                  mainAxisSize:
                                                      MainAxisSize.max,
                                                  children: [
                                                    InkWell(
                                                      splashColor:
                                                          Colors.transparent,
                                                      focusColor:
                                                          Colors.transparent,
                                                      hoverColor:
                                                          Colors.transparent,
                                                      highlightColor:
                                                          Colors.transparent,
                                                      onTap: () async {
                                                        final updated =
                                                            await showDialog<
                                                                bool>(
                                                          context: context,
                                                          builder:
                                                              (dialogContext) {
                                                            return Dialog(
                                                              elevation: 0,
                                                              insetPadding:
                                                                  EdgeInsets
                                                                      .zero,
                                                              backgroundColor:
                                                                  Colors
                                                                      .transparent,
                                                              alignment: AlignmentDirectional(
                                                                      0.0, 0.0)
                                                                  .resolve(
                                                                      Directionality.of(
                                                                          context)),
                                                              child:
                                                                  _EditItemSeriesDialog(
                                                                item:
                                                                    lVStructureDocumentsOwnerAircraftItemsRow,
                                                                aircrafts:
                                                                    aircraftsRowList,
                                                                linkedAircraftIds:
                                                                    linkedAircraftIds,
                                                              ),
                                                            );
                                                          },
                                                        );
                                                        if (updated == true) {
                                                          _model.itemLinksFuture =
                                                              null;
                                                          safeSetState(() {});
                                                        }
                                                      },
                                                      child: Icon(
                                                        Icons.edit,
                                                        color:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .primary,
                                                        size: 20.0,
                                                      ),
                                                    ),
                                                    InkWell(
                                                      splashColor:
                                                          Colors.transparent,
                                                      focusColor:
                                                          Colors.transparent,
                                                      hoverColor:
                                                          Colors.transparent,
                                                      highlightColor:
                                                          Colors.transparent,
                                                      onTap: () async {
                                                        await AircraftItemsTable()
                                                            .delete(
                                                          matchingRows:
                                                              (rows) =>
                                                                  rows.eqOrNull(
                                                            'id',
                                                            lVStructureDocumentsOwnerAircraftItemsRow
                                                                .id,
                                                          ),
                                                        );
                                                        // FK com ON DELETE CASCADE
                                                        // limpa os vínculos; aqui só
                                                        // atualizamos a lista.
                                                        _model.itemLinksFuture =
                                                            null;
                                                        safeSetState(() {});
                                                      },
                                                      child: Icon(
                                                        Icons.delete,
                                                        color:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .error,
                                                        size: 20.0,
                                                      ),
                                                    ),
                                                  ].divide(
                                                      SizedBox(width: 8.0)),
                                                ),
                                              ].divide(SizedBox(width: 24.0)),
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
                      ),
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

/// Diálogo de edição de item de série — nome, quantidade e vínculos de
/// aeronave. Ao salvar, atualiza `aircraft_items` (com [guardWrite]) e
/// reescreve os vínculos em `aircraft_item_links` (delete sem guard — zero
/// linhas é legítimo em item legado — e insert com [guardInsert]).
/// Retorna `true` no `Navigator.pop` quando persistiu.
class _EditItemSeriesDialog extends StatefulWidget {
  const _EditItemSeriesDialog({
    required this.item,
    required this.aircrafts,
    required this.linkedAircraftIds,
  });

  final AircraftItemsRow item;
  final List<AircraftsRow> aircrafts;
  final List<String> linkedAircraftIds;

  @override
  State<_EditItemSeriesDialog> createState() => _EditItemSeriesDialogState();
}

class _EditItemSeriesDialogState extends State<_EditItemSeriesDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _qtyController;
  late final FormFieldController<List<String>?> _aircraftsController;
  List<String>? _selectedAircraftIds;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
        text: widget.item.getField<String>('item_name') ?? '');
    _qtyController = TextEditingController(
        text: widget.item.getField<int>('qty')?.toString() ?? '');
    _selectedAircraftIds = List<String>.from(widget.linkedAircraftIds);
    _aircraftsController =
        FormFieldController<List<String>?>(_selectedAircraftIds);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _qtyController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    final itemName = _nameController.text.trim();
    final qty = int.tryParse(_qtyController.text.trim());
    final selectedAircraftIds = _selectedAircraftIds?.toList() ?? <String>[];
    if (itemName.isEmpty) {
      showWriteError(context, 'Informe o nome do item.');
      return;
    }
    if (qty == null) {
      showWriteError(context, 'Informe uma quantidade numérica.');
      return;
    }
    if (selectedAircraftIds.isEmpty) {
      showWriteError(context, 'Selecione ao menos uma aeronave.');
      return;
    }
    setState(() => _busy = true);
    try {
      final ok = await guardWrite(
        context,
        () => AircraftItemsTable().update(
          data: {
            'item_name': itemName,
            'qty': qty,
          },
          matchingRows: (rows) => rows.eqOrNull('id', widget.item.id),
          returnRows: true,
        ),
      );
      if (!ok) return; // bloqueado — mantém a modal aberta.
      // Reescreve os vínculos. Sem guard no delete: zero linhas apagadas é
      // legítimo (item legado sem vínculo).
      await AircraftItemLinksTable().delete(
        matchingRows: (rows) =>
            rows.eqOrNull('aircraft_item_id', widget.item.id),
      );
      for (final aircraftId in selectedAircraftIds) {
        await guardInsert(
          context,
          () => AircraftItemLinksTable().insert({
            'aircraft_item_id': widget.item.id,
            'aircraft_id': aircraftId,
            'created_by': currentUserUid,
          }),
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppModal(
      icon: Icons.edit_rounded,
      title: 'Editar item de série',
      description: 'Atualize o nome, a quantidade e as aeronaves vinculadas.',
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
            onPressed: _submit,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppFormField(
            controller: _nameController,
            label: 'Nome do item',
            placeholder: 'Nome do item',
            icon: Icons.build_outlined,
            required: true,
          ),
          const SizedBox(height: 14),
          AppFormField(
            controller: _qtyController,
            label: 'Quantidade',
            placeholder: 'Qtd',
            icon: Icons.numbers_rounded,
            required: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 14),
          RichText(
            text: TextSpan(
              text: 'Aeronaves',
              style: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: const Color(0xCCFFFFFF),
                letterSpacing: 0.3,
              ),
              children: const [
                TextSpan(
                  text: ' *',
                  style: TextStyle(color: Color(0xFFFF7B82)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          FlutterFlowDropDown<String>(
            multiSelectController: _aircraftsController,
            options:
                List<String>.from(widget.aircrafts.map((e) => e.id).toList()),
            optionLabels:
                widget.aircrafts.map((e) => e.aircraftModel).toList(),
            onMultiSelectChanged: (val) =>
                setState(() => _selectedAircraftIds = val),
            height: 48.0,
            textStyle: GoogleFonts.roboto(
              color: Colors.white,
              fontSize: 13.5,
            ),
            hintText: 'Selecione as aeronaves',
            icon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Color(0x73FFFFFF),
              size: 24.0,
            ),
            fillColor: const Color(0xFF404040),
            elevation: 2.0,
            borderColor: const Color(0x22FFFFFF),
            borderWidth: 1.4,
            borderRadius: 10.0,
            margin: const EdgeInsetsDirectional.fromSTEB(12.0, 0.0, 12.0, 0.0),
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

/// Diálogo de criação de item de série — categoria, nome, quantidade e
/// vínculos de aeronave. Ao salvar, insere em `aircraft_items` (com
/// [guardInsert] — bloqueio mantém a modal aberta) e cria um vínculo em
/// `aircraft_item_links` por aeronave selecionada (também com [guardInsert]).
/// Retorna `true` no `Navigator.pop` quando persistiu.
class _CreateItemSeriesDialog extends StatefulWidget {
  const _CreateItemSeriesDialog({
    required this.categories,
    required this.aircrafts,
    this.initialCategoryId,
  });

  final List<CategoryRow> categories;
  final List<AircraftsRow> aircrafts;

  /// Pré-seleciona a categoria (vindo da tela Categorias via rota).
  final String? initialCategoryId;

  @override
  State<_CreateItemSeriesDialog> createState() =>
      _CreateItemSeriesDialogState();
}

class _CreateItemSeriesDialogState extends State<_CreateItemSeriesDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _qtyController;
  late final FormFieldController<String> _categoryController;
  late final FormFieldController<List<String>?> _aircraftsController;
  String? _selectedCategoryId;
  List<String>? _selectedAircraftIds;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _qtyController = TextEditingController();
    _selectedCategoryId = (widget.initialCategoryId ?? '').isNotEmpty
        ? widget.initialCategoryId
        : null;
    _categoryController = FormFieldController<String>(_selectedCategoryId ?? '');
    _selectedAircraftIds = null;
    _aircraftsController = FormFieldController<List<String>?>(null);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _qtyController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    final categoryId = _selectedCategoryId ?? '';
    final itemName = _nameController.text.trim();
    final qty = int.tryParse(_qtyController.text.trim());
    final selectedAircraftIds = _selectedAircraftIds?.toList() ?? <String>[];
    if (categoryId.isEmpty) {
      showWriteError(context, 'Selecione a categoria.');
      return;
    }
    if (itemName.isEmpty) {
      showWriteError(context, 'Informe o nome do item.');
      return;
    }
    if (qty == null) {
      showWriteError(context, 'Informe uma quantidade numérica.');
      return;
    }
    if (selectedAircraftIds.isEmpty) {
      showWriteError(context, 'Selecione ao menos uma aeronave.');
      return;
    }
    setState(() => _busy = true);
    try {
      final createdItem = await guardInsert(
        context,
        () => AircraftItemsTable().insert({
          'category_id': categoryId,
          'item_name': itemName,
          'qty': qty,
          'price': 0.00,
          'item_type': ItemType.series.name,
          'created_by': currentUserUid,
        }),
      );
      if (createdItem == null) return; // bloqueado — mantém a modal aberta.
      for (final aircraftId in selectedAircraftIds) {
        await guardInsert(
          context,
          () => AircraftItemLinksTable().insert({
            'aircraft_item_id': createdItem.id,
            'aircraft_id': aircraftId,
            'created_by': currentUserUid,
          }),
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppModal(
      icon: Icons.add_rounded,
      title: 'Adicionar item de série',
      description:
          'Informe a categoria, o nome, a quantidade e as aeronaves vinculadas.',
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
            onPressed: _submit,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              text: 'Categoria',
              style: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: const Color(0xCCFFFFFF),
                letterSpacing: 0.3,
              ),
              children: const [
                TextSpan(
                  text: ' *',
                  style: TextStyle(color: Color(0xFFFF7B82)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          FlutterFlowDropDown<String>(
            controller: _categoryController,
            options:
                List<String>.from(widget.categories.map((e) => e.id).toList()),
            optionLabels:
                widget.categories.map((e) => e.categoryName).toList(),
            onChanged: (val) => setState(() => _selectedCategoryId = val),
            height: 48.0,
            textStyle: GoogleFonts.roboto(
              color: Colors.white,
              fontSize: 13.5,
            ),
            hintText: 'Selecione a categoria',
            icon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Color(0x73FFFFFF),
              size: 24.0,
            ),
            fillColor: const Color(0xFF404040),
            elevation: 2.0,
            borderColor: const Color(0x22FFFFFF),
            borderWidth: 1.4,
            borderRadius: 10.0,
            margin: const EdgeInsetsDirectional.fromSTEB(12.0, 0.0, 12.0, 0.0),
            hidesUnderline: true,
            isOverButton: false,
            isSearchable: false,
            isMultiSelect: false,
          ),
          const SizedBox(height: 14),
          AppFormField(
            controller: _nameController,
            label: 'Nome do item',
            placeholder: 'Nome do item',
            icon: Icons.build_outlined,
            required: true,
          ),
          const SizedBox(height: 14),
          AppFormField(
            controller: _qtyController,
            label: 'Quantidade',
            placeholder: 'Qtd',
            icon: Icons.numbers_rounded,
            required: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 14),
          RichText(
            text: TextSpan(
              text: 'Aeronaves',
              style: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: const Color(0xCCFFFFFF),
                letterSpacing: 0.3,
              ),
              children: const [
                TextSpan(
                  text: ' *',
                  style: TextStyle(color: Color(0xFFFF7B82)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          FlutterFlowDropDown<String>(
            multiSelectController: _aircraftsController,
            options:
                List<String>.from(widget.aircrafts.map((e) => e.id).toList()),
            optionLabels:
                widget.aircrafts.map((e) => e.aircraftModel).toList(),
            onMultiSelectChanged: (val) =>
                setState(() => _selectedAircraftIds = val),
            height: 48.0,
            textStyle: GoogleFonts.roboto(
              color: Colors.white,
              fontSize: 13.5,
            ),
            hintText: 'Selecione as aeronaves',
            icon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Color(0x73FFFFFF),
              size: 24.0,
            ),
            fillColor: const Color(0xFF404040),
            elevation: 2.0,
            borderColor: const Color(0x22FFFFFF),
            borderWidth: 1.4,
            borderRadius: 10.0,
            margin: const EdgeInsetsDirectional.fromSTEB(12.0, 0.0, 12.0, 0.0),
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
