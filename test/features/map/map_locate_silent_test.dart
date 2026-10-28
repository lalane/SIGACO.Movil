import 'package:flutter_test/flutter_test.dart';
import 'package:sigaco_movil/features/map/domain/entities/geo_point.dart';
import 'package:sigaco_movil/features/map/domain/entities/map_pin.dart';
import 'package:sigaco_movil/features/map/domain/repositories/location_source.dart';
import 'package:sigaco_movil/features/map/presentation/bloc/map_cubit.dart';

import '../../support/map_fakes.dart';

/// Al abrir, el mapa busca a la persona sin molestarla (APP-MOB-04): si no hay
/// ubicacion no sale ningun aviso, pero si hay, el mapa se centra en ella.
void main() {
  const here = GeoPoint(-18.85, -41.98);
  late FakeMapRepository repo;
  late FakeLocationSource location;

  MapCubit build() => MapCubit(repository: repo, locationSource: location);

  setUp(() {
    repo = FakeMapRepository(
      data: {
        MapLayer.tickets: [fakePin('t1', layer: MapLayer.tickets)],
        MapLayer.inventory: [fakePin('a1')],
      },
    );
    location = FakeLocationSource(location: fakeLocation(position: here));
  });

  test(
    'en silencio, con ubicacion, se guarda y pide centrar el mapa',
    () async {
      final cubit = build();
      await cubit.load();
      final before = cubit.state.focusTick;
      await cubit.locate(silent: true);
      expect(cubit.state.locate, LocateStatus.ready);
      expect(cubit.state.location?.position, here);
      expect(cubit.state.focusTick, before + 1);
    },
  );

  for (final failure in LocationFailure.values) {
    test('en silencio, ${failure.name} no deja ningun aviso', () async {
      location.failure = failure;
      final cubit = build();
      await cubit.load();
      await cubit.locate(silent: true);
      expect(cubit.state.locate, LocateStatus.idle);
      expect(cubit.state.location, isNull);
    });

    test('al pedirlo la persona, ${failure.name} si se informa', () async {
      location.failure = failure;
      final cubit = build();
      await cubit.load();
      await cubit.locate();
      expect(cubit.state.locate, isNot(LocateStatus.idle));
      expect(cubit.state.locate, isNot(LocateStatus.ready));
    });
  }

  test('en silencio, un fallo no borra la ultima ubicacion buena', () async {
    final cubit = build();
    await cubit.load();
    await cubit.locate();
    location.failure = LocationFailure.unavailable;
    await cubit.locate(silent: true);
    expect(cubit.state.location?.position, here);
    expect(cubit.state.locate, LocateStatus.idle);
  });
}
