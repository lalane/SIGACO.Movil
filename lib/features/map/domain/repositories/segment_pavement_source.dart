import '../entities/segment_pavement.dart';

/// El estado del pavimento por tramo (`/api/gis/segment-indicators`), para
/// colorear los tramos del mapa. Es opcional: los repositorios de tramos que no
/// lo tienen (datos de ejemplo) no muestran el boton. Lanza `MapException`; con
/// `permissionDenied` el perfil no ve la capa «Indicadores y pavimento» (DTF M10
/// §4.2).
abstract interface class SegmentPavementSource {
  Future<PavementLayer> pavement();
}
