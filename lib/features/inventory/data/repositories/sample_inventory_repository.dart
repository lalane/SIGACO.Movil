import 'dart:typed_data';

import '../../domain/entities/inventory_asset.dart';
import '../../domain/repositories/inventory_repository.dart';
import 'in_memory_inventory.dart';

/// Activos de ejemplo para ver el modulo mientras el backend no publica los
/// suyos. Tienen el mismo id, tramo, kilometro y posicion que los pines de
/// inventario del mapa de ejemplo, asi que "Ver en mapa" cae sobre el pin. No
/// son activos reales. Se filtran y paginan en el telefono. Su historia
/// operativa (tickets, inspecciones y mantenimientos) tambien es de ejemplo;
/// los que el mapa de ejemplo pinta "en mantenimiento" tienen un ticket
/// abierto.
class SampleInventoryRepository
    with InMemoryInventory
    implements AssetHistorySource {
  SampleInventoryRepository({
    DateTime Function()? clock,
    this.delay = Duration.zero,
  }) : _clock = clock ?? DateTime.now;

  /// Para simular la espera de la red en pruebas de interfaz.
  final Duration delay;
  final DateTime Function() _clock;

  List<InventoryAsset>? _assets;

  // id, nombre, tipo, estado, kilometro, tramo, sentido, latitud, longitud.
  static const _rows =
      <
        (
          String,
          String,
          String,
          AssetCondition,
          String,
          String,
          String,
          double,
          double,
        )
      >[
        (
          'A-001',
          'Defensa metálica',
          'Defensa metálica',
          AssetCondition.good,
          'KM 147+200',
          '381BMG0160',
          'Creciente',
          -18.847666,
          -41.983488,
        ),
        (
          'A-002',
          'Señal vertical SV-114',
          'Señal vertical',
          AssetCondition.good,
          'KM 148+000',
          '381BMG0160',
          'Decreciente',
          -18.854918,
          -41.983451,
        ),
        (
          'A-003',
          'Barrera New Jersey',
          'Barrera',
          AssetCondition.regular,
          'KM 149+400',
          '381BMG0160',
          'Creciente',
          -18.865647,
          -41.989895,
        ),
        (
          'A-004',
          'Descida d\'água DA-22',
          'Drenaje',
          AssetCondition.regular,
          'KM 150+200',
          '381BMG0160',
          'Creciente',
          -18.872509,
          -41.992129,
        ),
        (
          'A-005',
          'Poste de iluminación P-310',
          'Iluminación',
          AssetCondition.poor,
          'KM 150+350',
          '381BMG0160',
          'Decreciente',
          -18.8739,
          -41.992485,
        ),
        (
          'A-006',
          'OAE puente sobre arroyo',
          'OAE',
          AssetCondition.good,
          'KM 152+100',
          '381BMG0170',
          'Creciente',
          -18.886491,
          -42.000578,
        ),
        (
          'A-007',
          'Señal vertical SV-131',
          'Señal vertical',
          AssetCondition.regular,
          'KM 153+600',
          '381BMG0170',
          'Creciente',
          -18.896842,
          -42.004428,
        ),
        (
          'A-008',
          'Defensa metálica',
          'Defensa metálica',
          AssetCondition.poor,
          'KM 155+400',
          '381BMG0170',
          'Decreciente',
          -18.91159,
          -42.008042,
        ),
        (
          'A-009',
          'Defensa metálica',
          'Defensa metálica',
          AssetCondition.good,
          'KM 156+800',
          '381BMG0180',
          'Creciente',
          -18.921434,
          -42.016384,
        ),
        (
          'A-010',
          'Señal vertical SV-152',
          'Señal vertical',
          AssetCondition.good,
          'KM 157+900',
          '381BMG0180',
          'Decreciente',
          -18.922766,
          -42.024741,
        ),
        (
          'A-011',
          'Poste de iluminación P-420',
          'Iluminación',
          AssetCondition.regular,
          'KM 160+100',
          '381BMG0190',
          'Creciente',
          -18.929349,
          -42.044025,
        ),
        (
          'A-012',
          'Alcantarilla AL-07',
          'Drenaje',
          AssetCondition.good,
          'KM 163+200',
          '381BMG0200',
          'Decreciente',
          -18.946381,
          -42.067027,
        ),
      ];

  /// Los que el mapa de ejemplo pinta "en mantenimiento": un ticket abierto.
  static const _inMaintenance = {'A-004', 'A-008'};

  /// Los conteos de ejemplo de la historia del activo [i].
  static AssetHistoryCounts _counts(int i, String id) => AssetHistoryCounts(
    tickets: _inMaintenance.contains(id)
        ? const AssetHistoryCount(open: 1, total: 2)
        : AssetHistoryCount(open: 0, total: i % 3),
    inspections: AssetHistoryCount(open: i % 4 == 0 ? 1 : 0, total: 1 + i % 3),
    maintenances: AssetHistoryCount(open: i % 5 == 0 ? 1 : 0, total: i % 4),
  );

  List<InventoryAsset> _load() {
    final cached = _assets;
    if (cached != null) return cached;
    final now = _clock().toUtc();
    final today = DateTime.utc(now.year, now.month, now.day);
    return _assets = [
      for (var i = 0; i < _rows.length; i++)
        InventoryAsset(
          inMaintenance: _inMaintenance.contains(_rows[i].$1),
          openTicketCount: _inMaintenance.contains(_rows[i].$1) ? 1 : 0,
          history: _counts(i, _rows[i].$1),
          id: _rows[i].$1,
          name: _rows[i].$2,
          category: _rows[i].$3,
          condition: _rows[i].$4,
          kmLabel: _rows[i].$5,
          segmentCode: _rows[i].$6,
          direction: _rows[i].$7,
          latitude: _rows[i].$8,
          longitude: _rows[i].$9,
          installedAt: DateTime.utc(2019 + i % 4, 1 + (i * 3) % 12, 10),
          // Algunos se inspeccionaron esta semana y otros hace meses, para
          // probar el filtro por fecha.
          lastInspectionAt: today.subtract(Duration(days: 3 + i * 17)),
          notes: _rows[i].$4 == AssetCondition.good
              ? null
              : 'Requiere seguimiento en la próxima inspección.',
        ),
    ];
  }

  @override
  Future<List<InventoryAsset>> allAssets() async {
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    return [..._load()];
  }

  @override
  Future<InventoryAsset> get(String id) async {
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    for (final a in _load()) {
      if (a.id == id) return a;
    }
    throw const InventoryException(InventoryError.notFound);
  }

  /// Los activos de ejemplo no tienen foto.
  @override
  Future<Uint8List?> mainPhoto(InventoryAsset asset) async => null;

  /// Registros de ejemplo que cuadran con los conteos del activo: primero los
  /// abiertos y despues los cerrados, uno cada pocas semanas hacia atras.
  @override
  Future<AssetHistoryPage> history(
    String assetId,
    AssetHistoryKind kind, {
    int limit = 5,
  }) async {
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    final index = _load().indexWhere((a) => a.id == assetId);
    if (index < 0) throw const InventoryException(InventoryError.notFound);
    final count = _load()[index].history?.of(kind);
    if (count == null) {
      throw const InventoryException(InventoryError.permissionDenied);
    }
    final now = _clock().toUtc();
    final shown = count.total < limit ? count.total : limit;
    final (prefix, open, closed, titles) = switch (kind) {
      AssetHistoryKind.tickets => (
        'TK',
        'EN_PROCESO',
        'CERRADO',
        const ['Daño en el elemento', 'Limpieza requerida'],
      ),
      AssetHistoryKind.inspections => (
        'IN',
        'ASIGNADA',
        'CERRADA',
        const ['Inspección de rutina', 'Inspección anual'],
      ),
      AssetHistoryKind.maintenances => (
        'MP',
        'PROGRAMADO',
        'COMPLETADO',
        const ['Limpieza y pintura', 'Sustitución de piezas'],
      ),
    };
    return AssetHistoryPage(
      total: count.total,
      items: [
        for (var k = 0; k < shown; k++)
          AssetHistoryEntry(
            id: '$assetId-${kind.name}-$k',
            kind: kind,
            folio:
                '$prefix-${now.year}-${(index * 10 + k + 1).toString().padLeft(6, '0')}',
            status: k < count.open ? open : closed,
            title: titles[k % titles.length],
            date: now.subtract(Duration(days: 3 + k * 21)),
            dateOnly: kind == AssetHistoryKind.maintenances,
            responsible: 'Equipo de campo',
            overdue: kind == AssetHistoryKind.tickets && k < count.open,
          ),
      ],
    );
  }
}
