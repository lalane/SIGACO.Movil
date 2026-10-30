import 'package:flutter_test/flutter_test.dart';
import 'package:sigaco_movil/features/map/data/repositories/api_road_segments_repository.dart';
import 'package:sigaco_movil/features/map/domain/entities/road_segment.dart';
import 'package:sigaco_movil/features/map/domain/repositories/map_repository.dart';

import '../../support/fake_api.dart';

Map<String, Object?> _segment(
  String id,
  String direction,
  Object? geometry, {
  String code = '381BMG0170',
}) => {
  'id': id,
  'roadCode': 'BR-381',
  'code': code,
  'name': 'Trecho de prueba',
  'direction': direction,
  'kmStart': 155.9,
  'kmEnd': 195.1,
  'provisional': true,
  'geometry': geometry,
};

void main() {
  late FakeApi api;
  late ApiRoadSegmentsRepository repo;

  setUp(() {
    api = FakeApi();
    repo = ApiRoadSegmentsRepository(api.client());
  });

  test('cada linea del trazo es un tramo dibujable con el mismo id', () async {
    api.on(
      'GET /api/road-network/segments/map',
      FakeReply(200, [
        _segment('a', 'CRECIENTE', {
          'type': 'MultiLineString',
          'coordinates': [
            [
              [-42.04, -18.92],
              [-42.05, -18.93],
            ],
            [
              [-42.06, -18.94],
              [-42.07, -18.95],
              [-42.08, -18.96],
            ],
          ],
        }),
        _segment('b', 'DECRECIENTE', {
          'type': 'LineString',
          'coordinates': [
            [-42.04, -18.921],
            [-42.05, -18.931],
          ],
        }),
        _segment('c', 'CRECIENTE', null, code: 'SIN-TRAZO'),
        _segment('d', 'AMBOS', {
          'type': 'LineString',
          'coordinates': [
            [-42.04, -18.92],
            [-42.05, -18.93],
          ],
        }),
      ]),
    );

    final segments = await repo.segments();

    expect(segments.map((s) => s.id), ['a', 'a', 'b']);
    expect(segments.every((s) => s.isDrawable), isTrue);
    final first = segments.first;
    expect(first.direction, TravelDirection.increasing);
    expect(first.points.first.latitude, -18.92);
    expect(first.points.first.longitude, -42.04);
    expect(first.startKmLabel, 'KM 155+900');
    expect(first.endKmLabel, 'KM 195+100');
    expect(segments[1].points, hasLength(3));
    expect(segments.last.direction, TravelDirection.decreasing);
  });

  test('los fallos del servidor se vuelven errores del mapa', () async {
    api.on('GET /api/road-network/segments/map', const FakeReply(403, {}));
    await expectLater(
      repo.segments(),
      throwsA(
        isA<MapException>().having(
          (e) => e.error,
          'error',
          MapError.permissionDenied,
        ),
      ),
    );
  });
}
