import 'dart:async';

/// Cache em memória com TTL — evita refazer queries para dropdowns
/// repetidos (lista de clientes, vendedores, categorias) no mesmo
/// ciclo de vida do app.
///
/// Uso:
/// ```dart
/// final clients = await QueryCache.fetch(
///   key: 'clients',
///   ttl: const Duration(minutes: 2),
///   fetcher: () => VwGetClientsTable().queryRows(queryFn: (q) => q),
/// );
/// ```
class QueryCache {
  QueryCache._();

  static final Map<String, _Entry> _store = {};
  static final Map<String, Future<dynamic>> _inFlight = {};

  /// Retorna o valor cacheado se válido, ou executa o fetcher.
  /// Requests concorrentes para a mesma key compartilham o mesmo Future.
  static Future<T> fetch<T>({
    required String key,
    required Future<T> Function() fetcher,
    Duration ttl = const Duration(minutes: 2),
  }) async {
    final entry = _store[key];
    if (entry != null && DateTime.now().isBefore(entry.expiresAt)) {
      return entry.value as T;
    }

    final pending = _inFlight[key];
    if (pending != null) return pending as Future<T>;

    final future = fetcher().then((value) {
      _store[key] = _Entry(value, DateTime.now().add(ttl));
      _inFlight.remove(key);
      return value;
    }).catchError((Object e) {
      _inFlight.remove(key);
      throw e;
    });

    _inFlight[key] = future;
    return future;
  }

  /// Invalida uma entrada — chame após inserir/atualizar/deletar.
  static void invalidate(String key) {
    _store.remove(key);
  }

  /// Invalida tudo. Útil em logout.
  static void clear() {
    _store.clear();
    _inFlight.clear();
  }
}

class _Entry {
  _Entry(this.value, this.expiresAt);
  final Object? value;
  final DateTime expiresAt;
}
