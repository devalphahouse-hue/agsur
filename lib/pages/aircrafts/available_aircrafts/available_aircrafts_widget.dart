import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';

import '/auth/supabase_auth/auth_util.dart';
import '/backend/paged_query.dart';
import '/backend/stock.dart';
import '/backend/supabase/supabase.dart';
import '/core_ui/core_ui.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/pages/modal_create_available_aircraft/modal_create_available_aircraft_widget.dart';
import '/security/access_control.dart';
import '/security/action_feedback.dart';
import '/security/write_guard.dart';
import 'available_aircrafts_model.dart';
import 'stock_entry_modal.dart';
import 'stock_move_modal.dart';
import 'stock_unit_history_dialog.dart';
import 'stock_widgets.dart';

export 'available_aircrafts_model.dart';

/// Estoque de aeronaves (migration 20260922120000).
///
/// Três visões sobre os mesmos dados:
/// - **Saldo** — quantidade por modelo do catálogo (em estoque, disponíveis,
///   em negociação, vendidas, outras saídas).
/// - **Aeronaves** — cada unidade física, com nº de série e prefixo.
/// - **Movimentações** — o livro-razão de entradas e saídas, imutável.
///
/// Entrada/saída/edição: só Admin Master e Admin documentação
/// ([AccessControl.canManageStock], espelho da guarda do banco). Venda não se
/// lança aqui: a aeronave sai do estoque sozinha quando a proposta vira
/// contrato, e volta se o contrato for cancelado.
class AvailableAircraftsWidget extends StatefulWidget {
  const AvailableAircraftsWidget({super.key});

  static String routeName = 'AvailableAircrafts';
  static String routePath = '/availableAircrafts';

  @override
  State<AvailableAircraftsWidget> createState() =>
      _AvailableAircraftsWidgetState();
}

enum _Tab { saldo, unidades, movimentacoes }

class _AvailableAircraftsWidgetState extends State<AvailableAircraftsWidget> {
  late AvailableAircraftsModel _model;
  bool _disposed = false;

  _Tab _tab = _Tab.saldo;
  String _query = '';
  Timer? _searchDebounce;

  // Aeronaves
  static const _unitFilters = ['Em estoque', 'Fora do estoque', 'Todas'];
  String _unitFilter = 'Em estoque';
  String? _modelFilterId;
  String? _modelFilterName;

  // Movimentações
  static const _typeFilters = ['Todas', 'Entradas', 'Saídas'];
  static const _periodFilters = ['30 dias', '90 dias', '12 meses', 'Tudo'];
  String _typeFilter = 'Todas';
  String _periodFilter = '90 dias';

  // Paginação por aba (1-based). Filtro/busca novos voltam para a página 1.
  int _saldoPage = 1, _saldoPerPage = kDefaultPerPage;
  int _unitsPage = 1, _unitsPerPage = kDefaultPerPage;
  int _movesPage = 1, _movesPerPage = kDefaultPerPage;

  /// Saldo: todas as unidades (a conta é por modelo, então precisa do todo;
  /// o volume é de dezenas/centenas de aviões) + quais modelos saíram do
  /// catálogo, para não parecerem duplicados na tabela.
  Future<(List<VwStockUnitsRow>, Set<String>)>? _saldoFuture;

  /// Aeronaves e Movimentações: paginadas NO SERVIDOR — todo filtro vai no
  /// queryFn (regra do `queryPage`; filtrar em Dart depois mentiria o total).
  Future<PagedResult<VwStockUnitsRow>>? _unitsFuture;
  Future<PagedResult<VwStockMovementsRow>>? _movesFuture;

  /// Aeronave → quantas propostas ATIVAS a escolheram (não excluída, ainda
  /// não convertida). "Em proposta" é calculado daqui, sem mexer no status.
  Future<Map<String, int>>? _proposalCountsFuture;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AvailableAircraftsModel());
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      try {
        final user = await QueryCache.fetch<List<UsersRow>>(
          key: 'aircrafts.currentUser:$currentUserUid',
          ttl: const Duration(minutes: 5),
          fetcher: () => UsersTable().queryRows(
            queryFn: (q) => q.eqOrNull('id', currentUserUid),
          ),
        );
        if (_disposed) return;
        _model.user = user;
        safeSetState(() {});
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _searchDebounce?.cancel();
    _model.dispose();
    super.dispose();
  }

  bool get _canManage => AccessControl.canManageStock(
      AccessControl.roleOf(_model.user?.firstOrNull));

  String get _q => _query.trim();

  Future<Map<String, int>> get _proposalCounts =>
      _proposalCountsFuture ??= () async {
        final rows = await ProposalTable().queryRows(
          queryFn: (q) => q
              .not('available_aircraft_id', 'is', null)
              .eq('is_contract', false)
              .eq('is_deleted', false)
              .eq('active', true),
        );
        final map = <String, int>{};
        for (final p in rows) {
          final id = p.availableAircraftId;
          if (id != null) map[id] = (map[id] ?? 0) + 1;
        }
        return map;
      }();

  Future<(List<VwStockUnitsRow>, Set<String>)> get _saldo =>
      _saldoFuture ??= () async {
        final units = await VwStockUnitsTable().queryRows(queryFn: (q) => q);
        final ids = units.map((u) => u.aircraftId).toSet().toList();
        final removed = ids.isEmpty
            ? <String>{}
            : (await AircraftsTable().queryRows(
                queryFn: (q) => q.inFilter('id', ids).eq('deleted', true),
              ))
                .map((a) => a.id)
                .toSet();
        return (units, removed);
      }();

  Future<PagedResult<VwStockUnitsRow>> get _units =>
      _unitsFuture ??= queryPage(
        table: VwStockUnitsTable(),
        page: _unitsPage,
        perPage: _unitsPerPage,
        queryFn: (q) {
          var f = q;
          if (_modelFilterId != null) f = f.eq('aircraft_id', _modelFilterId!);
          if (_unitFilter == 'Em estoque') f = f.eq('in_stock', true);
          if (_unitFilter == 'Fora do estoque') f = f.eq('in_stock', false);
          if (_q.isNotEmpty) {
            f = f.or(orIlike(
                ['aircraft_model_name', 'serial_number', 'registration_prefix'],
                _q));
          }
          return f
              .order('featured', ascending: false)
              .order('aircraft_model_name')
              .order('serial_number');
        },
      );

  Future<PagedResult<VwStockMovementsRow>> get _moves =>
      _movesFuture ??= queryPage(
        table: VwStockMovementsTable(),
        page: _movesPage,
        perPage: _movesPerPage,
        queryFn: (q) {
          final since = switch (_periodFilter) {
            '30 dias' => DateTime.now().subtract(const Duration(days: 30)),
            '90 dias' => DateTime.now().subtract(const Duration(days: 90)),
            '12 meses' => DateTime.now().subtract(const Duration(days: 365)),
            _ => null,
          };
          var f = q;
          if (since != null) {
            f = f.gte('created_at', since.toUtc().toIso8601String());
          }
          if (_typeFilter == 'Entradas') f = f.eq('movement_type', 'entrada');
          if (_typeFilter == 'Saídas') f = f.eq('movement_type', 'saida');
          if (_q.isNotEmpty) {
            f = f.or(orIlike(
                ['aircraft_model_name', 'serial_number', 'note'], _q));
          }
          return f.order('created_at', ascending: false);
        },
      );

  /// Recarrega tudo (depois de entrada/saída/edição).
  void _refresh() {
    // O seletor da proposta/contrato cacheia as unidades (loadStockUnits).
    QueryCache.invalidate('stock.units');
    safeSetState(() {
      _saldoFuture = null;
      _unitsFuture = null;
      _movesFuture = null;
      _proposalCountsFuture = null;
    });
  }

  /// Filtro/busca mudou: volta para a página 1 das listas paginadas.
  void _resetPaging() {
    _saldoPage = 1;
    _unitsPage = 1;
    _movesPage = 1;
    _unitsFuture = null;
    _movesFuture = null;
  }

  void _onSearch(String v) {
    setState(() => _query = v);
    // Aeronaves/Movimentações consultam o servidor: espera parar de digitar.
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) setState(_resetPaging);
    });
  }

  // ── Ações ────────────────────────────────────────────────────────────────

  Future<void> _openEntry() async {
    final count = await showStockDialog<int>(context, const StockEntryModal());
    if (count == null || !mounted) return;
    _refresh();
    showActionSuccess(
      context,
      count == 1
          ? 'Entrada registrada: 1 aeronave'
          : 'Entrada registrada: $count aeronaves',
    );
  }

  Future<void> _openMove(VwStockUnitsRow unit, {required bool isExit}) async {
    final ok = await showStockDialog<bool>(
      context,
      StockMoveModal(unit: unit, isExit: isExit),
    );
    if (ok != true || !mounted) return;
    _refresh();
    showActionSuccess(
        context, isExit ? 'Saída registrada' : 'Aeronave devolvida ao estoque');
  }

  Future<void> _openHistory(VwStockUnitsRow unit) =>
      showStockDialog(context, StockUnitHistoryDialog(unit: unit));

  Future<void> _openEdit(VwStockUnitsRow unit) async {
    await showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        elevation: 0,
        insetPadding: EdgeInsets.zero,
        backgroundColor: Colors.transparent,
        alignment: Alignment.center,
        child: GestureDetector(
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: ModalCreateAvailableAircraftWidget(
            type: 'edit',
            id: unit.id,
            btnAction: (idAeronave, numeroSerie, dataFabricacao,
                prazoConfiguracao, dataEntrega, createdBy, anoBase, status,
                updateBy, id, prefixo) async {
              // guardWrite pega o UPDATE bloqueado em silêncio pela RLS;
              // runAction cobre exceção real (serial repetido, guarda do
              // banco) e fecha o diálogo nos dois caminhos. `in_stock` não
              // vai no payload: só o livro-razão mexe nele.
              var gravou = false;
              final ok = await runAction(
                context,
                dialogContext: dialogContext,
                contexto: 'estoque.editar_unidade',
                failure: 'Não foi possível salvar a aeronave.',
                action: () async {
                  gravou = await guardWrite(
                    context,
                    () => AvailableAircraftsTable().update(
                      data: {
                        'aircraft_model': idAeronave,
                        'serial_number': numeroSerie.trim(),
                        'registration_prefix':
                            (prefixo ?? '').isEmpty ? null : prefixo,
                        'manufacture_date':
                            supaSerialize<DateTime>(dataFabricacao),
                        'configuration_deadline':
                            supaSerialize<DateTime>(prazoConfiguracao),
                        'delivery_date': supaSerialize<DateTime>(dataEntrega),
                        'status': status,
                        'update_by': updateBy,
                        'entry_year': anoBase,
                      },
                      matchingRows: (rows) => rows.eqOrNull('id', unit.id),
                      returnRows: true,
                    ),
                    contexto: 'estoque.editar_unidade',
                  );
                },
              );
              if (!mounted || !ok || !gravou) return;
              _refresh();
              showActionSuccess(context, 'Aeronave atualizada');
            },
          ),
        ),
      ),
    );
  }

  // ── Layout ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AppListScaffold(
      eyebrow: 'Operação',
      title: 'Estoque de aeronaves',
      description:
          'Os aviões físicos que a AGSur tem hoje — o que ela vende fica no '
          'Catálogo. A venda dá baixa sozinha quando a proposta vira contrato.',
      actions: [
        if (_canManage)
          AppPrimaryButton(
            label: 'Registrar entrada',
            icon: Icons.move_to_inbox_rounded,
            onPressed: _openEntry,
          ),
      ],
      search: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _Segmented<_Tab>(
            value: _tab,
            options: const {
              _Tab.saldo: 'Resumo por modelo',
              _Tab.unidades: 'Aeronaves',
              _Tab.movimentacoes: 'Movimentações',
            },
            // Cada aba busca por coisa diferente (Resumo: modelo; Aeronaves:
            // serial/prefixo; Movimentações: observação). Carregar a busca de
            // uma para outra dava "nenhum resultado" sem motivo aparente
            // (QA de 2026-09-22) — trocar de aba começa limpo.
            onChanged: (t) => setState(() {
              if (t == _tab) return;
              _tab = t;
              _searchDebounce?.cancel();
              _query = '';
              _resetPaging();
            }),
          ),
          AppSearchInput(
            value: _query,
            placeholder: switch (_tab) {
              _Tab.saldo => 'Buscar modelo...',
              _Tab.unidades => 'Buscar modelo, serial ou prefixo...',
              _Tab.movimentacoes => 'Buscar modelo, serial ou observação...',
            },
            onChanged: _onSearch,
          ),
          if (_tab == _Tab.unidades) ...[
            _FilterChips(
              label: 'Mostrar',
              options: _unitFilters,
              value: _unitFilter,
              onChanged: (v) => setState(() {
                _unitFilter = v;
                _resetPaging();
              }),
            ),
            if (_modelFilterId != null)
              InputChip(
                label: Text(_modelFilterName ?? 'Modelo'),
                onDeleted: () => setState(() {
                  _modelFilterId = null;
                  _modelFilterName = null;
                  _resetPaging();
                }),
              ),
          ],
          if (_tab == _Tab.movimentacoes) ...[
            _FilterChips(
              label: 'Tipo',
              options: _typeFilters,
              value: _typeFilter,
              onChanged: (v) => setState(() {
                _typeFilter = v;
                _resetPaging();
              }),
            ),
            _FilterChips(
              label: 'Período',
              options: _periodFilters,
              value: _periodFilter,
              onChanged: (v) => setState(() {
                _periodFilter = v;
                _resetPaging();
              }),
            ),
          ],
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StockHelp(tab: _tab),
          const SizedBox(height: 14),
          switch (_tab) {
            _Tab.saldo => _buildSaldo(),
            _Tab.unidades => _buildUnidades(),
            _Tab.movimentacoes => _buildMovimentacoes(),
          },
        ],
      ),
    );
  }

  Widget _loading() => Column(
        children: List.generate(
          6,
          (_) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: AppSkeleton.box(height: 52),
          ),
        ),
      );

  Widget _error() => const AppCard(
        child: AppEmptyState(
          icon: Icons.error_outline_rounded,
          title: 'Não foi possível carregar o estoque',
          description: 'Atualize a página e tente de novo.',
        ),
      );

  Widget _empty(IconData icon, String title, String description) => AppCard(
        child: AppEmptyState(icon: icon, title: title, description: description),
      );

  /// Nome do modelo com ★ de destaque e selo de removido do catálogo.
  Widget _modelCell(String name, {bool featured = false, bool removed = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (featured) ...[
          const Icon(Icons.star_rounded, size: 15, color: Color(0xFFFFC857)),
          const SizedBox(width: 4),
        ],
        Flexible(
          child: AppCellText(name.trim().isEmpty ? 'Modelo sem nome' : name.trim(),
              bold: true),
        ),
        if (removed) ...[
          const SizedBox(width: 8),
          const Tooltip(
            message: 'Este modelo foi removido do catálogo — a AGSur não o '
                'vende mais —, mas ainda há aeronave física dele registrada '
                'no estoque.',
            child: AppStatusBadge(
                label: 'Saiu do catálogo',
                tone: AppStatusTone.neutral,
                dense: true),
          ),
        ],
      ],
    );
  }

  Widget _count(int n, {Color? color}) => Text(
        '$n',
        style: GoogleFonts.inter(
          fontSize: 13.5,
          fontWeight: FontWeight.w700,
          color: n == 0 ? const Color(0x55FFFFFF) : (color ?? Colors.white),
        ),
      );

  // ── Saldo ────────────────────────────────────────────────────────────────

  Widget _buildSaldo() {
    return FutureBuilder<List<Object>>(
      // Key por aba: sem ela o Flutter reaproveita o FutureBuilder da aba
      // anterior (mesmo tipo, mesma posição) e o snapshot antigo chega aqui
      // com outro formato — era o fundo vermelho ao trocar Resumo↔Aeronaves.
      key: const ValueKey('estoque.resumo'),
      future: Future.wait<Object>([_saldo, _proposalCounts]),
      builder: (context, snap) {
        if (snap.hasError) return _error();
        if (!snap.hasData) return _loading();
        final (units, removed) =
            snap.data![0] as (List<VwStockUnitsRow>, Set<String>);
        final proposals = snap.data![1] as Map<String, int>;
        final q = _q.toLowerCase();
        final balances = summarizeStock(units.map((u) => StockUnitSnapshot(
                  modelId: u.aircraftId,
                  modelName: u.aircraftModelName.trim(),
                  inStock: u.inStock,
                  status: u.status,
                  featured: u.featured,
                  hasActiveContract: u.contractId != null,
                  openProposals: proposals[u.id] ?? 0,
                )))
            .where((b) => q.isEmpty || b.modelName.toLowerCase().contains(q))
            .toList();
        if (balances.isEmpty) {
          return _empty(
            Icons.warehouse_outlined,
            q.isEmpty ? 'Estoque vazio' : 'Nenhum modelo encontrado',
            q.isNotEmpty
                ? 'Tente outro termo de busca.'
                : _canManage
                    ? 'Use "Registrar entrada" para cadastrar as aeronaves.'
                    : 'Nenhuma aeronave cadastrada no estoque.',
          );
        }
        // Agregado: pagina em memória.
        final pageCount =
            ((balances.length + _saldoPerPage - 1) ~/ _saldoPerPage).clamp(1, 1 << 30);
        final page = _saldoPage.clamp(1, pageCount);
        final from = (page - 1) * _saldoPerPage;
        final paged = PagedResult<StockModelBalance>(
          items: balances.skip(from).take(_saldoPerPage).toList(),
          total: balances.length,
          page: page,
          perPage: _saldoPerPage,
        );
        final totalIn = balances.fold<int>(0, (s, b) => s + b.inStock);
        final totalAvail = balances.fold<int>(0, (s, b) => s + b.available);
        final totalProp = balances.fold<int>(0, (s, b) => s + b.inProposal);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  AppStatusBadge(
                    label: '$totalIn em estoque',
                    icon: Icons.warehouse_outlined,
                    tone: AppStatusTone.brand,
                  ),
                  AppStatusBadge(
                    label: '$totalAvail livre(s) para oferecer',
                    icon: Icons.check_circle_outline_rounded,
                    tone: AppStatusTone.success,
                  ),
                  AppStatusBadge(
                    label: '$totalProp em proposta',
                    icon: Icons.request_quote_outlined,
                    tone: AppStatusTone.warning,
                  ),
                  AppStatusBadge(
                    label: '${balances.length} modelo(s)',
                    icon: Icons.flight_outlined,
                    tone: AppStatusTone.neutral,
                  ),
                ],
              ),
            ),
            AppDataTable<StockModelBalance>(
              items: paged.items,
              rowId: (b) => b.modelId,
              minWidth: 900,
              // Clique leva para a aba Aeronaves filtrada pelo modelo.
              onRowTap: (b) => setState(() {
                _modelFilterId = b.modelId;
                _modelFilterName = b.modelName;
                _unitFilter = 'Todas';
                _tab = _Tab.unidades;
                _query = '';
                _resetPaging();
              }),
              columns: [
                AppDataColumn(
                  label: 'Modelo',
                  flex: 4,
                  cell: (b) => _modelCell(b.modelName,
                      featured: b.featured, removed: removed.contains(b.modelId)),
                ),
                AppDataColumn(
                  label: 'Em estoque',
                  width: 100,
                  align: Alignment.center,
                  cell: (b) => _count(b.inStock, color: const Color(0xFFC2D51C)),
                ),
                AppDataColumn(
                  label: 'Disponíveis',
                  width: 100,
                  align: Alignment.center,
                  cell: (b) => Tooltip(
                    message: 'No estoque, sem proposta e sem reserva',
                    child: _count(b.available, color: const Color(0xFF4ADE80)),
                  ),
                ),
                AppDataColumn(
                  label: 'Em proposta',
                  width: 105,
                  align: Alignment.center,
                  cell: (b) => Tooltip(
                    message: 'No estoque e escolhidas em proposta ativa '
                        '(saem quando a proposta vira contrato)',
                    child: _count(b.inProposal, color: const Color(0xFFFFC857)),
                  ),
                ),
                AppDataColumn(
                  label: 'Reservadas',
                  width: 100,
                  align: Alignment.center,
                  cell: (b) => Tooltip(
                    message: 'Marcadas à mão como Reservado ou Em negociação, '
                        'sem proposta',
                    child: _count(b.reserved, color: const Color(0xFFFFC857)),
                  ),
                ),
                AppDataColumn(
                  label: 'Vendidas',
                  width: 90,
                  align: Alignment.center,
                  cell: (b) => _count(b.sold, color: const Color(0xFFFF7B82)),
                ),
                AppDataColumn(
                  label: 'Outras saídas',
                  width: 110,
                  align: Alignment.center,
                  cell: (b) => Tooltip(
                    message: 'Baixa, devolução ao fabricante ou ajuste de '
                        'inventário — saída sem ser por venda',
                    child: _count(b.otherOut),
                  ),
                ),
                AppDataColumn(
                  label: 'Total',
                  width: 70,
                  align: Alignment.center,
                  cell: (b) => _count(b.total),
                ),
              ],
            ),
            AppPagination(
              result: paged,
              onPageChanged: (p) => setState(() => _saldoPage = p),
              onPerPageChanged: (n) => setState(() {
                _saldoPerPage = n;
                _saldoPage = 1;
              }),
            ),
          ],
        );
      },
    );
  }

  // ── Aeronaves ────────────────────────────────────────────────────────────

  Widget _buildUnidades() {
    return FutureBuilder<List<Object>>(
      key: const ValueKey('estoque.aeronaves'),
      future: Future.wait<Object>([_units, _proposalCounts]),
      builder: (context, snap) {
        if (snap.hasError) return _error();
        if (!snap.hasData) return _loading();
        final paged = snap.data![0] as PagedResult<VwStockUnitsRow>;
        final proposals = snap.data![1] as Map<String, int>;
        if (paged.total == 0) {
          return _empty(Icons.flight_outlined, 'Nenhuma aeronave',
              'Nenhuma aeronave para a busca e os filtros atuais.');
        }
        return Column(
          children: [
            AppDataTable<VwStockUnitsRow>(
              items: paged.items,
              rowId: (u) => u.id,
              minWidth: 980,
              onRowTap: (u) => _canManage ? _openEdit(u) : _openHistory(u),
              columns: [
                AppDataColumn(
                  label: 'Modelo',
                  flex: 3,
                  cell: (u) => _modelCell(u.aircraftModelName, featured: u.featured),
                ),
                AppDataColumn(
                  label: 'Nº de série',
                  flex: 2,
                  cell: (u) => AppCellText(u.serialNumber, bold: true),
                ),
                AppDataColumn(
                  label: 'Prefixo',
                  width: 100,
                  cell: (u) => AppCellText(
                      (u.registrationPrefix ?? '').isEmpty
                          ? '—'
                          : u.registrationPrefix!,
                      muted: true),
                ),
                AppDataColumn(
                  label: 'Fabricação',
                  width: 100,
                  cell: (u) =>
                      AppCellText(formatStockDate(u.manufactureDate), muted: true),
                ),
                AppDataColumn(
                  label: 'Entrega',
                  width: 100,
                  cell: (u) =>
                      AppCellText(formatStockDate(u.deliveryDate), muted: true),
                ),
                AppDataColumn(
                  label: 'Status',
                  width: 220,
                  cell: (u) => Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      AppStatusBadge(
                        label: u.status.isEmpty ? '—' : u.status,
                        tone: stockStatusTone(u.status, inStock: u.inStock),
                        dense: true,
                      ),
                      if (u.contractId != null)
                        const AppStatusBadge(
                          label: 'Contrato',
                          icon: Icons.description_outlined,
                          tone: AppStatusTone.brand,
                          dense: true,
                        )
                      else if (u.inStock && (proposals[u.id] ?? 0) > 0)
                        AppStatusBadge(
                          label: (proposals[u.id] ?? 0) == 1
                              ? 'Em 1 proposta'
                              : 'Em ${proposals[u.id]} propostas',
                          icon: Icons.request_quote_outlined,
                          tone: AppStatusTone.warning,
                          dense: true,
                        ),
                    ],
                  ),
                ),
                AppDataColumn(
                  label: 'Ações',
                  width: 84,
                  align: Alignment.centerRight,
                  cell: (u) => Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppRowAction(
                        icon: Icons.history_rounded,
                        tooltip: 'Histórico',
                        onPressed: () => _openHistory(u),
                      ),
                      // Aeronave presa a contrato ativo só se movimenta pelo
                      // contrato (cancelar ou trocar a aeronave lá).
                      if (_canManage && u.contractId == null) ...[
                        const SizedBox(width: 4),
                        u.inStock
                            ? AppRowAction(
                                icon: Icons.outbox_rounded,
                                tooltip: 'Registrar saída',
                                danger: true,
                                onPressed: () => _openMove(u, isExit: true),
                              )
                            : AppRowAction(
                                icon: Icons.move_to_inbox_rounded,
                                tooltip: 'Devolver ao estoque',
                                onPressed: () => _openMove(u, isExit: false),
                              ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            AppPagination(
              result: paged,
              onPageChanged: (p) => setState(() {
                _unitsPage = p;
                _unitsFuture = null;
              }),
              onPerPageChanged: (n) => setState(() {
                _unitsPerPage = n;
                _unitsPage = 1;
                _unitsFuture = null;
              }),
            ),
          ],
        );
      },
    );
  }

  // ── Movimentações ────────────────────────────────────────────────────────

  Widget _buildMovimentacoes() {
    return FutureBuilder<PagedResult<VwStockMovementsRow>>(
      key: const ValueKey('estoque.movimentacoes'),
      future: _moves,
      builder: (context, snap) {
        if (snap.hasError) return _error();
        if (!snap.hasData) return _loading();
        final paged = snap.data!;
        if (paged.total == 0) {
          return _empty(Icons.swap_vert_rounded, 'Nenhuma movimentação',
              'Nada registrado no período e filtros escolhidos.');
        }
        return Column(
          children: [
            AppDataTable<VwStockMovementsRow>(
              items: paged.items,
              rowId: (m) => m.id,
              minWidth: 980,
              columns: [
                AppDataColumn(
                  label: 'Data',
                  width: 130,
                  cell: (m) =>
                      AppCellText(formatStockDateTime(m.createdAt), muted: true),
                ),
                AppDataColumn(
                  label: 'Tipo',
                  width: 100,
                  cell: (m) => AppStatusBadge(
                    label: m.isEntrada ? 'Entrada' : 'Saída',
                    icon: m.isEntrada
                        ? Icons.south_west_rounded
                        : Icons.north_east_rounded,
                    tone: m.isEntrada
                        ? AppStatusTone.success
                        : AppStatusTone.danger,
                    dense: true,
                  ),
                ),
                AppDataColumn(
                  label: 'Motivo',
                  flex: 2,
                  cell: (m) => AppCellText(stockReasonLabel(m.reason)),
                ),
                AppDataColumn(
                  label: 'Modelo',
                  flex: 2,
                  cell: (m) => AppCellText(m.aircraftModelName.trim(), bold: true),
                ),
                AppDataColumn(
                  label: 'Nº de série',
                  flex: 2,
                  cell: (m) => AppCellText(m.serialNumber),
                ),
                AppDataColumn(
                  label: 'Observação',
                  flex: 3,
                  cell: (m) => Tooltip(
                    message: m.note ?? '',
                    child: Text(
                      (m.note ?? '').isEmpty ? '—' : m.note!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        color: const Color(0xB3FFFFFF),
                      ),
                    ),
                  ),
                ),
                AppDataColumn(
                  label: 'Por',
                  flex: 2,
                  cell: (m) => AppCellText(
                      (m.createdByName ?? '').isEmpty ? 'Sistema' : m.createdByName!,
                      muted: true),
                ),
              ],
            ),
            AppPagination(
              result: paged,
              onPageChanged: (p) => setState(() {
                _movesPage = p;
                _movesFuture = null;
              }),
              onPerPageChanged: (n) => setState(() {
                _movesPerPage = n;
                _movesPage = 1;
                _movesFuture = null;
              }),
            ),
          ],
        );
      },
    );
  }
}

// ── Ajuda: o que é cada coisa (pedido do cliente) ─────────────────────────

/// Painel "Como ler esta tela", recolhível. Abre expandido na primeira vez e
/// lembra a escolha enquanto o painel estiver aberto no navegador.
class _StockHelp extends StatefulWidget {
  const _StockHelp({required this.tab});
  final _Tab tab;

  @override
  State<_StockHelp> createState() => _StockHelpState();
}

class _StockHelpState extends State<_StockHelp> {
  static bool _open = true;

  static const _catalogVsStock = [
    ('Catálogo',
        'os MODELOS que a AGSur vende (tela Catálogo de aeronaves). É dele '
            'que vêm a '
            'descrição técnica e o preço da proposta.'),
    ('Estoque',
        'os AVIÕES FÍSICOS que a AGSur já tem, cada um com o seu número de '
            'série. Um modelo do catálogo pode ter vários aviões no estoque — '
            'ou nenhum.'),
  ];

  List<(String, String)> get _items => switch (widget.tab) {
        _Tab.saldo => const [
            ('Em estoque',
                'aviões que estão no estoque agora. É a soma de Disponíveis + '
                    'Em proposta + Reservadas.'),
            ('Disponíveis', 'no estoque e livres para oferecer a um cliente.'),
            ('Em proposta',
                'no estoque, mas já escolhidos numa proposta em andamento. '
                    'Saem do estoque sozinhos quando a proposta vira contrato.'),
            ('Reservadas',
                'no estoque e marcadas à mão como Reservado ou Em negociação, '
                    'sem proposta (ex.: segurar para um cliente).'),
            ('Vendidas', 'saíram do estoque por um contrato.'),
            ('Outras saídas',
                'saíram sem ser por venda: baixa, devolução ao fabricante ou '
                    'ajuste de inventário.'),
            ('Total', 'todos os aviões desse modelo que já passaram pelo estoque.'),
            ('★', 'modelo em destaque no catálogo.'),
            ('Saiu do catálogo',
                'o modelo foi removido do catálogo (não é mais vendido), mas '
                    'ainda há avião dele registrado no estoque.'),
          ],
        _Tab.unidades => const [
            ('Cada linha', 'é um avião físico, identificado pelo número de série.'),
            ('Prefixo',
                'matrícula na ANAC (ex.: PR-ABC). Fica vazio até o registro.'),
            ('Status',
                'Disponível / Reservado / Em negociação enquanto está no '
                    'estoque; Vendido, Entregue ou Baixado depois que sai.'),
            ('Em N propostas',
                'quantas propostas em andamento escolheram este avião. A '
                    'primeira que virar contrato leva.'),
            ('Ações',
                'histórico do avião e registrar saída (baixa) ou devolver ao '
                    'estoque. Avião em contrato só se movimenta pelo contrato.'),
            ('Clique na linha', 'para editar prefixo, datas e status.'),
          ],
        _Tab.movimentacoes => const [
            ('Entrada', 'avião que entrou no estoque (compra, importação, devolução).'),
            ('Saída',
                'avião que saiu: venda (automática, ao virar contrato), baixa, '
                    'devolução ao fabricante.'),
            ('Histórico permanente',
                'nenhum lançamento é apagado. Um erro se corrige com um novo '
                    'lançamento de "Ajuste de inventário".'),
          ],
      };

  @override
  Widget build(BuildContext context) {
    final items = [
      if (widget.tab == _Tab.saldo) ..._catalogVsStock,
      ..._items,
    ];
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () => setState(() => _open = !_open),
            borderRadius: BorderRadius.circular(8),
            child: Row(
              children: [
                const Icon(Icons.help_outline_rounded,
                    size: 18, color: Color(0xFFC2D51C)),
                const SizedBox(width: 8),
                Text(
                  'Como ler esta tela',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                Icon(
                  _open
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  color: const Color(0x99FFFFFF),
                ),
              ],
            ),
          ),
          if (_open) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 28,
              runSpacing: 8,
              children: [
                for (final (term, text) in items)
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: RichText(
                      text: TextSpan(
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          height: 1.4,
                          color: const Color(0xB3FFFFFF),
                        ),
                        children: [
                          TextSpan(
                            text: '$term: ',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          TextSpan(text: text),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Segmented<T> extends StatelessWidget {
  const _Segmented({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final T value;
  final Map<T, String> options;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0x14FFFFFF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0x22FFFFFF)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final e in options.entries)
            GestureDetector(
              onTap: () => onChanged(e.key),
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: e.key == value
                        ? const Color(0xFFC2D51C)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    e.value,
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: e.key == value
                          ? const Color(0xFF313131)
                          : const Color(0xCCFFFFFF),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({
    required this.label,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final List<String> options;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0x14FFFFFF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0x22FFFFFF)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label:',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: const Color(0x99FFFFFF),
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(width: 8),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isDense: true,
              dropdownColor: const Color(0xFF2A2A2A),
              icon: const Icon(Icons.expand_more_rounded,
                  color: Color(0xFFC2D51C), size: 18),
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              items: [
                for (final opt in options)
                  DropdownMenuItem(value: opt, child: Text(opt)),
              ],
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
            ),
          ),
        ],
      ),
    );
  }
}
