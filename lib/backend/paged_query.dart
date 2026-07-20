import 'package:supabase_flutter/supabase_flutter.dart';

import '/backend/supabase/supabase.dart';

/// Uma página de resultados vinda do backend.
class PagedResult<T> {
  const PagedResult({
    required this.items,
    required this.total,
    required this.page,
    required this.perPage,
  });

  /// Linhas desta página (no máximo [perPage]).
  final List<T> items;

  /// Total de linhas que casam com o filtro — vem do `Content-Range` do
  /// PostgREST (`count=exact`), não do tamanho de [items].
  final int total;

  /// Página atual, 1-based.
  final int page;
  final int perPage;

  int get pageCount => total <= 0 ? 1 : ((total + perPage - 1) ~/ perPage);
  bool get hasPrev => page > 1;
  bool get hasNext => page < pageCount;

  /// Índice 1-based da primeira linha desta página (para "11–20 de 57").
  int get firstIndex => total == 0 ? 0 : ((page - 1) * perPage) + 1;
  int get lastIndex => total == 0 ? 0 : firstIndex + items.length - 1;

  static PagedResult<T> empty<T>(int page, int perPage) =>
      PagedResult(items: const [], total: 0, page: page, perPage: perPage);
}

const List<int> kPerPageOptions = [10, 25, 50, 100];
const int kDefaultPerPage = 25;

/// Consulta paginada no servidor: aplica `range` + `count=exact` numa query.
///
/// **Por que não vive em `SupabaseTable`:** `lib/backend/supabase/database/`
/// é código gerado pelo FlutterFlow — uma regeneração apagaria o método. Aqui
/// só usamos a API pública da tabela (`tableName` e `createRow`).
///
/// **Consequência que vem junto:** com paginação no servidor, todo filtro tem
/// que ir para o `queryFn` também. Filtrar em Dart depois de paginar filtra
/// apenas a página corrente — a busca passaria a "não achar" registros que
/// existem duas páginas adiante, e a contagem ficaria mentindo.
Future<PagedResult<T>> queryPage<T extends SupabaseDataRow>({
  required SupabaseTable<T> table,
  required PostgrestTransformBuilder Function(PostgrestFilterBuilder) queryFn,
  required int page,
  required int perPage,
}) async {
  final safePage = page < 1 ? 1 : page;
  final from = (safePage - 1) * perPage;
  final to = from + perPage - 1;

  final res = await queryFn(SupaFlow.client.from(table.tableName).select())
      .range(from, to)
      .count(CountOption.exact);

  final rows = (res.data as List).cast<Map<String, dynamic>>();
  return PagedResult<T>(
    items: rows.map(table.createRow).toList(),
    total: res.count,
    page: safePage,
    perPage: perPage,
  );
}

/// Monta um filtro `or=(col.ilike.*q*,...)` do PostgREST para busca em várias
/// colunas de uma vez.
///
/// Vírgula e parênteses quebram a sintaxe do `or` e são removidos do termo —
/// sem isso, uma busca com vírgula viraria um filtro malformado (400).
String orIlike(List<String> columns, String query) {
  final q = query.trim().replaceAll(RegExp(r'[(),*]'), '');
  return columns.map((c) => '$c.ilike.*$q*').join(',');
}
