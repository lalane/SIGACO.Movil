import 'package:flutter/widgets.dart';

/// El nombre de la concesion activa de la sesion, para que los modulos lo
/// muestren sin depender del modulo de acceso (los modulos solo comparten
/// codigo via core/). Lo pone la app (`app/app.dart`) a partir de la sesion.
class ActiveConcessionScope extends InheritedWidget {
  const ActiveConcessionScope({
    super.key,
    required this.name,
    required super.child,
  });

  final String? name;

  /// La concesion activa, o null si no hay sesion (o no hay alcance en el
  /// arbol, como en una prueba de un solo widget).
  static String? nameOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ActiveConcessionScope>()?.name;

  @override
  bool updateShouldNotify(ActiveConcessionScope oldWidget) =>
      name != oldWidget.name;
}
