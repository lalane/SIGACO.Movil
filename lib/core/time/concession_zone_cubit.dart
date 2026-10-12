import 'package:flutter_bloc/flutter_bloc.dart';

import 'concession_zone.dart';

/// Zona horaria de la concesion activa, disponible para cualquier modulo sin
/// que dependa del modulo de marca. La compone la app (`SessionLifecycle`):
/// null antes de iniciar sesion o si la concesion no la trae.
class ConcessionZoneCubit extends Cubit<ConcessionZone?> {
  ConcessionZoneCubit() : super(null);

  void set(ConcessionZone? zone) {
    if (zone?.id != state?.id) emit(zone);
  }
}
