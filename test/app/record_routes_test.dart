import 'package:flutter_test/flutter_test.dart';
import 'package:sigaco_movil/app/shell/record_routes.dart';
import 'package:sigaco_movil/features/inventory/domain/entities/inventory_asset.dart';
import 'package:sigaco_movil/features/map/domain/entities/map_record_target.dart';
import 'package:sigaco_movil/features/tickets/domain/entities/ticket.dart';

/// El lugar de un ticket levantado desde el mapa viaja en la ruta: el mapa y los
/// tickets no se importan entre si.
void main() {
  final readAt = DateTime.utc(2026, 10, 19, 15, 30, 12);

  group('desde la ficha de un activo', () {
    test('viaja el activo aunque no tenga punto, con su km e indicador', () {
      final uri = Uri.parse(
        ticketNewRouteForAsset(
          const InventoryAsset(
            id: 'a-1',
            code: 'DEFENSA-000001',
            name: 'Defensa',
            category: 'Defensa metálica',
            condition: AssetCondition.good,
            kmLabel: 'KM 150+200 - 151+000',
            subsystemCode: 'SGS',
          ),
        ),
      );
      expect(uri.path, '/tickets/new');
      // Sin punto no hay ubicacion de GPS ni del mapa...
      expect(parseTicketLocation(uri.queryParameters), isNull);
      // ...pero si el activo, que da la ubicacion en el servidor.
      expect(
        parseTicketAsset(uri.queryParameters),
        const TicketAssetRef(
          id: 'a-1',
          code: 'DEFENSA-000001',
          kmLabel: 'KM 150+200',
          kmEndLabel: 'KM 151+000',
          subsystemCode: 'SGS',
        ),
      );
    });

    test('sin codigo ni km queda el id', () {
      final asset = parseTicketAsset(
        Uri.parse(
          ticketNewRouteForAsset(
            const InventoryAsset(
              id: 'a-9',
              name: 'x',
              category: 'x',
              condition: AssetCondition.unknown,
            ),
          ),
        ).queryParameters,
      )!;
      expect(asset.label, 'a-9');
      expect(asset.kmLabel, isNull);
      expect(asset.kmEndLabel, isNull);
      expect(parseTicketAsset({}), isNull);
      expect(parseTicketAsset({'asset': ' '}), isNull);
    });
  });

  test('un lugar con todo sobrevive a la ruta', () {
    final route = ticketNewRoute(
      MapRecordTarget(
        latitude: -18.854918,
        longitude: -41.983451,
        origin: MapTargetOrigin.gps,
        accuracyMeters: 12.5,
        readAt: readAt,
        assetId: 'A-002',
        kmLabel: 'KM 148+000',
      ),
    );
    final uri = Uri.parse(route);
    expect(uri.path, '/tickets/new');

    final location = parseTicketLocation(uri.queryParameters)!;
    expect(location.latitude, -18.854918);
    expect(location.longitude, -41.983451);
    expect(location.origin, TicketLocationOrigin.gps);
    expect(location.accuracyMeters, 12.5);
    expect(location.readAt, readAt);
    expect(location.assetId, 'A-002');
    expect(location.kmLabel, 'KM 148+000');
  });

  test('un punto elegido no trae precision ni activo', () {
    final uri = Uri.parse(
      ticketNewRoute(
        const MapRecordTarget(
          latitude: -18.9,
          longitude: -42.0,
          origin: MapTargetOrigin.mapPoint,
        ),
      ),
    );
    expect(uri.queryParameters.keys, containsAll(['lat', 'lon', 'src']));
    expect(uri.queryParameters.containsKey('acc'), isFalse);
    expect(uri.queryParameters.containsKey('asset'), isFalse);
    final location = parseTicketLocation(uri.queryParameters)!;
    expect(location.origin, TicketLocationOrigin.mapPoint);
    expect(location.accuracyMeters, isNull);
  });

  test('cada origen del mapa tiene su origen en el ticket', () {
    for (final o in MapTargetOrigin.values) {
      final uri = Uri.parse(
        ticketNewRoute(MapRecordTarget(latitude: 1, longitude: 1, origin: o)),
      );
      expect(parseTicketLocation(uri.queryParameters)!.origin.name, o.name);
    }
  });

  test('un kilometro con signos y espacios no se rompe', () {
    final uri = Uri.parse(
      ticketNewRoute(
        const MapRecordTarget(
          latitude: 1,
          longitude: 1,
          origin: MapTargetOrigin.asset,
          kmLabel: 'KM 150+200 & más',
        ),
      ),
    );
    expect(
      parseTicketLocation(uri.queryParameters)!.kmLabel,
      'KM 150+200 & más',
    );
  });

  test('sin parametros, o invalidos, el formulario se abre sin ubicacion', () {
    expect(parseTicketLocation({}), isNull);
    expect(parseTicketLocation({'lat': '1'}), isNull);
    expect(parseTicketLocation({'lat': 'x', 'lon': '1', 'src': 'gps'}), isNull);
    expect(
      parseTicketLocation({'lat': '95', 'lon': '1', 'src': 'gps'}),
      isNull,
    );
    expect(
      parseTicketLocation({'lat': '1', 'lon': '200', 'src': 'gps'}),
      isNull,
    );
    // Un origen desconocido no se adivina.
    expect(
      parseTicketLocation({'lat': '1', 'lon': '1', 'src': 'satelite'}),
      isNull,
    );
    expect(parseTicketLocation({'lat': '1', 'lon': '1'}), isNull);
  });

  test('una precision o fecha rotas se ignoran sin tumbar el lugar', () {
    final location = parseTicketLocation({
      'lat': '1',
      'lon': '2',
      'src': 'gps',
      'acc': 'mucha',
      'at': 'ayer',
    })!;
    expect(location.accuracyMeters, isNull);
    expect(location.readAt, isNull);
  });
}
