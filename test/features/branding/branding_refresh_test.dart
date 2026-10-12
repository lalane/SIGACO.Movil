import 'package:flutter_test/flutter_test.dart';
import 'package:sigaco_movil/features/branding/data/repositories/branding_repository_impl.dart';
import 'package:sigaco_movil/features/branding/domain/entities/concession_branding.dart';
import 'package:sigaco_movil/features/branding/presentation/bloc/branding_cubit.dart';

import '../../support/fakes.dart';

ConcessionBranding _v(
  int version, {
  String primary = '#0EA5E9',
  String? timezone,
  String? reduced,
}) => ConcessionBranding(
  version: version,
  primary: primary,
  timezone: timezone,
  logoReducedUrl: reduced,
);

Future<void> _settle() =>
    Future<void>.delayed(const Duration(milliseconds: 20));

/// El contrato de la marca que entrega la base (`core.fn_branding`) y su
/// refresco mientras la sesion sigue abierta (DEV-MOB-056 y 088).
void main() {
  group('contrato de la marca (core.fn_branding)', () {
    final payload = <String, dynamic>{
      'version': 3,
      'primary': '#0B3C5D',
      'secondary': '#328CC1',
      'headerStart': '#0B3C5D',
      'headerEnd': '#1D2731',
      'background': '#FFFFFF',
      'logoLightUrl': 'https://cdn.example.com/claro.png',
      'logoDarkUrl': 'https://cdn.example.com/oscuro.svg',
      'logoReducedUrl': 'https://cdn.example.com/reducido.png',
      'timezone': 'America/Sao_Paulo',
    };

    test('interpreta todos los campos, incluidos fondo, reducido y zona', () {
      final b = brandingFromJson(payload)!;
      expect(b.version, 3);
      expect(b.primary, '#0B3C5D');
      expect(b.secondary, '#328CC1');
      expect(b.headerStart, '#0B3C5D');
      expect(b.headerEnd, '#1D2731');
      expect(b.background, '#FFFFFF');
      expect(b.logoLightUrl, 'https://cdn.example.com/claro.png');
      expect(b.logoDarkUrl, 'https://cdn.example.com/oscuro.svg');
      expect(b.logoReducedUrl, 'https://cdn.example.com/reducido.png');
      expect(b.timezone, 'America/Sao_Paulo');
    });

    test('acepta la respuesta envuelta en branding', () {
      expect(
        brandingFromJson({'branding': payload})?.timezone,
        'America/Sao_Paulo',
      );
    });

    test(
      'los campos nuevos son opcionales: un contrato anterior sigue valiendo',
      () {
        final b = brandingFromJson({'version': 1, 'primary': '#0EA5E9'})!;
        expect(b.background, isNull);
        expect(b.logoReducedUrl, isNull);
        expect(b.timezone, isNull);
      },
    );

    test('ida y vuelta por el JSON guardado', () {
      final b = brandingFromJson(payload)!;
      expect(brandingFromJson(brandingToJson(b)), b);
    });

    test('lo guardado antes de estos campos se sigue leyendo', () {
      final old = <String, dynamic>{
        'version': 2,
        'primary': '#F97316',
        'secondary': null,
        'headerStart': null,
        'headerEnd': null,
        'logoLightUrl': null,
        'logoDarkUrl': null,
      };
      final b = brandingFromJson(old)!;
      expect(b.primary, '#F97316');
      expect(b.timezone, isNull);
    });

    test('un texto vacio en la zona o el logo cuenta como ausente', () {
      final b = brandingFromJson({
        'version': 1,
        'primary': '#0EA5E9',
        'timezone': '  ',
        'logoReducedUrl': '',
      })!;
      expect(b.timezone, isNull);
      expect(b.logoReducedUrl, isNull);
    });
  });

  group('zona horaria en el estado', () {
    test('una zona IANA valida llega al estado', () async {
      final cubit = BrandingCubit(
        FakeBrandingRepository({'c0': _v(1, timezone: 'America/Sao_Paulo')}),
      );
      await cubit.load('c0');
      expect(cubit.state.zone?.id, 'America/Sao_Paulo');
      await cubit.close();
    });

    test('una zona invalida o ausente deja el estado sin zona', () async {
      final cubit = BrandingCubit(
        FakeBrandingRepository({
          'c0': _v(1, timezone: 'Marte/Olympus'),
          'c1': _v(1),
        }),
      );
      await cubit.load('c0');
      expect(cubit.state.zone, isNull);
      expect(cubit.state.seed, isNotNull, reason: 'la marca sigue valiendo');
      await cubit.load('c1');
      expect(cubit.state.zone, isNull);
      await cubit.close();
    });

    test('al cambiar de concesion no queda la zona de la anterior', () async {
      final cubit = BrandingCubit(
        FakeBrandingRepository({
          'c0': _v(1, timezone: 'America/Sao_Paulo'),
          'c1': _v(1, timezone: 'America/Manaus'),
        }),
      );
      await cubit.load('c0');
      await cubit.load('c1');
      expect(cubit.state.zone?.id, 'America/Manaus');
      cubit.clear();
      expect(cubit.state.zone, isNull);
      await cubit.close();
    });
  });

  group('refresco de la marca', () {
    late FakeBrandingRepository repo;
    late DateTime now;

    BrandingCubit make({Duration gap = const Duration(minutes: 1)}) {
      return BrandingCubit(repo, minRefreshGap: gap, clock: () => now);
    }

    setUp(() {
      now = DateTime(2026, 10, 12, 10);
      repo = FakeBrandingRepository({'c0': _v(1)});
    });

    test('un cambio hecho en el portal llega sin cerrar sesion', () async {
      final cubit = make(gap: Duration.zero);
      await cubit.load('c0');
      expect(cubit.state.branding?.primary, '#0EA5E9');

      repo.brands['c0'] = _v(2, primary: '#F97316');
      await cubit.refresh();

      expect(cubit.state.branding?.version, 2);
      expect(cubit.state.branding?.primary, '#F97316');
      expect(cubit.state.seed?.primary.toARGB32(), 0xFFF97316);
      await cubit.close();
    });

    test('la marca que se ve no se vacia mientras se consulta', () async {
      final cubit = make(gap: Duration.zero);
      await cubit.load('c0');
      final seen = <int?>[];
      cubit.stream.listen((s) => seen.add(s.branding?.version));

      repo.delay = const Duration(milliseconds: 30);
      repo.brands['c0'] = _v(2);
      final pending = cubit.refresh();
      await _settle();
      expect(cubit.state.branding?.version, 1, reason: 'sigue la anterior');
      await pending;
      await _settle();

      expect(seen, [2], reason: 'solo emite el cambio, sin pasar por vacio');
      await cubit.close();
    });

    test('con la misma version no hay cambios', () async {
      final cubit = make(gap: Duration.zero);
      await cubit.load('c0');
      final seen = <BrandingState>[];
      cubit.stream.listen(seen.add);
      await cubit.refresh();
      await _settle();
      expect(seen, isEmpty);
      expect(repo.loads, ['c0', 'c0'], reason: 'si se consulto');
      await cubit.close();
    });

    test('al volver a la app no consulta antes del tiempo minimo', () async {
      final cubit = make();
      await cubit.load('c0');
      repo.loads.clear();

      now = now.add(const Duration(seconds: 30));
      await cubit.refresh();
      expect(repo.loads, isEmpty);

      now = now.add(const Duration(seconds: 31));
      await cubit.refresh();
      expect(repo.loads, ['c0']);
      await cubit.close();
    });

    test('al recuperar la conexion se consulta siempre', () async {
      final cubit = make();
      await cubit.load('c0');
      repo.loads.clear();
      repo.brands['c0'] = _v(2);

      await cubit.refresh(gap: Duration.zero);

      expect(repo.loads, ['c0']);
      expect(cubit.state.branding?.version, 2);
      await cubit.close();
    });

    test('un fallo del servidor conserva la marca que se ve', () async {
      final cubit = make(gap: Duration.zero);
      await cubit.load('c0');
      repo.failing = true;
      await cubit.refresh();
      expect(cubit.state.branding?.version, 1);
      expect(cubit.state.seed, isNotNull);
      await cubit.close();
    });

    test(
      'si la concesion ya no tiene marca vuelve a los colores de SIGACO',
      () async {
        final cubit = make(gap: Duration.zero);
        await cubit.load('c0');
        repo.brands.remove('c0');
        await cubit.refresh();
        expect(cubit.state.branding, isNull);
        expect(cubit.state.seed, isNull);
        await cubit.close();
      },
    );

    test('sin concesion activa no consulta nada', () async {
      final cubit = make(gap: Duration.zero);
      await cubit.refresh();
      expect(repo.loads, isEmpty);

      await cubit.load('c0');
      cubit.clear();
      repo.loads.clear();
      await cubit.refresh();
      expect(repo.loads, isEmpty, reason: 'tras cerrar sesion tampoco');
      await cubit.close();
    });

    test('una consulta en curso no se repite', () async {
      final cubit = make(gap: Duration.zero);
      await cubit.load('c0');
      repo.loads.clear();
      repo.delay = const Duration(milliseconds: 30);

      final a = cubit.refresh();
      final b = cubit.refresh();
      await Future.wait([a, b]);
      expect(repo.loads, ['c0']);
      await cubit.close();
    });

    test(
      'la respuesta tardia de la concesion anterior no pisa la nueva',
      () async {
        repo = FakeBrandingRepository({
          'c0': _v(1, primary: '#0EA5E9'),
          'c1': _v(1, primary: '#F97316'),
        });
        final cubit = make(gap: Duration.zero);
        await cubit.load('c0');

        repo.delay = const Duration(milliseconds: 40);
        final slow = cubit.refresh();
        repo.delay = null;
        await cubit.load('c1');
        await slow;
        await _settle();

        expect(cubit.state.branding?.primary, '#F97316');
        await cubit.close();
      },
    );
  });

  group('logo reducido en el estado', () {
    test('se prefiere solo si se pide y existe', () async {
      final cubit = BrandingCubit(
        FakeBrandingRepository({
          'c0': ConcessionBranding(
            version: 1,
            primary: '#0EA5E9',
            logoDarkUrl: 'https://cdn.example.com/oscuro.png',
            logoReducedUrl: 'https://cdn.example.com/reducido.png',
          ),
        }),
      );
      await cubit.load('c0');
      expect(
        cubit.state.logoFor(darkBackground: true),
        'https://cdn.example.com/oscuro.png',
      );
      expect(
        cubit.state.logoFor(darkBackground: true, preferReduced: true),
        'https://cdn.example.com/reducido.png',
      );
      await cubit.close();
    });
  });
}
