import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sigaco_movil/core/api/api_client.dart';
import 'package:sigaco_movil/features/documents/data/repositories/documents_repository_impl.dart';
import 'package:sigaco_movil/features/documents/domain/entities/document.dart';
import 'package:sigaco_movil/features/documents/domain/entities/document_preview.dart';
import 'package:sigaco_movil/features/documents/domain/entities/document_query.dart';
import 'package:sigaco_movil/features/documents/domain/repositories/documents_repository.dart';

/// Servidor falso con las formas de respuesta de SIGACO.Api (camelCase).
class _Server implements HttpClientAdapter {
  final requests = <RequestOptions>[];
  bool offline = false;
  int? failWith;
  Map<String, Object?>? failBody;
  Uint8List? previewBytes;
  String previewType = 'application/pdf';
  int pages = 1;

  static const rootId = '00000000-0000-0000-0000-000000000001';
  static const folderId = '00000000-0000-0000-0000-000000000002';
  static const typeId = '00000000-0000-0000-0000-0000000000a1';
  static const userId = '00000000-0000-0000-0000-0000000000b1';

  Map<String, Object?> item(String id, {String signature = 'SIN_FIRMA'}) => {
    'id': id,
    'name': 'Informe $id',
    'extension': '.PDF',
    'type': {'id': typeId, 'code': 'TD01', 'label': 'Informe', 'active': true},
    'category': null,
    'folder': {'id': folderId, 'name': 'Obras', 'path': 'Obras'},
    'versionId': 'v',
    'versionNumber': 2,
    'versionLabel': 'V2',
    'sizeBytes': 1024,
    'modifiedBy': {'id': userId, 'username': 'ana@idare.mx'},
    'lastModifiedAt': '2026-10-10T15:30:00-06:00',
    'signatureStatus': signature,
    'ownerUserId': userId,
    'isFavorite': true,
    'rowVersion': 1,
  };

  Object? body(RequestOptions o) {
    final path = o.path;
    if (path == '/api/documents/catalogs') {
      return {
        'types': [
          {
            'id': typeId,
            'code': 'TD01',
            'labelEs': 'Informe',
            'labelPt': 'Relatorio',
            'active': true,
            'sortOrder': 1,
          },
          {
            'id': '00000000-0000-0000-0000-0000000000a2',
            'code': 'TD02',
            'labelEs': 'Viejo',
            'labelPt': null,
            'active': false,
            'sortOrder': 2,
          },
        ],
        'categories': [
          {
            'id': '00000000-0000-0000-0000-0000000000c1',
            'code': 'CT01',
            'labelEs': 'Contratos',
            'labelPt': null,
            'active': true,
            'sortOrder': 1,
          },
        ],
      };
    }
    if (path == '/api/documents/folders') {
      return [
        {
          'id': rootId,
          'parentId': null,
          'name': 'Raiz',
          'path': '',
          'kind': 'RAIZ',
        },
        {
          'id': folderId,
          'parentId': rootId,
          'name': 'Obras',
          'path': 'Obras',
          'kind': 'CARPETA',
        },
        {
          'id': 'sp',
          'parentId': rootId,
          'name': 'SharePoint',
          'path': 'SharePoint',
          'kind': 'SHAREPOINT',
        },
      ];
    }
    if (path == '/api/documents/modifiers') {
      return [
        {'id': userId, 'username': 'ana@idare.mx'},
      ];
    }
    if (path == '/api/documents') {
      final page = int.parse('${o.queryParameters['page'] ?? 1}');
      return {
        'view': 'all',
        'mode': 'BUSQUEDA',
        'folders': [],
        'documents': [
          item('p$page-1', signature: page == 1 ? 'VALIDADO' : 'SIN_FIRMA'),
        ],
        'page': page,
        'pageSize': 100,
        'totalPages': pages,
      };
    }
    if (path == '/api/documents/d1') {
      return {
        'id': 'd1',
        'name': 'Informe d1',
        'extension': 'pdf',
        'mimeType': 'application/pdf',
        'type': {
          'id': typeId,
          'code': 'TD01',
          'label': 'Informe',
          'active': true,
        },
        'category': {
          'id': 'c',
          'code': 'CT01',
          'label': 'Contratos',
          'active': true,
        },
        'description': 'Descripcion',
        'folder': {'id': folderId, 'name': 'Obras', 'path': 'Obras/2026'},
        'owner': {'id': userId, 'username': 'luis@idare.mx'},
        'modifiedBy': {'id': userId, 'username': 'ana@idare.mx'},
        'lastModifiedAt': '2026-10-10T15:30:00Z',
        'currentVersion': {
          'number': 3,
          'sizeBytes': 2048,
          'signatureStatus': 'PENDIENTE_VALIDACION',
          'previewStatus': 'SIN_VISOR',
        },
        'isFavorite': false,
      };
    }
    return {'documentId': 'd1', 'isFavorite': true};
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    if (offline) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
      );
    }
    if (failWith != null) {
      return ResponseBody.fromString(
        jsonEncode(failBody ?? {}),
        failWith!,
        headers: {
          Headers.contentTypeHeader: ['application/json'],
        },
      );
    }
    if (options.path.endsWith('/preview')) {
      return ResponseBody.fromBytes(
        previewBytes ?? Uint8List.fromList([1, 2, 3]),
        200,
        headers: {
          Headers.contentTypeHeader: [previewType],
        },
      );
    }
    return ResponseBody.fromString(
      jsonEncode(body(options)),
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late _Server server;
  late DocumentsRepositoryImpl repo;
  var lang = 'es';

  setUp(() {
    server = _Server();
    lang = 'es';
    final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
      ..httpClientAdapter = server
      // Como el cliente real: los estados de error se traducen a excepcion.
      ..options.validateStatus = (s) => s != null && s < 400;
    repo = DocumentsRepositoryImpl(ApiClient(dio: dio), language: () => lang);
  });

  RequestOptions listCall() =>
      server.requests.firstWhere((r) => r.path == '/api/documents');

  group('lista', () {
    test('Todos sin criterios se pide plano desde la raiz', () async {
      final docs = await repo.list(const DocumentQuery());
      expect(listCall().queryParameters['inFolderId'], _Server.rootId);
      expect(listCall().queryParameters['view'], 'all');
      expect(listCall().queryParameters['lang'], 'es');
      expect(docs.single.format, 'pdf');
      expect(docs.single.ownerUsername, 'ana');
      expect(docs.single.signature, DocumentSignature.validated);
      expect(docs.single.typeLabel, 'Informe');
      expect(docs.single.modifiedAt.isUtc, isTrue);
      expect(docs.single.modifiedAt, DateTime.utc(2026, 10, 10, 21, 30));
    });

    test('las demas vistas no piden la raiz', () async {
      await repo.list(const DocumentQuery(view: DocumentView.favorites));
      expect(listCall().queryParameters['view'], 'favorites');
      expect(listCall().queryParameters.containsKey('inFolderId'), isFalse);
    });

    test('traduce codigos, ruta y usuario a identificadores', () async {
      await repo.list(
        DocumentQuery(
          search: ' informe ',
          filters: DocumentFilters(
            typeCode: 'TD01',
            categoryCode: 'CT01',
            folder: 'Obras',
            modifiedBy: 'ana',
            from: DateTime(2026, 10, 1),
            to: DateTime(2026, 10, 12),
          ),
        ),
      );
      final q = listCall().queryParameters;
      expect(q['q'], 'informe');
      expect(q['typeId'], _Server.typeId);
      expect(q['categoryId'], '00000000-0000-0000-0000-0000000000c1');
      expect(q['inFolderId'], _Server.folderId);
      expect(q['modifiedBy'], _Server.userId);
      expect(q['from'], '2026-10-01');
      expect(q['to'], '2026-10-12');
    });

    test('junta las paginas hasta el tope', () async {
      server.pages = 9;
      final docs = await repo.list(const DocumentQuery());
      expect(docs, hasLength(5));
    });

    test('pide en portugues cuando la interfaz esta en portugues', () async {
      lang = 'pt';
      await repo.list(const DocumentQuery());
      expect(listCall().queryParameters['lang'], 'pt');
    });
  });

  group('catalogos', () {
    test('usan el idioma, marcan inactivos y omiten SharePoint', () async {
      lang = 'pt';
      final c = await repo.catalogs();
      expect(c.types.first.label, 'Relatorio');
      expect(c.types.last.label, 'Viejo');
      expect(c.types.last.active, isFalse);
      expect(c.categories.single.label, 'Contratos');
      expect(c.folders, ['Obras']);
      expect(c.users, ['ana']);
    });
  });

  group('ficha', () {
    test('lee version, propietario, carpeta y firma', () async {
      final d = await repo.detail('d1');
      expect(d.version, 3);
      expect(d.sizeBytes, 2048);
      expect(d.summary.ownerUsername, 'luis');
      expect(d.modifiedBy, 'ana');
      expect(d.folder, 'Obras/2026');
      expect(d.summary.signature, DocumentSignature.pending);
      expect(d.previewAvailable, isFalse);
    });
  });

  group('favorito', () {
    test('marcar usa PUT y desmarcar DELETE', () async {
      await repo.setFavorite('d1', favorite: true);
      await repo.setFavorite('d1', favorite: false);
      expect(server.requests.map((r) => r.method), ['PUT', 'DELETE']);
      expect(
        server.requests.every((r) => r.path == '/api/documents/d1/favorite'),
        isTrue,
      );
    });
  });

  group('vista previa', () {
    test('PDF', () async {
      final p = await repo.preview('d1');
      expect(p.kind, PreviewKind.pdf);
      expect(p.bytes, [1, 2, 3]);
    });

    test('imagen', () async {
      server.previewType = 'image/png';
      expect((await repo.preview('d1')).kind, PreviewKind.image);
    });

    test('409 PREVIEW_* se muestra como sin vista previa', () async {
      server.failWith = 409;
      server.failBody = {'code': 'PREVIEW_PENDING'};
      expect((await repo.preview('d1')).kind, PreviewKind.unsupported);
    });

    test('404 es documento inexistente', () async {
      server.failWith = 404;
      server.failBody = {'code': 'NOT_FOUND'};
      await expectLater(
        repo.preview('d1'),
        throwsA(
          isA<DocumentsException>().having(
            (e) => e.error,
            'error',
            DocumentsError.notFound,
          ),
        ),
      );
    });
  });

  group('errores', () {
    Matcher fails(DocumentsError error) => throwsA(
      isA<DocumentsException>().having((e) => e.error, 'error', error),
    );

    test('sin red', () async {
      server.offline = true;
      await expectLater(
        repo.list(const DocumentQuery()),
        fails(DocumentsError.network),
      );
    });

    test('403 es sin permiso', () async {
      server.failWith = 403;
      await expectLater(
        repo.list(const DocumentQuery()),
        fails(DocumentsError.permissionDenied),
      );
    });

    test('403 sin carreteras asignadas se distingue del permiso', () async {
      server.failWith = 403;
      server.failBody = {'code': 'ROAD_ACCESS_REQUIRED'};
      await expectLater(
        repo.list(const DocumentQuery()),
        fails(DocumentsError.noRoadAccess),
      );
    });

    test('500 es fallo del servidor', () async {
      server.failWith = 500;
      await expectLater(repo.detail('d1'), fails(DocumentsError.server));
    });
  });
}
