import 'package:equatable/equatable.dart';

import 'inventory_asset.dart';

/// Lo que se pide al listar el catalogo. Con el servidor, la busqueda y los
/// filtros los aplica el (`GET /api/assets`); con activos de ejemplo, o con los
/// que esperan en el telefono, se aplican aqui con [matches].
class InventoryQuery extends Equatable {
  const InventoryQuery({
    this.search = '',
    this.typeCode,
    this.condition,
    this.inspectedFrom,
    this.inspectedTo,
  });

  /// En el servidor: codigo, descripcion, marca o numero de serie.
  final String search;

  /// Codigo del tipo de activo; null = todos.
  final String? typeCode;

  /// Estado de conservacion; null = todos. El servidor no sabe filtrar lo que
  /// no se evaluo: la pantalla solo ofrece [AssetCondition.assessed].
  final AssetCondition? condition;

  /// Dias de calendario (incluidos) en que se monitoreo; null = sin limite.
  final DateTime? inspectedFrom;
  final DateTime? inspectedTo;

  String get trimmedSearch => search.trim();

  /// La misma consulta sin el estado de conservacion: con ella se cuenta cuantos
  /// hay de cada estado.
  InventoryQuery withoutCondition() => condition == null
      ? this
      : InventoryQuery(
          search: search,
          typeCode: typeCode,
          inspectedFrom: inspectedFrom,
          inspectedTo: inspectedTo,
        );

  /// El activo cumple la consulta (para lo que se filtra en el telefono).
  bool matches(InventoryAsset a) {
    final type = typeCode;
    if (type != null && (a.typeCode ?? a.category) != type) return false;
    if (condition != null && a.condition != condition) return false;
    if (!_inspectedInRange(a.lastInspectionAt)) return false;
    return a.matches(search);
  }

  bool _inspectedInRange(DateTime? last) {
    final from = inspectedFrom;
    final to = inspectedTo;
    if (from == null && to == null) return true;
    if (last == null) return false;
    final day = DateTime.utc(last.year, last.month, last.day);
    if (from != null &&
        day.isBefore(DateTime.utc(from.year, from.month, from.day))) {
      return false;
    }
    return to == null || !day.isAfter(DateTime.utc(to.year, to.month, to.day));
  }

  @override
  List<Object?> get props => [
    search,
    typeCode,
    condition,
    inspectedFrom,
    inspectedTo,
  ];
}

/// Una pagina del catalogo.
class InventoryResultPage {
  const InventoryResultPage({
    required this.items,
    required this.total,
    this.next,
  });

  final List<InventoryAsset> items;

  /// Cuantos activos cumplen la consulta (no solo los de esta pagina).
  final int total;

  /// Con que pedir la pagina siguiente (lo entiende solo el repositorio que la
  /// dio); null si ya no hay mas.
  final Object? next;

  bool get hasMore => next != null;
}

/// Cuantos activos cumplen una consulta y cuantos hay en cada estado de
/// conservacion.
class InventoryCounts extends Equatable {
  const InventoryCounts({
    required this.total,
    this.good = 0,
    this.regular = 0,
    this.poor = 0,
  });

  final int total;
  final int good;
  final int regular;

  /// Malos y pesimos.
  final int poor;

  int of(AssetCondition c) => switch (c) {
    AssetCondition.good => good,
    AssetCondition.regular => regular,
    AssetCondition.poor => poor,
    AssetCondition.unknown => _unassessed < 0 ? 0 : _unassessed,
  };

  int get _unassessed => total - good - regular - poor;

  /// La parte del total que es [c], de 0 a 100.
  double share(AssetCondition c) => total <= 0 ? 0 : of(c) * 100 / total;

  @override
  List<Object?> get props => [total, good, regular, poor];
}

/// Avisa que una consulta ya no interesa (cambio la busqueda o un filtro): el
/// repositorio deja de esperarla si puede. Lo que llegue tarde, de todos modos,
/// no se muestra.
class InventoryCancellation {
  final _listeners = <void Function()>[];
  bool _cancelled = false;

  bool get isCancelled => _cancelled;

  void cancel() {
    if (_cancelled) return;
    _cancelled = true;
    final listeners = [..._listeners];
    _listeners.clear();
    for (final l in listeners) {
      l();
    }
  }

  /// [listener] corre al cancelar (o ya, si ya se cancelo).
  void whenCancelled(void Function() listener) {
    if (_cancelled) {
      listener();
    } else {
      _listeners.add(listener);
    }
  }
}
