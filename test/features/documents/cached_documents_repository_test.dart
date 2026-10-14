import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sigaco_movil/core/offline/operation.dart';
import 'package:sigaco_movil/features/documents/data/cache/documents_cache.dart';
import 'package:sigaco_movil/features/documents/data/repositories/cached_documents_repository.dart';
import 'package:sigaco_movil/features/documents/data/repositories/sample_documents_repository.dart';
import 'package:sigaco_movil/features/documents/domain/entities/document.dart';
import 'package:sigaco_movil/features/documents/domain/entities/document_catalogs.dart';
import 'package:sigaco_movil/features/documents/domain/entities/document_preview.dart';
import 'package:sigaco_movil/features/documents/domain/entities/document_query.dart';
import 'package:sigaco_movil/features/documents/domain/repositories/documents_repository.dart';

const _scope = OfflineScope(userId: 'ana', concessionId: 'c1');
final _now = DateTime.utc(2026, 10, 14, 12);

/// El repositorio de ejemplo, al que se le puede quitar la red o hacer fallar.
class _Server extends SampleDocumentsRepository {
  _Server() : super(clock: () => _now);

  DocumentsError? failWith;
  int signs = 0;

  Future<void> _check() async {
    final error = failWith;
    if (error != null) throw DocumentsException(error);
  }

  @override
  Future<DocumentListing> list(DocumentQuery query) async {
    await _check();
    return super.list(query);
  }

  @override
  Future<DocumentDetail> detail(String id) async {
    await _check();
    return super.detail(id);
  }

  @override
  Future<DocumentPreview> preview(String id) async {
    await _check();
    return super.preview(id);
  }

  @override
  Future<DocumentCatalogs> catalogs() async {
    await _check();
    return super.catalogs();
  }

  @override
  Future<DocumentSignature> sign(String id, String versionId) async {
    await _check();
    signs++;
    return super.sign(id, versionId);
  }
}

/// Lo ya consultado se ve sin conexion, con su fecha, y nada mas (DTF M03 §3.2,
/// CA-HU-MOB-03-01-05 y 06).
void main() {
  late Directory dir;
  late _Server server;
  late FileDocumentsCache cache;
  late CachedDocumentsRepository repo;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('cached_repo_test');
    server = _Server();
    cache = FileDocumentsCache(root: () async => dir, clock: () => _now);
    await cache.bind(_scope);
    repo = CachedDocumentsRepository(server, cache);
  });

  tearDown(() async {
    if (await dir.exists()) await dir.delete(recursive: true);
  });

  Matcher fails(DocumentsError error) =>
      throwsA(isA<DocumentsException>().having((e) => e.error, 'error', error));

  group('lista', () {
    test(
      'con conexion viene del servidor y no se marca como guardada',
      () async {
        final listing = await repo.list(const DocumentQuery());

        expect(listing, isNotEmpty);
        expect(listing.cachedAt, isNull);
        expect(listing.fromPhone, isFalse);
      },
    );

    test('sin conexion devuelve la ultima lista, con su fecha', () async {
      final online = await repo.list(const DocumentQuery());
      server.failWith = DocumentsError.network;

      final offline = await repo.list(const DocumentQuery());

      expect(offline.map((d) => d.id), online.map((d) => d.id));
      expect(offline.cachedAt, _now);
      expect(offline.fromPhone, isTrue);
    });

    test(
      'sin conexion y sin nada guardado, avisa que no hay conexion',
      () async {
        server.failWith = DocumentsError.network;

        await expectLater(
          repo.list(const DocumentQuery()),
          fails(DocumentsError.network),
        );
      },
    );

    test('una consulta distinta no recibe la lista de otra', () async {
      await repo.list(const DocumentQuery());
      server.failWith = DocumentsError.network;

      await expectLater(
        repo.list(const DocumentQuery(view: DocumentView.favorites)),
        fails(DocumentsError.network),
      );
    });

    test('un fallo que no es de red nunca entrega lo guardado', () async {
      await repo.list(const DocumentQuery());
      for (final error in [
        DocumentsError.permissionDenied,
        DocumentsError.server,
        DocumentsError.noRoadAccess,
      ]) {
        server.failWith = error;
        await expectLater(repo.list(const DocumentQuery()), fails(error));
      }
    });
  });

  group('ficha', () {
    test('sin conexion devuelve la ficha ya vista, con su fecha', () async {
      await repo.detail('d-001');
      server.failWith = DocumentsError.network;

      final saved = await repo.detail('d-001');

      expect(saved.summary.id, 'd-001');
      expect(saved.cachedAt, _now);
    });

    test('un documento que nunca se abrio pide conexion', () async {
      server.failWith = DocumentsError.network;

      await expectLater(
        repo.detail('d-001'),
        fails(DocumentsError.notAvailableOffline),
      );
    });

    test('un documento que ya no existe no sale del cache', () async {
      await repo.detail('d-001');
      server.failWith = DocumentsError.notFound;

      await expectLater(repo.detail('d-001'), fails(DocumentsError.notFound));
    });
  });

  group('vista previa', () {
    test('sin conexion se ve la que ya se abrio', () async {
      final live = await repo.preview('d-004');
      server.failWith = DocumentsError.network;

      final saved = await repo.preview('d-004');

      expect(saved.kind, live.kind);
      expect(saved.bytes, live.bytes);
      expect(saved.cachedAt, _now);
    });

    test('una que no se abrio pide conexion', () async {
      server.failWith = DocumentsError.network;

      await expectLater(
        repo.preview('d-004'),
        fails(DocumentsError.notAvailableOffline),
      );
    });

    test('lo que no tiene visor no se guarda y pide conexion', () async {
      // d-002 es un plano .dwg: no tiene vista previa.
      final none = await repo.preview('d-002');
      expect(none.kind, PreviewKind.unsupported);
      server.failWith = DocumentsError.network;

      await expectLater(
        repo.preview('d-002'),
        fails(DocumentsError.notAvailableOffline),
      );
    });
  });

  group('catalogos', () {
    test('sin conexion se usan los ultimos para poder capturar', () async {
      final live = await repo.catalogs();
      server.failWith = DocumentsError.network;

      final saved = await repo.catalogs();

      expect(saved.types.map((e) => e.code), live.types.map((e) => e.code));
      expect(saved.folders, live.folders);
    });

    test('sin conexion y sin nada guardado falla como antes', () async {
      server.failWith = DocumentsError.network;

      await expectLater(repo.catalogs(), fails(DocumentsError.network));
    });
  });

  group('cambios', () {
    test('marcar favorito deja de servir la ficha guardada', () async {
      await repo.detail('d-001');
      await repo.setFavorite('d-001', favorite: true);
      server.failWith = DocumentsError.network;

      await expectLater(
        repo.detail('d-001'),
        fails(DocumentsError.notAvailableOffline),
      );
    });

    test('firmar deja de servir la ficha guardada', () async {
      final detail = await repo.detail('d-006');
      final status = await repo.sign('d-006', detail.versionId);
      expect(status, DocumentSignature.validated);
      server.failWith = DocumentsError.network;

      // La ficha de antes decia «sin firma».
      await expectLater(
        repo.detail('d-006'),
        fails(DocumentsError.notAvailableOffline),
      );
    });

    test('un fallo al firmar no toca lo guardado', () async {
      await repo.detail('d-006');
      server.failWith = DocumentsError.alreadySigned;

      await expectLater(
        repo.sign('d-006', ''),
        fails(DocumentsError.alreadySigned),
      );
      server.failWith = DocumentsError.network;
      expect((await repo.detail('d-006')).cachedAt, _now);
    });
  });

  test('un cache que falla al guardar no rompe la consulta', () async {
    final broken = CachedDocumentsRepository(server, _BrokenCache());

    final listing = await broken.list(const DocumentQuery());

    expect(listing, isNotEmpty);
  });

  test('sin alcance (nadie inicio sesion) no se guarda nada', () async {
    await cache.bind(null);
    await repo.list(const DocumentQuery());
    server.failWith = DocumentsError.network;

    await expectLater(
      repo.list(const DocumentQuery()),
      fails(DocumentsError.network),
    );
  });

  test('el contenido guardado es el mismo que entrego el servidor', () async {
    final live = await repo.preview('d-004');
    server.failWith = DocumentsError.network;
    final saved = await repo.preview('d-004');

    expect(Uint8List.fromList(saved.bytes), Uint8List.fromList(live.bytes));
  });
}

class _BrokenCache extends NoDocumentsCache {
  @override
  Future<void> saveList(
    DocumentQuery query,
    List<DocumentSummary> items,
  ) async => throw const FileSystemException('disco lleno');
}
