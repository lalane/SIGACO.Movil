import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sigaco_movil/features/inventory/domain/entities/asset_capture.dart';
import 'package:sigaco_movil/features/inventory/domain/entities/inventory_asset.dart';
import 'package:sigaco_movil/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:sigaco_movil/features/inventory/presentation/bloc/inventory_cubit.dart';

InventoryAsset _asset(String id, {String? typeCode}) => InventoryAsset(
  id: id,
  code: id,
  name: id,
  category: typeCode ?? 'Defensa',
  typeCode: typeCode,
  condition: AssetCondition.unknown,
);

/// Un servidor que pagina de a 10 y anota lo que se le pide. Con [gate],
/// las paginas esperan a que se abra (para ver que pasa mientras tanto).
class _Server implements InventoryRepository {
  _Server(this.rows);

  final int rows;
  final int size = 10;
  final pages = <({InventoryQuery query, Object? after})>[];
  final countQueries = <InventoryQuery>[];
  final cancellations = <InventoryCancellation?>[];
  Completer<void>? gate;
  InventoryError? fail;

  @override
  Future<InventoryResultPage> page(
    InventoryQuery query, {
    Object? after,
    InventoryCancellation? cancellation,
  }) async {
    pages.add((query: query, after: after));
    cancellations.add(cancellation);
    final wait = gate;
    if (wait != null) await wait.future;
    final error = fail;
    if (error != null) throw InventoryException(error);
    final from = after is int ? after : 0;
    final to = (from + size).clamp(0, rows);
    return InventoryResultPage(
      items: [for (var i = from; i < to; i++) _asset('${query.search}$i')],
      total: rows,
      next: to < rows ? to : null,
    );
  }

  @override
  Future<InventoryCounts> counts(
    InventoryQuery query, {
    InventoryCancellation? cancellation,
  }) async {
    countQueries.add(query);
    return InventoryCounts(total: rows, good: 2, regular: 1, poor: 1);
  }

  @override
  Future<List<AssetTypeOption>> types() async => const [
    AssetTypeOption(code: 'OAE', labelEs: 'Obra de arte especial'),
    AssetTypeOption(code: 'DEFENSA', labelEs: 'Defensa metálica'),
  ];

  @override
  Future<InventoryAsset> get(String id) async => _asset(id);

  @override
  Future<Uint8List?> mainPhoto(InventoryAsset asset) async => null;
}

class _Pending implements PendingAssetsSource {
  @override
  Future<List<InventoryAsset>> pendingAssets() async => const [
    InventoryAsset(
      id: 'cid-1',
      name: 'POSTE nuevo',
      category: 'Poste',
      typeCode: 'POSTE',
      condition: AssetCondition.unknown,
      pendingSync: true,
    ),
  ];
}

void main() {
  group('paginas', () {
    test('la primera pagina, el total del servidor y los conteos', () async {
      final server = _Server(25);
      final cubit = InventoryCubit(server);
      await cubit.load();

      final s = cubit.state;
      expect(s.status, InventoryListStatus.ready);
      expect(s.visible, hasLength(10));
      expect(s.total, 25);
      expect(s.hasMore, isTrue);
      expect(s.counts?.total, 25);
      expect(s.count(AssetCondition.good), 2);
      expect(s.count(AssetCondition.unknown), 21);
      expect(s.types.map((t) => t.code), ['OAE', 'DEFENSA']);
      // Por nombre en el idioma de la app.
      expect(s.typeOptions('es').map((t) => t.code), ['DEFENSA', 'OAE']);
      expect(server.pages.single.after, isNull);
    });

    test('cargar mas agrega hasta el final y despues no pide', () async {
      final server = _Server(25);
      final cubit = InventoryCubit(server);
      await cubit.load();

      await cubit.loadMore();
      expect(cubit.state.visible, hasLength(20));
      expect(server.pages.last.after, 10);
      await cubit.loadMore();
      expect(cubit.state.visible, hasLength(25));
      expect(cubit.state.visible.last.id, '24');
      expect(cubit.state.hasMore, isFalse);

      await cubit.loadMore();
      expect(server.pages, hasLength(3));
    });

    test('dos pedidos de la siguiente a la vez piden una sola', () async {
      final server = _Server(25);
      final cubit = InventoryCubit(server);
      await cubit.load();
      await Future.wait([cubit.loadMore(), cubit.loadMore()]);
      expect(server.pages, hasLength(2));
      expect(cubit.state.visible, hasLength(20));
    });

    test('si la siguiente falla, la lista se queda y se reintenta', () async {
      final server = _Server(25);
      final cubit = InventoryCubit(server);
      await cubit.load();

      server.fail = InventoryError.network;
      await cubit.loadMore();
      expect(cubit.state.status, InventoryListStatus.ready);
      expect(cubit.state.visible, hasLength(10));
      expect(cubit.state.moreError, InventoryError.network);
      expect(cubit.state.loadingMore, isFalse);

      server.fail = null;
      await cubit.loadMore();
      expect(cubit.state.moreError, isNull);
      expect(cubit.state.visible, hasLength(20));
    });

    test('sin red al abrir: error de red y se reintenta', () async {
      final server = _Server(5)..fail = InventoryError.network;
      final cubit = InventoryCubit(server);
      await cubit.load();
      expect(cubit.state.status, InventoryListStatus.failure);
      expect(cubit.state.error, InventoryError.network);
      expect(cubit.state.hasContent, isFalse);

      server.fail = null;
      await cubit.load();
      expect(cubit.state.status, InventoryListStatus.ready);
      expect(cubit.state.visible, hasLength(5));
    });

    test(
      'lo que espera en el telefono va arriba si cumple los filtros',
      () async {
        final cubit = InventoryCubit(
          _Server(3),
          pending: _Pending(),
          searchDelay: Duration.zero,
        );
        await cubit.load();
        expect(cubit.state.visible.first.id, 'cid-1');
        expect(cubit.state.visible, hasLength(4));
        expect(cubit.state.total, 3);

        await cubit.setType('OAE');
        expect(cubit.state.visible.map((a) => a.id), isNot(contains('cid-1')));
        await cubit.setType(null);
        await cubit.setQuery('poste');
        expect(cubit.state.visible.first.id, 'cid-1');
      },
    );
  });

  group('busqueda', () {
    test('espera a que se deje de escribir y busca una sola vez', () async {
      final server = _Server(30);
      final cubit = InventoryCubit(
        server,
        searchDelay: const Duration(milliseconds: 30),
      );
      await cubit.load();
      server.pages.clear();

      unawaited(cubit.setQuery('o'));
      unawaited(cubit.setQuery('oa'));
      expect(cubit.state.query, 'oa');
      await cubit.setQuery('oae');

      expect(server.pages, hasLength(1));
      expect(server.pages.single.query.search, 'oae');
      expect(server.pages.single.after, isNull);
      expect(cubit.state.visible.first.id, 'oae0');
      expect(cubit.state.hasMore, isTrue);
    });

    test(
      'una busqueda nueva corta la anterior y lo viejo no se muestra',
      () async {
        final server = _Server(30);
        final cubit = InventoryCubit(server, searchDelay: Duration.zero);
        await cubit.load();

        final slow = server.gate = Completer<void>();
        final first = cubit.setQuery('viejo');
        // Que la consulta salga y quede esperando.
        await Future<void>.delayed(const Duration(milliseconds: 5));
        expect(cubit.state.refreshing, isTrue);
        final firstCancellation = server.cancellations.last!;

        server.gate = null;
        await cubit.setQuery('nuevo');
        expect(firstCancellation.isCancelled, isTrue);
        expect(cubit.state.visible.first.id, 'nuevo0');

        // Lo de la busqueda vieja llega tarde y se descarta.
        slow.complete();
        await first;
        await Future<void>.delayed(Duration.zero);
        expect(cubit.state.visible.first.id, 'nuevo0');
        expect(cubit.state.query, 'nuevo');
        expect(cubit.state.refreshing, isFalse);
      },
    );

    test('cambiar los filtros cancela la pagina siguiente en camino', () async {
      final server = _Server(30);
      final cubit = InventoryCubit(server);
      await cubit.load();

      final slow = server.gate = Completer<void>();
      final more = cubit.loadMore();
      await Future<void>.delayed(Duration.zero);
      final moreCancellation = server.cancellations.last!;

      server.gate = null;
      await cubit.setCondition(AssetCondition.good);
      expect(moreCancellation.isCancelled, isTrue);
      slow.complete();
      await more;
      // Solo la primera pagina de la consulta nueva.
      expect(cubit.state.visible, hasLength(10));
      expect(cubit.state.loadingMore, isFalse);
    });
  });

  group('filtros', () {
    test('van al servidor; el estado no vuelve a contar', () async {
      final server = _Server(12);
      final cubit = InventoryCubit(server);
      await cubit.load();
      expect(server.countQueries, hasLength(1));

      await cubit.setCondition(AssetCondition.poor);
      expect(server.pages.last.query.condition, AssetCondition.poor);
      // Los conteos no dependen del estado elegido.
      expect(server.countQueries, hasLength(1));

      await cubit.setType('OAE');
      expect(server.pages.last.query.typeCode, 'OAE');
      expect(server.pages.last.query.condition, AssetCondition.poor);
      expect(server.countQueries, hasLength(2));
      expect(server.countQueries.last.typeCode, 'OAE');
      expect(server.countQueries.last.condition, isNull);

      await cubit.setInspectedFrom(DateTime.utc(2026, 11, 1));
      expect(server.pages.last.query.inspectedFrom, DateTime.utc(2026, 11, 1));

      await cubit.clearFilters();
      expect(server.pages.last.query, const InventoryQuery());
      expect(cubit.state.hasActiveFilters, isFalse);
    });

    test('si una consulta con filtros falla, los filtros siguen', () async {
      final server = _Server(12);
      final cubit = InventoryCubit(server);
      await cubit.load();

      server.fail = InventoryError.network;
      await cubit.setType('OAE');
      expect(cubit.state.status, InventoryListStatus.failure);
      expect(cubit.state.hasContent, isTrue);

      server.fail = null;
      await cubit.setType(null);
      expect(cubit.state.status, InventoryListStatus.ready);
      expect(cubit.state.visible, hasLength(10));
    });

    test('el tipo elegido siempre esta entre las opciones', () {
      const state = InventoryState(typeCode: 'BARRERA');
      expect(state.typeOptions('es').map((t) => t.code), ['BARRERA']);
    });
  });
}
