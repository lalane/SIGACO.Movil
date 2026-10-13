import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sigaco_movil/features/documents/data/repositories/sample_documents_repository.dart';
import 'package:sigaco_movil/features/documents/domain/entities/document.dart';
import 'package:sigaco_movil/features/documents/domain/entities/document_catalogs.dart';
import 'package:sigaco_movil/features/documents/domain/entities/document_preview.dart';
import 'package:sigaco_movil/features/documents/domain/entities/document_query.dart';
import 'package:sigaco_movil/features/documents/domain/repositories/documents_repository.dart';
import 'package:sigaco_movil/features/documents/presentation/bloc/document_detail_cubit.dart';
import 'package:sigaco_movil/features/documents/presentation/bloc/documents_cubit.dart';

final _now = DateTime.utc(2026, 10, 12, 12);

/// El repositorio de ejemplo, que cuenta lo que se le pide y deja controlar
/// cuando responde cada consulta.
class _Spy implements DocumentsRepository {
  _Spy() : inner = SampleDocumentsRepository(clock: () => _now);

  final SampleDocumentsRepository inner;
  final queries = <DocumentQuery>[];
  final favorites = <(String, bool)>[];
  int catalogLoads = 0;
  Completer<void>? hold;
  bool failFavorites = false;

  /// Hace fallar la siguiente consulta de la lista (no la de catalogos, que se
  /// pide a la vez).
  DocumentsError? failList;

  @override
  Future<List<DocumentSummary>> list(DocumentQuery query) async {
    queries.add(query);
    final error = failList;
    if (error != null) {
      failList = null;
      throw DocumentsException(error);
    }
    final gate = hold;
    if (gate != null) await gate.future;
    return inner.list(query);
  }

  @override
  Future<DocumentDetail> detail(String id) => inner.detail(id);

  @override
  Future<DocumentPreview> preview(String id) => inner.preview(id);

  @override
  Future<void> setFavorite(String id, {required bool favorite}) async {
    favorites.add((id, favorite));
    if (failFavorites) throw const DocumentsException(DocumentsError.server);
    return inner.setFavorite(id, favorite: favorite);
  }

  @override
  Future<DocumentCatalogs> catalogs() {
    catalogLoads++;
    return inner.catalogs();
  }
}

void main() {
  group('consulta de documentos (068 y 069)', () {
    late _Spy repo;
    late DocumentsCubit cubit;

    setUp(() {
      repo = _Spy();
      cubit = DocumentsCubit(repo);
    });
    tearDown(() => cubit.close());

    test('al cargar muestra Todos y trae los catalogos', () async {
      expect(cubit.state.status, DocumentsStatus.loading);
      await cubit.load();
      expect(cubit.state.status, DocumentsStatus.ready);
      expect(cubit.state.items, hasLength(14));
      expect(cubit.state.query.view, DocumentView.all);
      await Future<void>.delayed(Duration.zero);
      expect(repo.catalogLoads, 1);
      expect(cubit.state.catalogs.types, isNotEmpty);
    });

    test('cada vista vuelve a consultar con su vista', () async {
      await cubit.load();
      await cubit.selectView(DocumentView.favorites);
      expect(cubit.state.items.map((d) => d.id), ['d-001', 'd-003', 'd-008']);
      await cubit.selectView(DocumentView.mine);
      expect(cubit.state.items, hasLength(5));
      expect(repo.queries.map((q) => q.view), [
        DocumentView.all,
        DocumentView.favorites,
        DocumentView.mine,
      ]);
    });

    test('elegir la vista que ya esta abierta no consulta de nuevo', () async {
      await cubit.load();
      await cubit.selectView(DocumentView.all);
      expect(repo.queries, hasLength(1));
    });

    test(
      'buscar y filtrar se combinan y se conservan al cambiar de vista',
      () async {
        await cubit.load();
        await cubit.search('  foto ');
        expect(cubit.state.query.search, 'foto');
        await cubit.applyFilters(const DocumentFilters(categoryCode: 'CAT03'));
        expect(cubit.state.items.map((d) => d.id), ['d-004']);
        await cubit.selectView(DocumentView.mine);
        expect(cubit.state.query.search, 'foto');
        expect(cubit.state.query.filters.categoryCode, 'CAT03');
        expect(cubit.state.items.map((d) => d.id), ['d-004']);
      },
    );

    test('la misma busqueda no consulta otra vez', () async {
      await cubit.load();
      await cubit.search('foto');
      await cubit.search('foto');
      expect(repo.queries, hasLength(2));
    });

    test(
      'un rango con Desde posterior a Hasta se rechaza sin consultar (CA-05)',
      () async {
        await cubit.load();
        await cubit.applyFilters(const DocumentFilters(typeCode: 'TD02'));
        final before = repo.queries.length;
        final items = cubit.state.items;
        await cubit.applyFilters(
          DocumentFilters(
            typeCode: 'TD10',
            from: DateTime.utc(2026, 10, 5),
            to: DateTime.utc(2026, 10, 1),
          ),
        );
        expect(cubit.state.rangeRejected, isTrue);
        expect(repo.queries, hasLength(before));
        // Los filtros y el resultado anteriores siguen en pie.
        expect(cubit.state.query.filters.typeCode, 'TD02');
        expect(cubit.state.items, items);
        // Corregido el rango, se aplica.
        await cubit.applyFilters(
          DocumentFilters(
            typeCode: 'TD10',
            from: DateTime.utc(2026, 10, 1),
            to: DateTime.utc(2026, 10, 5),
          ),
        );
        expect(cubit.state.rangeRejected, isFalse);
        expect(repo.queries, hasLength(before + 1));
      },
    );

    test(
      'limpiar quita la busqueda y los filtros y conserva la vista',
      () async {
        await cubit.load();
        await cubit.selectView(DocumentView.mine);
        await cubit.search('zzz');
        expect(cubit.state.items, isEmpty);
        await cubit.clearCriteria();
        expect(cubit.state.query.hasCriteria, isFalse);
        expect(cubit.state.query.view, DocumentView.mine);
        expect(cubit.state.items, hasLength(5));
      },
    );

    test(
      'gana la ultima consulta aunque la anterior responda despues',
      () async {
        await cubit.load();
        repo.hold = Completer<void>();
        final slow = cubit.selectView(DocumentView.favorites);
        final slowGate = repo.hold!;
        repo.hold = null;
        await cubit.selectView(DocumentView.mine);
        slowGate.complete();
        await slow;
        expect(cubit.state.query.view, DocumentView.mine);
        expect(cubit.state.items, hasLength(5));
      },
    );

    test('un fallo se distingue y se puede reintentar', () async {
      repo.failList = DocumentsError.network;
      await cubit.load();
      expect(cubit.state.status, DocumentsStatus.failure);
      expect(cubit.state.error, DocumentsError.network);
      await cubit.retry();
      expect(cubit.state.status, DocumentsStatus.ready);
      expect(cubit.state.error, isNull);
    });

    test('un error inesperado se trata como fallo del servidor', () async {
      final broken = DocumentsCubit(_Throwing());
      addTearDown(broken.close);
      await broken.load();
      expect(broken.state.status, DocumentsStatus.failure);
      expect(broken.state.error, DocumentsError.server);
    });

    test('si los catalogos no llegan, la lista funciona igual', () async {
      final c = DocumentsCubit(_NoCatalogs());
      addTearDown(c.close);
      await c.load();
      expect(c.state.status, DocumentsStatus.ready);
      expect(c.state.catalogs.types, isEmpty);
    });

    test('actualizar no vacia la lista mientras consulta', () async {
      await cubit.load();
      repo.hold = Completer<void>();
      final refreshing = cubit.refresh();
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.status, DocumentsStatus.ready);
      expect(cubit.state.items, hasLength(14));
      repo.hold!.complete();
      await refreshing;
    });

    group('favoritos', () {
      test('se marca al instante y se guarda', () async {
        await cubit.load();
        final doc = cubit.state.items.firstWhere((d) => d.id == 'd-002');
        final future = cubit.toggleFavorite(doc);
        expect(
          cubit.state.items.firstWhere((d) => d.id == 'd-002').isFavorite,
          isTrue,
        );
        await future;
        expect(repo.favorites, [('d-002', true)]);
      });

      test('quitarlo en Favoritos lo saca de la lista', () async {
        await cubit.load();
        await cubit.selectView(DocumentView.favorites);
        await cubit.toggleFavorite(cubit.state.items.first);
        expect(cubit.state.items.map((d) => d.id), ['d-003', 'd-008']);
      });

      test('si el servidor no lo acepta, se revierte y se avisa', () async {
        await cubit.load();
        repo.failFavorites = true;
        final doc = cubit.state.items.firstWhere((d) => d.id == 'd-001');
        await cubit.toggleFavorite(doc);
        expect(
          cubit.state.items.firstWhere((d) => d.id == 'd-001').isFavorite,
          isTrue,
        );
        expect(cubit.state.favoriteFailed, 1);
      });
    });

    test('cerrar el cubit con una consulta en vuelo no falla', () async {
      await cubit.load();
      repo.hold = Completer<void>();
      final pending = cubit.selectView(DocumentView.mine);
      await cubit.close();
      repo.hold!.complete();
      await pending;
    });
  });

  group('ficha (070)', () {
    late _Spy repo;
    late DocumentDetailCubit cubit;

    setUp(() {
      repo = _Spy();
      cubit = DocumentDetailCubit(repo, 'd-001');
    });
    tearDown(() => cubit.close());

    test('carga la version vigente', () async {
      await cubit.load();
      expect(cubit.state.status, DocumentDetailStatus.ready);
      expect(cubit.state.detail!.version, 3);
    });

    test('un documento que ya no existe se distingue', () async {
      final c = DocumentDetailCubit(repo, 'nope');
      addTearDown(c.close);
      await c.load();
      expect(c.state.status, DocumentDetailStatus.failure);
      expect(c.state.error, DocumentsError.notFound);
    });

    test('el favorito se refleja al instante y se guarda', () async {
      await cubit.load();
      expect(cubit.state.detail!.summary.isFavorite, isTrue);
      final future = cubit.toggleFavorite();
      expect(cubit.state.detail!.summary.isFavorite, isFalse);
      await future;
      expect(repo.favorites, [('d-001', false)]);
    });

    test('si no se guarda, vuelve como estaba y avisa', () async {
      await cubit.load();
      repo.failFavorites = true;
      await cubit.toggleFavorite();
      expect(cubit.state.detail!.summary.isFavorite, isTrue);
      expect(cubit.state.favoriteFailed, 1);
    });

    test('sin ficha cargada, marcar favorito no hace nada', () async {
      await cubit.toggleFavorite();
      expect(repo.favorites, isEmpty);
    });

    test('reintentar despues de un fallo', () async {
      repo.inner.failNextWith = DocumentsError.network;
      await cubit.load();
      expect(cubit.state.error, DocumentsError.network);
      await cubit.load();
      expect(cubit.state.status, DocumentDetailStatus.ready);
    });
  });
}

class _Throwing implements DocumentsRepository {
  @override
  Future<List<DocumentSummary>> list(DocumentQuery query) async =>
      throw StateError('inesperado');

  @override
  Future<DocumentDetail> detail(String id) async => throw StateError('x');

  @override
  Future<DocumentPreview> preview(String id) async => throw StateError('x');

  @override
  Future<void> setFavorite(String id, {required bool favorite}) async {}

  @override
  Future<DocumentCatalogs> catalogs() async => throw StateError('x');
}

class _NoCatalogs extends SampleDocumentsRepository {
  _NoCatalogs() : super(clock: () => _now);

  @override
  Future<DocumentCatalogs> catalogs() async =>
      throw StateError('sin catalogos');
}
