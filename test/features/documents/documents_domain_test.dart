import 'package:flutter_test/flutter_test.dart';
import 'package:sigaco_movil/features/documents/data/repositories/sample_documents_repository.dart';
import 'package:sigaco_movil/features/documents/domain/entities/document.dart';
import 'package:sigaco_movil/features/documents/domain/entities/document_access.dart';
import 'package:sigaco_movil/features/documents/domain/entities/document_query.dart';
import 'package:sigaco_movil/features/documents/domain/repositories/documents_repository.dart';
import 'package:sigaco_movil/features/documents/presentation/document_labels.dart';
import 'package:sigaco_movil/features/navigation/domain/entities/mobile_module.dart';

import '../../support/fakes.dart';

final _now = DateTime.utc(2026, 10, 12, 12);

SampleDocumentsRepository _repo() =>
    SampleDocumentsRepository(clock: () => _now);

Future<List<String>> _ids(
  SampleDocumentsRepository repo,
  DocumentQuery query,
) async => [for (final d in await repo.list(query)) d.id];

void main() {
  group('permisos del gestor documental (DEV-MOB-092)', () {
    DocumentAccess access(Iterable<String> keys) =>
        DocumentAccess.fromPermissions(keys);

    test('sin permisos no se concede nada', () {
      expect(access(const []), DocumentAccess.none);
    });

    test('Ver habilita la consulta y nada mas', () {
      final a = access([DocumentAccess.viewKey]);
      expect(a.canView, isTrue);
      expect(a.canUpload, isFalse);
      expect(a.canSign, isFalse);
    });

    test('Cargar y Firmar se suman a Ver', () {
      final up = access([DocumentAccess.viewKey, DocumentAccess.uploadKey]);
      expect((up.canView, up.canUpload, up.canSign), (true, true, false));
      final sign = access([DocumentAccess.viewKey, DocumentAccess.signKey]);
      expect((sign.canView, sign.canUpload, sign.canSign), (true, false, true));
      final all = access([
        DocumentAccess.viewKey,
        DocumentAccess.uploadKey,
        DocumentAccess.signKey,
      ]);
      expect((all.canView, all.canUpload, all.canSign), (true, true, true));
    });

    test('Cargar o Firmar sin Ver no conceden ninguna accion', () {
      for (final keys in [
        [DocumentAccess.uploadKey],
        [DocumentAccess.signKey],
        [DocumentAccess.uploadKey, DocumentAccess.signKey],
      ]) {
        expect(access(keys), DocumentAccess.none, reason: '$keys');
      }
    });

    test('otras claves del menu no cuentan', () {
      expect(access(['MANTENIMIENTO:R', 'DOCUMENTOS:X']), DocumentAccess.none);
    });
  });

  group('tarjeta del menu (DEV-MOB-091)', () {
    test('aparece solo si el menu trae el modulo', () {
      expect(
        MobileModule.availableIn(menuWith(['DOCUMENTOS'])),
        contains(MobileModule.documents),
      );
      expect(
        MobileModule.availableIn(menuWith(['PANEL', 'TICKETS'])),
        isNot(contains(MobileModule.documents)),
      );
    });
  });

  group('filtros y consulta', () {
    test('sin filtros esta vacio y no cuenta nada', () {
      expect(DocumentFilters.none.isEmpty, isTrue);
      expect(DocumentFilters.none.activeCount, 0);
      expect(const DocumentQuery().hasCriteria, isFalse);
    });

    test('el rango cuenta como un solo filtro', () {
      final f = DocumentFilters(
        typeCode: 'TD02',
        from: DateTime.utc(2026, 10, 1),
        to: DateTime.utc(2026, 10, 5),
      );
      expect(f.activeCount, 2);
      expect(const DocumentQuery().copyWith(filters: f).hasCriteria, isTrue);
    });

    test('un texto en blanco no es un criterio', () {
      expect(const DocumentQuery(search: '   ').hasCriteria, isFalse);
    });

    test('Desde posterior a Hasta es invalido; el mismo dia no', () {
      final a = DateTime.utc(2026, 10, 5);
      final b = DateTime.utc(2026, 10, 3);
      expect(DocumentFilters(from: a, to: b).rangeIsValid, isFalse);
      expect(DocumentFilters(from: b, to: a).rangeIsValid, isTrue);
      expect(DocumentFilters(from: a, to: a).rangeIsValid, isTrue);
      expect(DocumentFilters(from: a).rangeIsValid, isTrue);
    });
  });

  group('documentos de ejemplo con las reglas del servidor', () {
    test(
      'Todos: ordenados por ultima modificacion, la mas reciente primero',
      () async {
        final repo = _repo();
        final all = await repo.list(const DocumentQuery());
        expect(all, hasLength(14));
        for (var i = 1; i < all.length; i++) {
          expect(
            all[i - 1].modifiedAt.isAfter(all[i].modifiedAt),
            isTrue,
            reason: 'posicion $i',
          );
        }
      },
    );

    test('Mis documentos: solo los del usuario de la sesion (CA-02)', () async {
      final repo = _repo();
      expect(await _ids(repo, const DocumentQuery(view: DocumentView.mine)), [
        'd-004',
        'd-001',
        'd-012',
        'd-007',
        'd-010',
      ]);
      final other = SampleDocumentsRepository(clock: () => _now, me: 'gnova');
      expect(await _ids(other, const DocumentQuery(view: DocumentView.mine)), [
        'd-005',
        'd-006',
        'd-011',
      ]);
    });

    test('Favoritos: solo los marcados por el usuario (CA-03)', () async {
      final repo = _repo();
      expect(
        await _ids(repo, const DocumentQuery(view: DocumentView.favorites)),
        ['d-001', 'd-003', 'd-008'],
      );
      await repo.setFavorite('d-002', favorite: true);
      await repo.setFavorite('d-001', favorite: false);
      expect(
        await _ids(repo, const DocumentQuery(view: DocumentView.favorites)),
        ['d-002', 'd-003', 'd-008'],
      );
    });

    test(
      'Recientes: actividad propia de los ultimos 30 dias, la mas reciente primero (CA-04)',
      () async {
        final repo = _repo();
        expect(
          await _ids(repo, const DocumentQuery(view: DocumentView.recent)),
          ['d-004', 'd-001', 'd-012', 'd-003', 'd-007', 'd-005'],
        );
      },
    );

    test('abrir una ficha cuenta como actividad y sube el documento', () async {
      final repo = _repo();
      await repo.detail('d-014');
      expect(
        (await _ids(
          repo,
          const DocumentQuery(view: DocumentView.recent),
        )).first,
        'd-014',
      );
    });

    test('Recientes: no pasa de 50 documentos', () async {
      final base = DocumentSummary(
        id: 'x',
        name: 'x.pdf',
        typeCode: 'TD02',
        typeLabel: 'Informe',
        ownerUsername: 'amartinez',
        modifiedAt: _now,
      );
      DocumentDetail doc(int i) => DocumentDetail(
        summary: DocumentSummary(
          id: 'r-$i',
          name: 'doc $i.pdf',
          typeCode: base.typeCode,
          typeLabel: base.typeLabel,
          ownerUsername: base.ownerUsername,
          modifiedAt: _now,
        ),
        version: 1,
        sizeBytes: 10,
        modifiedBy: 'amartinez',
      );
      final repo = SampleDocumentsRepository(
        clock: () => _now,
        documents: [for (var i = 0; i < 60; i++) doc(i)],
        activity: {
          for (var i = 0; i < 60; i++)
            'r-$i': _now.subtract(Duration(minutes: i)),
        },
      );
      final ids = await _ids(
        repo,
        const DocumentQuery(view: DocumentView.recent),
      );
      expect(ids, hasLength(50));
      expect(ids.toSet(), hasLength(50));
      expect(ids.first, 'r-0');
    });

    test('la busqueda mira nombre, propietario y categoria', () async {
      final repo = _repo();
      expect(await _ids(repo, const DocumentQuery(search: 'inspección')), [
        'd-001',
      ]);
      expect(await _ids(repo, const DocumentQuery(search: 'RRODRIGUEZ')), [
        'd-002',
        'd-009',
        'd-014',
      ]);
      expect(await _ids(repo, const DocumentQuery(search: 'legal')), ['d-010']);
      expect(
        await _ids(repo, const DocumentQuery(search: 'no existe')),
        isEmpty,
      );
    });

    test('busqueda y filtros se combinan con la vista (CA-05)', () async {
      final repo = _repo();
      expect(
        await _ids(
          repo,
          const DocumentQuery(
            view: DocumentView.mine,
            filters: DocumentFilters(typeCode: 'TD10'),
          ),
        ),
        ['d-004', 'd-012'],
      );
      expect(
        await _ids(
          repo,
          const DocumentQuery(
            search: 'foto',
            filters: DocumentFilters(categoryCode: 'CAT03'),
          ),
        ),
        ['d-004'],
      );
      expect(
        await _ids(
          repo,
          const DocumentQuery(
            filters: DocumentFilters(modifiedBy: 'amartinez'),
          ),
        ),
        contains('d-009'),
      );
      expect(
        await _ids(
          repo,
          const DocumentQuery(filters: DocumentFilters(folder: 'Legal')),
        ),
        ['d-005', 'd-010', 'd-006'],
      );
    });

    test('el rango Desde/Hasta incluye el dia completo de Hasta', () async {
      final repo = _repo();
      final both = DocumentFilters(
        from: DateTime.utc(2026, 10, 10),
        to: DateTime.utc(2026, 10, 12),
      );
      expect(await _ids(repo, DocumentQuery(filters: both)), [
        'd-004',
        'd-001',
        'd-012',
      ]);
      final until11 = DocumentFilters(
        from: DateTime.utc(2026, 10, 10),
        to: DateTime.utc(2026, 10, 11),
      );
      expect(await _ids(repo, DocumentQuery(filters: until11)), [
        'd-001',
        'd-012',
      ]);
    });

    test(
      'la ficha trae la version vigente y un documento ajeno no existe',
      () async {
        final repo = _repo();
        final d = await repo.detail('d-001');
        expect(d.version, 3);
        expect(d.summary.signature, DocumentSignature.validated);
        expect(
          () => repo.detail('nope'),
          throwsA(
            isA<DocumentsException>().having(
              (e) => e.error,
              'error',
              DocumentsError.notFound,
            ),
          ),
        );
      },
    );

    test('los catalogos son los iniciales del DTF', () async {
      final c = await _repo().catalogs();
      expect(c.types.map((t) => t.code), [
        for (var i = 1; i <= 12; i++) 'TD${i.toString().padLeft(2, '0')}',
      ]);
      expect(c.categories, hasLength(10));
      expect(c.folders, contains('Legal'));
    });

    test('failNextWith falla una sola vez', () async {
      final repo = _repo()..failNextWith = DocumentsError.network;
      await expectLater(
        repo.list(const DocumentQuery()),
        throwsA(isA<DocumentsException>()),
      );
      expect(await repo.list(const DocumentQuery()), isNotEmpty);
    });
  });

  group('etiquetas', () {
    test('tamanos legibles', () {
      expect(formatBytes(0), '0 B');
      expect(formatBytes(900), '900 B');
      expect(formatBytes(1024), '1 KB');
      expect(formatBytes(480000), '469 KB');
      expect(formatBytes(2400000), '2.3 MB');
      expect(formatBytes(18200000), '17.4 MB');
      expect(formatBytes(5 * 1024 * 1024 * 1024), '5 GB');
    });

    test('un icono por formato y uno generico para el resto', () {
      expect(fileIcon('pdf'), isNot(fileIcon('png')));
      expect(fileIcon('zzz'), fileIcon(''));
    });
  });
}
