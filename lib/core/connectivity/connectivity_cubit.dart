import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'connectivity_source.dart';

class ConnectivityState extends Equatable {
  const ConnectivityState({
    this.online = true,
    this.lastContactAt,
    this.justReconnected = false,
  });

  /// Hay red y el servidor respondio la ultima vez que se le pregunto.
  final bool online;

  /// Ultima respuesta del servidor (hora del telefono). Nulo si aun no hubo.
  final DateTime? lastContactAt;

  /// La conexion volvio hace unos segundos (para avisarlo y retirar el aviso).
  final bool justReconnected;

  ConnectivityState copyWith({
    bool? online,
    DateTime? lastContactAt,
    bool? justReconnected,
  }) => ConnectivityState(
    online: online ?? this.online,
    lastContactAt: lastContactAt ?? this.lastContactAt,
    justReconnected: justReconnected ?? this.justReconnected,
  );

  @override
  List<Object?> get props => [online, lastContactAt, justReconnected];
}

/// Une dos señales: la red del telefono y las respuestas del servidor.
/// Sin red del telefono, o con la ultima peticion fallida por red, la app esta
/// sin conexion. Cuando la red vuelve se da por buena hasta la siguiente
/// peticion, que confirma o vuelve a marcarla sin conexion.
class ConnectivityCubit extends Cubit<ConnectivityState> {
  ConnectivityCubit(
    this._source,
    Stream<bool> serverReachable, {
    this.reconnectedFor = const Duration(seconds: 3),
    DateTime Function()? clock,
  }) : _now = clock ?? DateTime.now,
       super(const ConnectivityState()) {
    _networkSub = _source.changes.listen(_onNetwork);
    _serverSub = serverReachable.listen(_onServer);
    _source.isConnected.then(_onNetwork).catchError((_) {});
  }

  final ConnectivitySource _source;

  /// Cuanto tiempo se muestra «conexion restablecida».
  final Duration reconnectedFor;
  final DateTime Function() _now;
  late final StreamSubscription<bool> _networkSub;
  late final StreamSubscription<bool> _serverSub;
  Timer? _reconnectedTimer;

  bool _network = true;

  /// Resultado de la ultima peticion: true respondio, false fallo por red,
  /// nulo sin dato (por ejemplo, justo despues de volver la red).
  bool? _server;

  void _onNetwork(bool connected) {
    _network = connected;
    // Al volver la red se espera la siguiente respuesta para confirmarlo.
    if (connected) _server = null;
    _publish();
  }

  void _onServer(bool reachable) {
    _server = reachable;
    if (reachable) {
      emit(state.copyWith(lastContactAt: _now()));
    }
    _publish();
  }

  void _publish() {
    if (isClosed) return;
    final online = _network && _server != false;
    if (online == state.online) return;
    _reconnectedTimer?.cancel();
    if (online) {
      emit(state.copyWith(online: true, justReconnected: true));
      _reconnectedTimer = Timer(reconnectedFor, () {
        if (!isClosed) emit(state.copyWith(justReconnected: false));
      });
    } else {
      emit(state.copyWith(online: false, justReconnected: false));
    }
  }

  @override
  Future<void> close() async {
    _reconnectedTimer?.cancel();
    await _networkSub.cancel();
    await _serverSub.cancel();
    return super.close();
  }
}
