import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/backend/supabase/supabase.dart';
import '/core_ui/core_ui.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'registed_aircraft_model.dart';
export 'registed_aircraft_model.dart';

/// Formata inteiro com separador de milhar (padrão pt-BR): 1251990 -> 1.251.990
String _thousands(int v) {
  final s = v.abs().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
    b.write(s[i]);
  }
  return '${v < 0 ? '-' : ''}$b';
}

String _fmtUsd(num v) => 'US\$ ${_thousands(v.round())}';

// Paleta do design system (espelha core_ui / FlutterFlowTheme).
const _kBrand = Color(0xFFC2D51C);
const _kCardImageBg = Color(0xFF2E2E2E);

class RegistedAircraftWidget extends StatefulWidget {
  const RegistedAircraftWidget({super.key});

  static String routeName = 'RegistedAircraft';
  static String routePath = '/registedAircraft';

  @override
  State<RegistedAircraftWidget> createState() => _RegistedAircraftWidgetState();
}

class _RegistedAircraftWidgetState extends State<RegistedAircraftWidget> {
  late RegistedAircraftModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  // ── Paginação server-side ─────────────────────────────────────────
  // 6 por página: com poucos modelos já demonstra a paginação; ajuste à
  // vontade (a barra some sozinha quando tudo cabe em 1 página).
  static const int _perPage = 6;
  int _page = 0; // 0-based
  List<AircraftsRow> _items = [];
  int _total = 0;
  bool _loading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => RegistedAircraftModel());

    _model.tFSearchAircraftTextController ??= TextEditingController();
    _model.tFSearchAircraftFocusNode ??= FocusNode();

    _load();
    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  String get _query => _model.tFSearchAircraftTextController?.text ?? '';

  int get _totalPages =>
      _total <= 0 ? 1 : ((_total + _perPage - 1) ~/ _perPage);

  /// Carrega SÓ a página atual no backend (range = page × perPage) e a
  /// contagem total (CountOption.exact) num único request. Mantém os
  /// cards atuais visíveis enquanto a próxima página chega.
  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    try {
      final from = _page * _perPage;
      final res = await SupaFlow.client
          .from('aircrafts')
          .select('*')
          .eq('deleted', false)
          .ilike('aircraft_model', '%$_query%')
          .order('aircraft_model', ascending: true)
          .range(from, from + _perPage - 1)
          .count(CountOption.exact);
      if (!mounted) return;
      final rows = res.data
          .map((d) => AircraftsRow(Map<String, dynamic>.from(d)))
          .toList();
      final total = res.count;
      final pages = total <= 0 ? 1 : ((total + _perPage - 1) ~/ _perPage);
      // Página fora do range (ex.: após exclusão): recua e recarrega.
      if (_page > pages - 1 && _page > 0) {
        _page = pages - 1;
        return _load();
      }
      setState(() {
        _items = rows;
        _total = total;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  void _resetAndReload() {
    _page = 0;
    _load();
  }

  void _goToPage(int page) {
    if (page == _page) return;
    _page = page;
    _load();
  }

  // ─────────────────────────── Paginação ─────────────────────────────
  Widget _pagination(int totalPages) {
    if (totalPages <= 1) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _pagerBtn(Icons.chevron_left_rounded, _page > 0,
              () => _goToPage(_page - 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text(
              'Página ${_page + 1} de $totalPages',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xCCFFFFFF),
              ),
            ),
          ),
          _pagerBtn(Icons.chevron_right_rounded, _page < totalPages - 1,
              () => _goToPage(_page + 1)),
        ],
      ),
    );
  }

  Widget _pagerBtn(IconData icon, bool enabled, VoidCallback onTap) {
    // IconButton: hit-testing robusto do Material (lida com a arena de
    // gestos e o scroll sem perder o toque).
    return IconButton(
      onPressed: enabled ? onTap : null,
      icon: Icon(icon, size: 22),
      color: _kBrand,
      disabledColor: const Color(0x44FFFFFF),
      style: IconButton.styleFrom(
        backgroundColor:
            enabled ? const Color(0x14FFFFFF) : const Color(0x0AFFFFFF),
        side: BorderSide(
          color: enabled ? const Color(0x33C2D51C) : const Color(0x18FFFFFF),
        ),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _errorState(Object? error) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0x22FF5963),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.error_outline_rounded,
                size: 32, color: Color(0xFFFF7B82)),
          ),
          const SizedBox(height: 18),
          Text(
            'Erro ao carregar o catálogo',
            style: GoogleFonts.inter(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$error',
            textAlign: TextAlign.center,
            style: GoogleFonts.roboto(
              fontSize: 12.5,
              color: const Color(0x99FFFFFF),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          AppPrimaryButton(
            label: 'Tentar de novo',
            icon: Icons.refresh_rounded,
            onPressed: _load,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppDetailsScaffold(
      title: 'Catálogo de aeronaves',
      subtitle:
          'Modelos que a AGSur vende — foto, especificações e preço base. '
          'Unidades físicas (com serial) ficam no menu Estoque.',
      actions: [
        AppPrimaryButton(
          label: 'Novo modelo',
          icon: Icons.add_rounded,
          onPressed: () => context.pushNamed(CreateAircraftWidget.routeName),
        ),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Toolbar: busca + contagem ──────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: Wrap(
              spacing: 12,
              runSpacing: 10,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                AppSearchInput(
                  value: _query,
                  placeholder: 'Buscar modelo...',
                  width: 300,
                  onChanged: (v) {
                    _model.tFSearchAircraftTextController?.text = v;
                    _resetAndReload();
                  },
                ),
                if (!(_loading && _items.isEmpty))
                  Text(
                    '$_total ${_total == 1 ? 'modelo' : 'modelos'}',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: const Color(0x99FFFFFF),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // ── Conteúdo ───────────────────────────────────────────────
          if (_error != null)
            _errorState(_error)
          else if (_loading && _items.isEmpty)
            _skeletonGrid()
          else if (_items.isEmpty)
            _emptyState(_query.isNotEmpty)
          else ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: _responsiveGrid(
                _items.length,
                (w, i) => _aircraftCard(_items[i], w),
              ),
            ),
            _pagination(_totalPages),
          ],
        ],
      ),
    );
  }

  // ─────────────────────── Grid responsivo ───────────────────────────
  /// Calcula colunas pela largura disponível (card mínimo ~300px) e
  /// estica os cards para preencher a linha inteira — sem sobra à direita.
  Widget _responsiveGrid(int count, Widget Function(double w, int i) build) {
    return LayoutBuilder(
      builder: (context, c) {
        const spacing = 18.0;
        const minCard = 300.0;
        final avail = c.maxWidth;
        var cols = ((avail + spacing) / (minCard + spacing)).floor();
        cols = cols.clamp(1, 4);
        final cardW = (avail - spacing * (cols - 1)) / cols;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [for (var i = 0; i < count; i++) build(cardW, i)],
        );
      },
    );
  }

  // ─────────────────────────── Card ──────────────────────────────────
  Widget _aircraftCard(AircraftsRow item, double width) {
    // Abre o formulário (create/edit) já preenchido com os dados do modelo.
    void openDetails() => context.pushNamed(
          CreateAircraftWidget.routeName,
          queryParameters: {
            'aircraftId': serializeParam(item.id, ParamType.String),
          }.withoutNulls,
        );

    return SizedBox(
      width: width,
      child: AppCard(
        padding: EdgeInsets.zero,
        borderRadius: 18,
        glow: true,
        onTap: openDetails,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Imagem + overlays
              Stack(
                children: [
                  SizedBox(
                    height: 176,
                    width: double.infinity,
                    child: Image.network(
                      item.aircraftPhotoUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _imageFallback(),
                      loadingBuilder: (c, child, progress) => progress == null
                          ? child
                          : AppSkeleton.box(height: 176, radius: 0),
                    ),
                  ),
                  const Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.transparent,
                            Color(0xCC1A1A1A),
                          ],
                          stops: [0.0, 0.55, 1.0],
                        ),
                      ),
                    ),
                  ),
                  // Nome do modelo sobre a imagem
                  Positioned(
                    left: 16,
                    right: 56,
                    bottom: 12,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Air Tractor',
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: _kBrand,
                            letterSpacing: 0.6,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          item.aircraftModel.trim(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -0.3,
                            shadows: const [
                              Shadow(color: Color(0x99000000), blurRadius: 8),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Botão remover (com confirmação)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Material(
                      color: const Color(0x73000000),
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => _confirmDelete(item),
                        child: const Padding(
                          padding: EdgeInsets.all(8),
                          child: Icon(
                            Icons.delete_outline_rounded,
                            size: 18,
                            color: Color(0xFFFF9CA1),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Conteúdo
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        AppStatusBadge(
                          label: '${_thousands(item.hopper.round())} L',
                          icon: Icons.water_drop_outlined,
                          tone: AppStatusTone.brand,
                        ),
                        AppStatusBadge(
                          label: item.aircraftYear,
                          icon: Icons.event_outlined,
                          tone: AppStatusTone.neutral,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'A partir de',
                      style: GoogleFonts.roboto(
                        fontSize: 11,
                        color: const Color(0x88FFFFFF),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _fmtUsd(item.price),
                      style: GoogleFonts.inter(
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                        color: _kBrand,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 16),
                    AppPrimaryButton(
                      label: 'Ver detalhes',
                      icon: Icons.arrow_forward_rounded,
                      expanded: true,
                      onPressed: openDetails,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _imageFallback() => Container(
        height: 176,
        width: double.infinity,
        color: _kCardImageBg,
        child: const Center(
          child: Icon(Icons.flight_rounded, size: 38, color: Color(0x55C2D51C)),
        ),
      );

  // ─────────────────────────── Skeleton ──────────────────────────────
  Widget _skeletonGrid() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: _responsiveGrid(6, (w, i) {
          return SizedBox(
            width: w,
            child: AppCard(
              padding: EdgeInsets.zero,
              borderRadius: 18,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppSkeleton.box(height: 176, radius: 0),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppSkeleton.text(width: 130, height: 18),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              AppSkeleton.text(width: 72, height: 22),
                              const SizedBox(width: 8),
                              AppSkeleton.text(width: 60, height: 22),
                            ],
                          ),
                          const SizedBox(height: 16),
                          AppSkeleton.text(width: 150, height: 22),
                          const SizedBox(height: 16),
                          AppSkeleton.box(height: 44, radius: 11),
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
  }

  // ─────────────────────────── Empty ─────────────────────────────────
  Widget _emptyState(bool searching) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 72, horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0x14C2D51C),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              searching ? Icons.search_off_rounded : Icons.flight_takeoff_rounded,
              size: 32,
              color: _kBrand,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            searching ? 'Nenhum modelo encontrado' : 'Catálogo vazio',
            style: GoogleFonts.inter(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            searching
                ? 'Tente outro termo de busca.'
                : 'Cadastre o primeiro modelo de aeronave do catálogo.',
            textAlign: TextAlign.center,
            style: GoogleFonts.roboto(
              fontSize: 13,
              color: const Color(0xAAFFFFFF),
              height: 1.4,
            ),
          ),
          if (!searching) ...[
            const SizedBox(height: 20),
            AppPrimaryButton(
              label: 'Novo modelo',
              icon: Icons.add_rounded,
              onPressed: () => context.pushNamed(CreateAircraftWidget.routeName),
            ),
          ],
        ],
      ),
    );
  }

  // ──────────────────────── Delete (confirm) ─────────────────────────
  Future<void> _confirmDelete(AircraftsRow item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: const Color(0xB3000000),
      builder: (ctx) => AppModal(
        icon: Icons.delete_outline_rounded,
        iconTone: AppModalTone.danger,
        title: 'Remover do catálogo?',
        description:
            'O modelo "${item.aircraftModel.trim()}" deixará de aparecer no '
            'catálogo e na criação de propostas. Você pode cadastrá-lo '
            'novamente depois.',
        maxWidth: 460,
        footer: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            AppSecondaryButton(
              label: 'Cancelar',
              onPressed: () => Navigator.of(ctx).pop(false),
            ),
            const SizedBox(width: 10),
            AppSecondaryButton(
              label: 'Remover',
              icon: Icons.delete_outline_rounded,
              danger: true,
              onPressed: () => Navigator.of(ctx).pop(true),
            ),
          ],
        ),
        child: const SizedBox.shrink(),
      ),
    );

    if (confirmed != true) return;

    await AircraftsTable().update(
      data: {'deleted': true},
      matchingRows: (rows) => rows.eqOrNull('id', item.id),
    );
    _load();
  }
}
