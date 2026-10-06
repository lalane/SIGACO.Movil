import 'package:equatable/equatable.dart';

/// Modulo o submodulo autorizado para el usuario en la concesion activa.
class NavigationItem extends Equatable {
  const NavigationItem({
    required this.code,
    required this.name,
    this.permissions = const [],
    this.submodules = const [],
  });

  final String code;
  final String name;
  final List<String> permissions;
  final List<NavigationItem> submodules;

  @override
  List<Object?> get props => [code, name, permissions, submodules];
}

/// Menu de la sesion: solo lo que el perfil, el acceso funcional y el cliente
/// (movil) permiten. Lo que no aparece no debe mostrarse (RN-TR-03).
class NavigationMenu extends Equatable {
  const NavigationMenu({this.modules = const [], this.permissions = const []});

  final List<NavigationItem> modules;

  /// Todas las claves de permiso (`FUNCION:ACCION`) de la sesion.
  final List<String> permissions;

  /// El modulo (o submodulo, por codigo completo como `ANTT.ACCIDENTES`) es visible.
  bool has(String code) {
    for (final m in modules) {
      if (m.code == code) return true;
      for (final s in m.submodules) {
        if (s.code == code) return true;
      }
    }
    return false;
  }

  @override
  List<Object?> get props => [modules, permissions];
}

enum NavigationError { contextRequired, permissionDenied, network, server }

class NavigationException implements Exception {
  const NavigationException(this.error);

  final NavigationError error;
}
