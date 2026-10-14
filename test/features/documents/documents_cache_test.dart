import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sigaco_movil/core/offline/operation.dart';
import 'package:sigaco_movil/features/documents/data/cache/documents_cache.dart';
import 'package:sigaco_movil/features/documents/domain/entities/document.dart';
import 'package:sigaco_movil/features/documents/domain/entities/document_catalogs.dart';
import 'package:sigaco_movil/features/documents/domain/entities/document_preview.dart';
import 'package:sigaco_movil/features/documents/domain/entities/document_query.dart';

const _ana = OfflineScope(userId: 'ana', concessionId: 'c1');
const _anaOtraConcesion = OfflineScope(userId: 'ana', concessionId: 'c2');
const _luis = OfflineScope(userId: 'luis', concessionId: 'c1');

final _at = DateTime.utc(2026, 10, 14, 15, 30);

DocumentSummary _doc(String id, {bool favorite = false}) => DocumentSummary(
  id: id,
  name: 'Informe $id.pdf',
  typeCode: 'TD01',
  typeLabel: 'Informe',
  categoryCode: 'CT01',
  categoryLabel: 'Contratos',
  ownerUsername: 'ana',
  modifiedAt: DateTime.utc(2026, 10, 10, 9),
  signature: DocumentSignature.pending,
  isFavorite: favorite,
  format: 'pdf',
);

DocumentDetail _detail(String id) => DocumentDetail(
  summary: _doc(id, favorite: true),
  version: 3,
  sizeBytes: 2048,
  modifiedBy: 'luis',
  description: 'Descripcion',
  folder: 'Obras/2026',
  previewAvailable: true,
  versionId: 'ver-$id',
  checksum: 'abc123',
);

/// Lo ya consultado queda en el telefono para verlo sin conexion, y es de una
/// persona y una concesion (DTF M03 §3.2, RN-CTX-02).
void main() {
  late Directory dir;
  late FileDocumentsCache cache;

  FileDocumentsCache build({int maxPreviews = 30, int maxLists = 30}) =>
      FileDocumentsCache(
        root: () async => dir,
        clock: () => _at,
        maxPreviews: maxPreviews,
        maxLists: maxLists,
        maxPreviewBytes: 1000,
      );

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('docs_cache_test');
    cache = build();
  });

  tearDown(() async {
    if (await dir.exists()) await dir.delete(recursive: true);
  });

  group('sin alcance', () {
    test('no guarda ni entrega nada hasta que alguien inicia sesion', () async {
      await cache.saveList(const DocumentQuery(), [_doc('a')]);
      await cache.saveDetail(_detail('a'));
      await cache.saveCatalogs(const DocumentCatalogs());

      expect(await cache.readList(const DocumentQuery()), isNull);
      expect(await cache.readDetail('a'), isNull);
      expect(await cache.readCatalogs(), isNull);
    });
  });

  group('lista', () {
    setUp(() => cache.bind(_ana));

    test('devuelve la lista con la fecha en que se guardo', () async {
      await cache.saveList(const DocumentQuery(), [_doc('a'), _doc('b')]);

      final saved = await cache.readList(const DocumentQuery());

      expect(saved, isNotNull);
      expect(saved!.map((d) => d.id), ['a', 'b']);
      expect(saved.cachedAt, _at);
      expect(saved.fromPhone, isTrue);
      expect(saved.first.signature, DocumentSignature.pending);
      expect(saved.first.modifiedAt, DateTime.utc(2026, 10, 10, 9));
    });

    test('cada consulta tiene su propia lista', () async {
      await cache.saveList(const DocumentQuery(), [_doc('a')]);
      await cache.saveList(const DocumentQuery(view: DocumentView.favorites), [
        _doc('b'),
      ]);
      await cache.saveList(const DocumentQuery(search: 'Acta'), [_doc('c')]);

      expect((await cache.readList(const DocumentQuery()))!.single.id, 'a');
      expect(
        (await cache.readList(
          const DocumentQuery(view: DocumentView.favorites),
        ))!.single.id,
        'b',
      );
      // La busqueda no distingue mayusculas ni espacios de los bordes.
      expect(
        (await cache.readList(
          const DocumentQuery(search: ' acta '),
        ))!.single.id,
        'c',
      );
      expect(await cache.readList(const DocumentQuery(search: 'otra')), isNull);
    });

    test('los filtros forman parte de la consulta', () async {
      const filtered = DocumentQuery(
        filters: DocumentFilters(typeCode: 'TD01', folder: 'Obras'),
      );
      await cache.saveList(filtered, [_doc('a')]);

      expect(await cache.readList(filtered), isNotNull);
      expect(await cache.readList(const DocumentQuery()), isNull);
      expect(
        await cache.readList(
          const DocumentQuery(filters: DocumentFilters(typeCode: 'TD02')),
        ),
        isNull,
      );
    });

    test('guarda solo las listas mas recientes', () async {
      cache = build(maxLists: 2);
      await cache.bind(_ana);
      for (final q in ['uno', 'dos', 'tres']) {
        await cache.saveList(DocumentQuery(search: q), [_doc(q)]);
        // Fechas de archivo distintas para saber cual es la mas vieja.
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }

      expect(await cache.readList(const DocumentQuery(search: 'uno')), isNull);
      expect(
        await cache.readList(const DocumentQuery(search: 'dos')),
        isNotNull,
      );
      expect(
        await cache.readList(const DocumentQuery(search: 'tres')),
        isNotNull,
      );
    });
  });

  group('ficha', () {
    setUp(() => cache.bind(_ana));

    test('guarda version, hash y fecha', () async {
      await cache.saveDetail(_detail('a'));

      final saved = await cache.readDetail('a');

      expect(saved, isNotNull);
      expect(saved!.version, 3);
      expect(saved.versionId, 'ver-a');
      expect(saved.checksum, 'abc123');
      expect(saved.folder, 'Obras/2026');
      expect(saved.summary.isFavorite, isTrue);
      expect(saved.cachedAt, _at);
    });

    test('un documento que no se guardo no existe', () async {
      expect(await cache.readDetail('zzz'), isNull);
    });

    test('olvidar la ficha no toca la vista previa', () async {
      await cache.saveDetail(_detail('a'));
      await cache.savePreview(
        'a',
        DocumentPreview(kind: PreviewKind.pdf, bytes: Uint8List(10)),
      );

      await cache.forgetDetail('a');

      expect(await cache.readDetail('a'), isNull);
      expect(await cache.readPreview('a'), isNotNull);
    });

    test('un id raro no sale de la carpeta del cache', () async {
      await cache.saveDetail(_detail('../../evil'));

      final outside = File('${dir.parent.path}/evil.json');
      expect(await outside.exists(), isFalse);
      expect(await cache.readDetail('../../evil'), isNotNull);
    });
  });

  group('vista previa', () {
    setUp(() => cache.bind(_ana));

    test('guarda los bytes y su tipo', () async {
      await cache.savePreview(
        'a',
        DocumentPreview(
          kind: PreviewKind.image,
          bytes: Uint8List.fromList([1, 2, 3]),
        ),
      );

      final saved = await cache.readPreview('a');

      expect(saved!.kind, PreviewKind.image);
      expect(saved.bytes, [1, 2, 3]);
      expect(saved.cachedAt, _at);
    });

    test('lo que no tiene visor no se guarda', () async {
      await cache.savePreview(
        'a',
        DocumentPreview(kind: PreviewKind.unsupported, bytes: Uint8List(0)),
      );

      expect(await cache.readPreview('a'), isNull);
    });

    test('un archivo demasiado grande no se guarda', () async {
      await cache.savePreview(
        'a',
        DocumentPreview(kind: PreviewKind.pdf, bytes: Uint8List(1001)),
      );

      expect(await cache.readPreview('a'), isNull);
    });

    test('guarda solo las vistas previas mas recientes', () async {
      cache = build(maxPreviews: 2);
      await cache.bind(_ana);
      for (final id in ['a', 'b', 'c']) {
        await cache.savePreview(
          id,
          DocumentPreview(kind: PreviewKind.pdf, bytes: Uint8List(10)),
        );
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }

      expect(await cache.readPreview('a'), isNull);
      expect(await cache.readPreview('b'), isNotNull);
      expect(await cache.readPreview('c'), isNotNull);
    });
  });

  group('catalogos', () {
    setUp(() => cache.bind(_ana));

    test('guardan tipos, categorias, carpetas y usuarios', () async {
      await cache.saveCatalogs(
        const DocumentCatalogs(
          types: [
            CatalogEntry('TD01', 'Informe'),
            CatalogEntry('TD02', 'Viejo', active: false),
          ],
          categories: [CatalogEntry('CT01', 'Contratos')],
          folders: ['Obras'],
          users: ['ana'],
        ),
      );

      final saved = await cache.readCatalogs();

      expect(saved!.types.map((e) => e.code), ['TD01', 'TD02']);
      expect(saved.types.last.active, isFalse);
      expect(saved.categories.single.label, 'Contratos');
      expect(saved.folders, ['Obras']);
      expect(saved.users, ['ana']);
    });
  });

  group('de quien es lo guardado (RN-CTX-02)', () {
    setUp(() async {
      await cache.bind(_ana);
      await cache.saveList(const DocumentQuery(), [_doc('a')]);
      await cache.saveDetail(_detail('a'));
    });

    test('al volver a iniciar la misma persona, lo conserva', () async {
      // Se cierra la app sin cerrar sesion y se abre otra vez.
      final reopened = build();
      await reopened.bind(_ana);

      expect(await reopened.readList(const DocumentQuery()), isNotNull);
      expect(await reopened.readDetail('a'), isNotNull);
    });

    test('otra persona en el mismo telefono no ve lo ajeno', () async {
      final reopened = build();
      await reopened.bind(_luis);

      expect(await reopened.readList(const DocumentQuery()), isNull);
      expect(await reopened.readDetail('a'), isNull);
    });

    test(
      'la misma persona en otra concesion no ve lo de la anterior',
      () async {
        await cache.bind(_anaOtraConcesion);

        expect(await cache.readList(const DocumentQuery()), isNull);
        expect(await cache.readDetail('a'), isNull);
      },
    );

    test('al cerrar sesion se descarta todo', () async {
      await cache.bind(null);
      await cache.bind(_ana);

      expect(await cache.readList(const DocumentQuery()), isNull);
      expect(await cache.readDetail('a'), isNull);
    });

    test('vaciar descarta todo y deja de entregar', () async {
      await cache.clear();

      expect(await cache.readList(const DocumentQuery()), isNull);
      expect(await cache.readDetail('a'), isNull);
    });

    test('lo que se guarda tras cambiar de alcance es del nuevo', () async {
      await cache.bind(_luis);
      await cache.saveDetail(_detail('b'));

      final reopened = build();
      await reopened.bind(_ana);

      expect(await reopened.readDetail('b'), isNull);
      expect(await reopened.readDetail('a'), isNull);
    });
  });

  group('datos danados', () {
    setUp(() => cache.bind(_ana));

    test('un archivo ilegible se trata como si no existiera', () async {
      await cache.saveDetail(_detail('a'));
      final file = File('${dir.path}/data/detail_a.json');
      await file.writeAsString('{no es json');

      expect(await cache.readDetail('a'), isNull);
    });
  });
}
