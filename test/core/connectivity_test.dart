import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sigaco_movil/core/api/api_client.dart';
import 'package:sigaco_movil/core/connectivity/connectivity_cubit.dart';
import 'package:sigaco_movil/core/connectivity/connectivity_source.dart';
import 'package:sigaco_movil/core/device/device_info_source.dart';

class FakeConnectivitySource implements ConnectivitySource {
  FakeConnectivitySource({this.connected = true});

  bool connected;
  final controller = StreamController<bool>.broadcast();

  @override
  Future<bool> get isConnected async => connected;

  @override
  Stream<bool> get changes => controller.stream;
}

Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 15));

/// Respuestas armadas a mano para el cliente HTTP.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.respond);

  final ResponseBody Function(RequestOptions options) respond;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => respond(options);

  @override
  void close({bool force = false}) {}
}

void main() {
  group('ConnectivityCubit', () {
    late FakeConnectivitySource network;
    late StreamController<bool> server;
    var now = DateTime(2026, 10, 6, 10);

    ConnectivityCubit make() => ConnectivityCubit(
      network,
      server.stream,
      reconnectedFor: const Duration(milliseconds: 40),
      clock: () => now,
    );

    setUp(() {
      network = FakeConnectivitySource();
      server = StreamController<bool>.broadcast();
      now = DateTime(2026, 10, 6, 10);
    });

    test('arranca con conexion y sin ultimo contacto', () async {
      final cubit = make();
      await settle();
      expect(cubit.state.online, isTrue);
      expect(cubit.state.lastContactAt, isNull);
      expect(cubit.state.justReconnected, isFalse);
      await cubit.close();
    });

    test('arranca sin conexion si el telefono no tiene red', () async {
      network.connected = false;
      final cubit = make();
      await settle();
      expect(cubit.state.online, isFalse);
      await cubit.close();
    });

    test(
      'sin red del telefono esta sin conexion y al volver lo avisa',
      () async {
        final cubit = make();
        await settle();
        network.controller.add(false);
        await settle();
        expect(cubit.state.online, isFalse);

        network.controller.add(true);
        await settle();
        expect(cubit.state.online, isTrue);
        expect(cubit.state.justReconnected, isTrue);

        // El aviso de «conexion restablecida» se retira solo.
        await Future<void>.delayed(const Duration(milliseconds: 80));
        expect(cubit.state.justReconnected, isFalse);
        expect(cubit.state.online, isTrue);
        await cubit.close();
      },
    );

    test(
      'una peticion fallida por red marca sin conexion aunque haya red',
      () async {
        final cubit = make();
        await settle();
        server.add(false);
        await settle();
        expect(cubit.state.online, isFalse);

        now = DateTime(2026, 10, 6, 10, 5);
        server.add(true);
        await settle();
        expect(cubit.state.online, isTrue);
        expect(cubit.state.justReconnected, isTrue);
        expect(cubit.state.lastContactAt, DateTime(2026, 10, 6, 10, 5));
        await cubit.close();
      },
    );

    test(
      'al volver la red se da por buena hasta la siguiente peticion',
      () async {
        final cubit = make();
        await settle();
        server.add(false);
        await settle();
        expect(cubit.state.online, isFalse);

        // Vuelve la red del telefono: aun no se sabe si el servidor responde.
        network.controller.add(true);
        await settle();
        expect(cubit.state.online, isTrue);

        // La siguiente peticion falla: otra vez sin conexion.
        server.add(false);
        await settle();
        expect(cubit.state.online, isFalse);
        await cubit.close();
      },
    );

    test(
      'con el servidor respondiendo pero sin red del telefono sigue sin conexion',
      () async {
        final cubit = make();
        await settle();
        network.controller.add(false);
        server.add(true);
        await settle();
        expect(cubit.state.online, isFalse);
        expect(cubit.state.lastContactAt, isNotNull);
        await cubit.close();
      },
    );
  });

  group('ApiClient: alcance del servidor', () {
    ApiClient clientWith(ResponseBody Function(RequestOptions) respond) {
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test'))
        ..httpClientAdapter = _FakeAdapter(respond);
      return ApiClient(dio: dio);
    }

    test('una respuesta correcta marca que el servidor responde', () async {
      final api = clientWith(
        (_) => ResponseBody.fromString(
          '{}',
          200,
          headers: {
            Headers.contentTypeHeader: ['application/json'],
          },
        ),
      );
      final seen = <bool>[];
      api.reachability.listen(seen.add);
      await api.get('/api/x');
      await settle();
      expect(seen, [true]);
    });

    test('un error del servidor tambien prueba que hay conexion', () async {
      final api = clientWith((_) => ResponseBody.fromString('{}', 500));
      final seen = <bool>[];
      api.reachability.listen(seen.add);
      await expectLater(api.get('/api/x'), throwsA(anything));
      await settle();
      expect(seen, [true]);
    });

    test('un fallo de red sin respuesta marca que no hay conexion', () async {
      final api = clientWith(
        (o) => throw DioException(
          requestOptions: o,
          type: DioExceptionType.connectionError,
        ),
      );
      final seen = <bool>[];
      api.reachability.listen(seen.add);
      await expectLater(api.get('/api/x'), throwsA(anything));
      await settle();
      expect(seen, [false]);
    });

    test('un tiempo de espera agotado cuenta como sin conexion', () async {
      final api = clientWith(
        (o) => throw DioException(
          requestOptions: o,
          type: DioExceptionType.receiveTimeout,
        ),
      );
      final seen = <bool>[];
      api.reachability.listen(seen.add);
      await expectLater(api.get('/api/x'), throwsA(anything));
      await settle();
      expect(seen, [false]);
    });

    test('una peticion cancelada no cambia el estado', () async {
      final api = clientWith(
        (o) => throw DioException(
          requestOptions: o,
          type: DioExceptionType.cancel,
        ),
      );
      final seen = <bool>[];
      api.reachability.listen(seen.add);
      await expectLater(api.get('/api/x'), throwsA(anything));
      await settle();
      expect(seen, isEmpty);
    });
  });

  group('describeDevice', () {
    test('une fabricante, modelo y version de Android', () {
      expect(
        describeDevice(
          manufacturer: 'samsung',
          model: 'SM-A155M',
          release: '14',
        ),
        'Samsung SM-A155M · Android 14',
      );
    });

    test('no repite el fabricante si el modelo ya lo trae', () {
      expect(
        describeDevice(
          manufacturer: 'HONOR',
          model: 'Honor X8b',
          release: '13',
        ),
        'Honor X8b · Android 13',
      );
    });

    test('sin version de Android solo muestra el equipo', () {
      expect(
        describeDevice(
          manufacturer: 'motorola',
          model: 'moto g54',
          release: '',
        ),
        'Motorola moto g54',
      );
    });

    test('sin datos devuelve vacio', () {
      expect(describeDevice(manufacturer: '', model: '', release: ''), '');
    });
  });
}
