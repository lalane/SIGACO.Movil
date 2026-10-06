import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Registro de trazabilidad: cada evento y cambio de estado de cualquier bloc.
/// Los eventos que llevan datos sensibles deben ocultarlos en su `toString`
/// (nunca contrasenas, tokens ni codigos). No registra nada en release.
class AppBlocObserver extends BlocObserver {
  @override
  void onEvent(Bloc<dynamic, dynamic> bloc, Object? event) {
    super.onEvent(bloc, event);
    _log('${bloc.runtimeType} <- $event');
  }

  @override
  void onTransition(
    Bloc<dynamic, dynamic> bloc,
    Transition<dynamic, dynamic> transition,
  ) {
    super.onTransition(bloc, transition);
    _log(
      '${bloc.runtimeType}: ${transition.currentState} -> '
      '${transition.nextState}',
    );
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    developer.log(
      '${bloc.runtimeType} ERROR: ${error.runtimeType}',
      name: 'sigaco.bloc',
      error: error,
      stackTrace: stackTrace,
    );
    super.onError(bloc, error, stackTrace);
  }

  void _log(String message) {
    if (kReleaseMode) return;
    developer.log(message, name: 'sigaco.bloc');
  }
}
