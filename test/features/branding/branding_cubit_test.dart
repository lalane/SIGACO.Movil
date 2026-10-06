import 'package:flutter_test/flutter_test.dart';
import 'package:sigaco_movil/features/branding/domain/entities/concession_branding.dart';
import 'package:sigaco_movil/features/branding/presentation/bloc/branding_cubit.dart';

import '../../support/fakes.dart';

const _blue = ConcessionBranding(
  version: 1,
  primary: '#0EA5E9',
  headerStart: '#0B1F3A',
  logoLightUrl: 'https://cdn.example.com/claro.png',
  logoDarkUrl: 'https://cdn.example.com/oscuro.png',
);

const _orange = ConcessionBranding(version: 1, primary: '#F97316');

const _red = ConcessionBranding(
  version: 1,
  primary: '#DC2626',
  logoLightUrl: 'https://cdn.example.com/rojo.png',
);

Future<void> _settle() =>
    Future<void>.delayed(const Duration(milliseconds: 30));

void main() {
  test('sin marca de la concesion no hay colores ni logo', () async {
    final cubit = BrandingCubit(FakeBrandingRepository());
    await cubit.load('c0');
    expect(cubit.state.seed, isNull);
    expect(cubit.state.branding, isNull);
    expect(cubit.state.hasBrand, isFalse);
    await cubit.close();
  });

  test('una marca valida entrega colores y logos', () async {
    final cubit = BrandingCubit(FakeBrandingRepository({'c0': _blue}));
    await cubit.load('c0');
    expect(cubit.state.seed?.primary.toARGB32(), 0xFF0EA5E9);
    expect(cubit.state.seed?.headerStart?.toARGB32(), 0xFF0B1F3A);
    expect(cubit.state.logoFor(darkBackground: true), contains('oscuro'));
    expect(cubit.state.logoFor(darkBackground: false), contains('claro'));
    expect(cubit.state.hasBrand, isTrue);
    await cubit.close();
  });

  test('el logo cae al otro si falta la variante pedida', () async {
    final cubit = BrandingCubit(
      FakeBrandingRepository({
        'c0': const ConcessionBranding(
          version: 1,
          primary: '#0EA5E9',
          logoLightUrl: 'https://cdn.example.com/solo-claro.png',
        ),
      }),
    );
    await cubit.load('c0');
    expect(cubit.state.logoFor(darkBackground: true), contains('solo-claro'));
    await cubit.close();
  });

  test('un color rechazado vuelve a SIGACO pero conserva el logo', () async {
    final cubit = BrandingCubit(FakeBrandingRepository({'c0': _red}));
    await cubit.load('c0');
    expect(cubit.state.seed, isNull);
    expect(cubit.state.logoFor(darkBackground: false), contains('rojo'));
    await cubit.close();
  });

  test('un color de accion ilegible no es una marca', () async {
    final cubit = BrandingCubit(
      FakeBrandingRepository({
        'c0': const ConcessionBranding(version: 1, primary: 'rojo'),
      }),
    );
    await cubit.load('c0');
    expect(cubit.state.seed, isNull);
    await cubit.close();
  });

  test('solo se aceptan logos por https (o http en desarrollo)', () async {
    for (final url in [
      'javascript:alert(1)',
      'file:///sdcard/logo.png',
      'ftp://cdn.example.com/logo.png',
      '/relativo/logo.png',
      'https://',
    ]) {
      final cubit = BrandingCubit(
        FakeBrandingRepository({
          'c0': ConcessionBranding(
            version: 1,
            primary: '#0EA5E9',
            logoDarkUrl: url,
          ),
        }),
      );
      await cubit.load('c0');
      expect(cubit.state.logoFor(darkBackground: true), isNull, reason: url);
      await cubit.close();
    }
  });

  test(
    'al cambiar de concesion se descarta la marca anterior (MAR-09)',
    () async {
      final repo = FakeBrandingRepository({'c0': _blue})
        ..delay = const Duration(milliseconds: 10);
      final cubit = BrandingCubit(repo);
      await cubit.load('c0');
      expect(cubit.state.seed, isNotNull);

      final states = <BrandingState>[];
      final sub = cubit.stream.listen(states.add);
      await cubit.load('c1'); // sin marca
      await _settle();
      expect(states.first.seed, isNull, reason: 'se vacia antes de cargar');
      expect(cubit.state.seed, isNull);
      await sub.cancel();
      await cubit.close();
    },
  );

  test('una respuesta tardia de la concesion anterior se ignora', () async {
    final repo = FakeBrandingRepository({'c0': _blue, 'c1': _orange})
      ..delay = const Duration(milliseconds: 40);
    final cubit = BrandingCubit(repo);

    final first = cubit.load('c0');
    await Future<void>.delayed(const Duration(milliseconds: 5));
    repo.delay = const Duration(milliseconds: 5);
    await cubit.load('c1');
    await first;
    await _settle();

    expect(cubit.state.seed?.primary.toARGB32(), 0xFFF97316);
    await cubit.close();
  });

  test('al cerrar sesion se vacia y no vuelve una carga pendiente', () async {
    final repo = FakeBrandingRepository({'c0': _blue})
      ..delay = const Duration(milliseconds: 30);
    final cubit = BrandingCubit(repo);
    final pending = cubit.load('c0');
    cubit.clear();
    await pending;
    await _settle();
    expect(cubit.state.seed, isNull);
    expect(cubit.state.hasBrand, isFalse);
    await cubit.close();
  });

  test('un fallo del repositorio deja los colores de SIGACO', () async {
    final cubit = BrandingCubit(_Failing());
    await cubit.load('c0');
    expect(cubit.state.seed, isNull);
    await cubit.close();
  });
}

class _Failing extends FakeBrandingRepository {
  @override
  Future<ConcessionBranding?> load(String concessionId) =>
      Future.error(StateError('sin servicio'));
}
