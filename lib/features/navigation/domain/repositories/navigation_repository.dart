import '../entities/navigation_entities.dart';

abstract interface class NavigationRepository {
  /// Lanza [NavigationException].
  Future<NavigationMenu> load();

  /// Emite cuando el servidor niega una accion por permisos: los accesos del
  /// usuario pudieron cambiar y conviene volver a consultar el menu.
  Stream<void> get accessDenied;
}
