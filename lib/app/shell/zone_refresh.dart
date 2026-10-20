import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/time/concession_zone_cubit.dart';
import '../../core/time/concession_zone_source.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';

/// Vuelve a pedir la zona horaria de la concesion activa al servidor (para
/// salir del bloqueo "sin configuracion", RN-13). Sin red o sin zona publicada
/// no cambia nada.
Future<void> refreshConcessionZone(BuildContext context) async {
  final concession = context.read<AuthBloc>().state.activeConcessionId;
  if (concession == null) return;
  final cubit = context.read<ConcessionZoneCubit>();
  final zone = await context.read<ConcessionZoneSource>().load(concession);
  if (zone != null) cubit.setFallback(zone);
}
