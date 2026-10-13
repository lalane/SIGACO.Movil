import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sigaco_movil/core/api/api_client.dart';
import 'package:sigaco_movil/core/offline/operation.dart';
import 'package:sigaco_movil/core/offline/sync_engine.dart';
import 'package:sigaco_movil/features/documents/data/repositories/documents_repository_impl.dart';
import 'package:sigaco_movil/features/documents/data/sync/documents_sync_remote.dart';

import '../../support/fakes.dart';

const _typeId = '00000000-0000-0000-0000-0000000000a1';
const _categoryId = '00000000-0000-0000-0000-0000000000c1';
const _folderId = '00000000-0000-0000-0000-000000000002';
const _opId = '11111111-1111-4111-8111-111111111111';

/// Servidor falso de `/api/uploads` y de los catalogos.
class _Server implements HttpClientAdapter {
  final requests = <RequestOptions>[];
  final bodies = <Object?>[];

  /// Respuestas sucesivas de abrir la carga y de completarla / consultarla.
  final open = <Map<String, Object?>>[];
  final next = <Map<String, Object?>>[];

  int? failBlocksWith;
  bool offlineOnBlocks = false;
  int? openStatus;
  Map<String, Object?>? openError;

  static Map<String, Object?> upload(
    String status, {
    List<int> missing = const [],
    int blockSize = 4,
    String? rejectionMessage,
  }) => {
    'uploadId': _opId,
    'status': status,
    'fileName': 'acta.pdf',
    'sizeBytes': 10,
    'blockSize': blockSize,
    'totalBlocks': 3,
    'missingBlocks': missing,
    'documentId': status == 'COMPLETADO' ? 'doc-1' : null,
    'versionId': status == 'COMPLETADO' ? 'ver-1' : null,
    'publishedName': status == 'COMPLETADO' ? 'acta.pdf' : null,
    'rejectionCode': rejectionMessage == null ? null : 'EXT_BLOCKED',
    'rejectionMessage': rejectionMessage,
  };

  ResponseBody json(Object? body, [int status = 200]) =>
      ResponseBody.fromString(
        jsonEncode(body),
        status,
        headers: {
          Headers.contentTypeHeader: ['application/json'],
        },
      );

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final path = options.path;
    if (path == '/api/documents/catalogs') {
      return json({
        'types': [
          {'id': _typeId, 'code': 'TD01', 'labelEs': 'Informe', 'active': true},
        ],
        'categories': [
          {'id': _categoryId, 'code': 'CT01', 'labelEs': 'C', 'active': true},
        ],
      });
    }
    if (path == '/api/documents/folders') {
      return json([
        {'id': 'root', 'name': 'Raiz', 'path': '', 'kind': 'RAIZ'},
        {'id': _folderId, 'name': 'Obras', 'path': 'Obras', 'kind': 'CARPETA'},
      ]);
    }
    if (path == '/api/documents/modifiers') return json([]);
    if (path == '/api/uploads' && options.method == 'POST') {
      bodies.add(options.data);
      if (openStatus != null) return json(openError ?? {}, openStatus!);
      return json(open.removeAt(0), 200);
    }
    if (path.contains('/blocks/')) {
      if (offlineOnBlocks) {
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
        );
      }
      if (failBlocksWith != null) return json({}, failBlocksWith!);
      return json({'index': 0, 'receivedCount': 1, 'totalBlocks': 3});
    }
    return json(next.removeAt(0), path.endsWith('/complete') ? 202 : 200);
  }

  @override
  void close({bool force = false}) {}
}

PendingOperation _op({Map<String, Object?>? payload, String? entity}) =>
    PendingOperation(
      id: _opId,
      scope: const OfflineScope(userId: 'u', concessionId: 'c'),
      entity: entity ?? 'documento',
      kind: OperationKind.insert,
      payload:
          payload ??
          {
            'name': 'acta.pdf',
            'typeCode': 'TD01',
            'categoryCode': 'CT01',
            'description': ' Acta firmada ',
            'folder': 'Obras',
            'format': 'pdf',
            'sizeBytes': 10,
            'localPath': '/kept/1/acta.pdf',
          },
      status: OperationStatus.pending,
      createdAt: DateTime.utc(2026, 10, 13),
      capturedAt: DateTime.utc(2026, 10, 13),
      updatedAt: DateTime.utc(2026, 10, 13),
    );

void main() {
  late _Server server;
  late MemoryFileStore store;
  late DocumentsSyncRemote remote;
  late List<(int, int)> reads;
  late List<Duration> waits;
  var fileExists = true;

  setUp(() {
    server = _Server();
    store = MemoryFileStore();
    reads = [];
    waits = [];
    fileExists = true;
    final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
      ..httpClientAdapter = server
      ..options.validateStatus = (s) => s != null && s < 400;
    final api = ApiClient(dio: dio);
    remote = DocumentsSyncRemote(
      api,
      DocumentsRepositoryImpl(api, language: () => 'es'),
      store,
      fileLength: (path) async {
        if (!fileExists) throw const FileSystemException('no existe');
        return 10;
      },
      readBlock: (path, start, length) async {
        reads.add((start, length));
        return Uint8List(length);
      },
      delay: (d) async => waits.add(d),
    );
  });

  Iterable<RequestOptions> blocks() =>
      server.requests.where((r) => r.path.contains('/blocks/'));

  test(
    'abre la carga con los identificadores y manda todos los bloques',
    () async {
      server.open.add(_Server.upload('TRANSFIRIENDO', missing: [0, 1, 2]));
      server.next.add(_Server.upload('COMPLETADO'));

      final outcome = await remote.send(_op());

      expect(outcome, isA<SyncAccepted>());
      expect((outcome as SyncAccepted).response, {
        'documentId': 'doc-1',
        'versionId': 'ver-1',
        'publishedName': 'acta.pdf',
      });
      final body = server.bodies.single! as Map;
      expect(body['uploadId'], _opId);
      expect(body['fileName'], 'acta.pdf');
      expect(body['sizeBytes'], 10);
      expect(body['typeId'], _typeId);
      expect(body['categoryId'], _categoryId);
      expect(body['folderId'], _folderId);
      expect(body['description'], 'Acta firmada');
      // El ultimo bloque lleva lo que sobra: 4 + 4 + 2.
      expect(reads, [(0, 4), (4, 4), (8, 2)]);
      expect(blocks().map((r) => r.path), [
        '/api/uploads/$_opId/blocks/0',
        '/api/uploads/$_opId/blocks/1',
        '/api/uploads/$_opId/blocks/2',
      ]);
      expect(blocks().every((r) => r.method == 'PUT'), isTrue);
      expect(store.removed, ['/kept/1/acta.pdf']);
    },
  );

  test('reanuda: solo manda los bloques que faltan', () async {
    server.open.add(_Server.upload('TRANSFIRIENDO', missing: [2]));
    server.next.add(_Server.upload('COMPLETADO'));

    await remote.send(_op());

    expect(reads, [(8, 2)]);
    expect(blocks().single.path, endsWith('/blocks/2'));
  });

  test('espera a que el servidor termine de validar', () async {
    server.open.add(_Server.upload('TRANSFIRIENDO', missing: [0, 1, 2]));
    server.next
      ..add(_Server.upload('VALIDANDO'))
      ..add(_Server.upload('VALIDANDO'))
      ..add(_Server.upload('COMPLETADO'));

    final outcome = await remote.send(_op());

    expect(outcome, isA<SyncAccepted>());
    expect(waits, hasLength(2));
  });

  test('si sigue validando, lo deja para la siguiente pasada', () async {
    server.open.add(_Server.upload('VALIDANDO'));
    for (var i = 0; i < 10; i++) {
      server.next.add(_Server.upload('VALIDANDO'));
    }

    final outcome = await remote.send(_op());

    expect(outcome, isA<SyncRetryLater>());
    expect(store.removed, isEmpty);
  });

  test('una carga ya completada se reconoce sin reenviar', () async {
    server.open.add(_Server.upload('COMPLETADO'));

    final outcome = await remote.send(_op());

    expect(outcome, isA<SyncAccepted>());
    expect(blocks(), isEmpty);
  });

  test('si el servidor la rechaza, conserva el motivo y el archivo', () async {
    server.open.add(
      _Server.upload('RECHAZADO', rejectionMessage: 'Extension bloqueada'),
    );

    final outcome = await remote.send(_op());

    expect(outcome, isA<SyncRejected>());
    expect((outcome as SyncRejected).message, 'Extension bloqueada');
    expect(outcome.code, 'EXT_BLOCKED');
    expect(store.removed, isEmpty);
  });

  test('sin red en un bloque: se reintenta mas tarde', () async {
    server.open.add(_Server.upload('TRANSFIRIENDO', missing: [0, 1, 2]));
    server.offlineOnBlocks = true;

    expect(await remote.send(_op()), isA<SyncRetryLater>());
    expect(store.removed, isEmpty);
  });

  test('sesion vencida', () async {
    server.openStatus = 401;

    expect(await remote.send(_op()), isA<SyncSessionLost>());
  });

  test('error del servidor es pasajero', () async {
    server.openStatus = 503;

    expect(await remote.send(_op()), isA<SyncRetryLater>());
  });

  test('un 400 de validacion se rechaza con el mensaje del campo', () async {
    server.openStatus = 400;
    server.openError = {
      'errors': {
        'fileName': ['Nombre no valido'],
      },
    };

    final outcome = await remote.send(_op());

    expect(outcome, isA<SyncRejected>());
    expect((outcome as SyncRejected).message, 'Nombre no valido');
  });

  test('sin permiso se rechaza', () async {
    server.openStatus = 403;
    server.openError = {'code': 'FORBIDDEN', 'title': 'Sin permiso'};

    final outcome = await remote.send(_op());

    expect(outcome, isA<SyncRejected>());
    expect((outcome as SyncRejected).message, 'Sin permiso');
  });

  test('si el archivo ya no esta en el telefono, se rechaza', () async {
    fileExists = false;

    final outcome = await remote.send(_op());

    expect(outcome, isA<SyncRejected>());
    expect(server.requests, isEmpty);
  });

  test('una carpeta que ya no existe no sube el documento a la raiz', () async {
    final outcome = await remote.send(
      _op(
        payload: {
          'name': 'acta.pdf',
          'folder': 'Borrada',
          'localPath': '/kept/1/acta.pdf',
        },
      ),
    );

    expect(outcome, isA<SyncRejected>());
    expect(server.bodies, isEmpty);
  });

  test('otros tipos de registro no se envian', () async {
    expect(
      await remote.send(_op(entity: 'documento_firma')),
      isA<SyncRejected>(),
    );
  });
}
