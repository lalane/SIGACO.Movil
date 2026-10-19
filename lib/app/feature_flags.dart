/// Funciones que existen en el codigo pero no se ofrecen en la app mientras no
/// estén dentro del alcance movil.
///
/// El gestor documental no esta entre los modulos moviles del Business
/// Blueprint (APP-MOB-01 a 09): se oculta del menu hasta que el PO confirme su
/// lugar en la app. Se enciende con `--dart-define=DOCUMENTS_MODULE=true`.
class FeatureFlags {
  const FeatureFlags({this.documents = false});

  /// La tarjeta del gestor documental en el menu de inicio.
  final bool documents;
}
