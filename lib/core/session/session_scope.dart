import '../offline/operation.dart';

/// Algo que guarda datos de la concesion activa y debe vaciarse al cambiar de
/// concesion o cerrar sesion (RN-CTX-02: nada del ambiente anterior sobrevive).
abstract interface class ScopeCleaner {
  Future<void> clear();
}

/// Un cache que ademas es de una persona y una concesion: al iniciar sesion se
/// le dice de quien es el alcance activo (o null al cerrar sesion). Si lo que
/// guardaba era de otro alcance, lo descarta; asi, aunque la app se haya cerrado
/// a la fuerza sin vaciarlo, otra persona nunca ve lo ajeno.
abstract interface class ScopeBound implements ScopeCleaner {
  Future<void> bind(OfflineScope? scope);
}

/// Registro de limpiadores. Cada modulo con cache local (por ejemplo la base
/// offline) registra el suyo en `app/dependencies.dart`.
class SessionScope {
  final List<ScopeCleaner> _cleaners = [];

  void register(ScopeCleaner cleaner) => _cleaners.add(cleaner);

  /// Vacia todo lo registrado. Un fallo de uno no impide vaciar los demas: se
  /// prefiere dejar menos datos ajenos que detenerse a mitad.
  Future<void> clear() async {
    for (final c in _cleaners) {
      try {
        await c.clear();
      } catch (_) {}
    }
  }

  /// Fija el alcance activo en los caches que lo necesitan.
  Future<void> bind(OfflineScope? scope) async {
    for (final c in _cleaners) {
      if (c is! ScopeBound) continue;
      try {
        await c.bind(scope);
      } catch (_) {}
    }
  }
}
