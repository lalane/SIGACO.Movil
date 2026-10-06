/// Algo que guarda datos de la concesion activa y debe vaciarse al cambiar de
/// concesion o cerrar sesion (RN-CTX-02: nada del ambiente anterior sobrevive).
abstract interface class ScopeCleaner {
  Future<void> clear();
}

/// Registro de limpiadores. Cada modulo con cache local (por ejemplo la base
/// offline) registra el suyo en `app/dependencies.dart`.
class SessionScope {
  final List<ScopeCleaner> _cleaners = [];

  void register(ScopeCleaner cleaner) => _cleaners.add(cleaner);

  Future<void> clear() async {
    for (final c in _cleaners) {
      await c.clear();
    }
  }
}
