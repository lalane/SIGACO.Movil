import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sigaco_movil/app/app.dart';
import 'package:sigaco_movil/app/dependencies.dart';
import 'package:sigaco_movil/core/branding/sigaco_wordmark.dart';
import 'package:sigaco_movil/core/theme/sigaco_palette.dart';
import 'package:sigaco_movil/features/branding/domain/entities/concession_branding.dart';

import '../../support/fakes.dart';
import '../../support/fonts.dart';
import '../../support/surface.dart';

const _blue = ConcessionBranding(
  version: 1,
  primary: '#0EA5E9',
  secondary: '#0F172A',
  headerStart: '#0B1F3A',
  headerEnd: '#07121F',
  logoLightUrl: 'https://cdn.example.com/claro.png',
  logoDarkUrl: 'https://cdn.example.com/oscuro.png',
);

const _red = ConcessionBranding(version: 1, primary: '#DC2626');

const _blueAccent = Color(0xFF0EA5E9);

/// Colores y logo de la concesion activa: solo despues de iniciar sesion, se
/// descartan al cerrar sesion o cambiar de concesion, y el usuario puede
/// volver a los colores de SIGACO.
void main() {
  setUp(
    () => PackageInfo.setMockInitialValues(
      appName: 'SIGACO',
      packageName: 'com.idare.sigaco_movil',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    ),
  );

  late FakeLogoStore logos;

  Future<(FakeBrandingRepository, FakeAuthRepository)> launch(
    WidgetTester tester, {
    required Map<String, ConcessionBranding> brands,
    FakeAuthRepository? auth,
    Map<String, Object> prefsValues = const {},
  }) async {
    await tester.runAsync(loadAppFonts);
    useSurface(tester, TestSurface.phone);
    SharedPreferences.setMockInitialValues(prefsValues);
    final brandingRepo = FakeBrandingRepository(brands);
    logos = FakeLogoStore();
    final authRepo = auth ?? FakeAuthRepository();
    final deps = AppDependencies(
      prefs: await SharedPreferences.getInstance(),
      authRepository: authRepo,
      credentialStore: FakeCredentialStore(supportsBiometrics: false),
      navigationRepository: FakeNavigationRepository(),
      brandingRepository: brandingRepo,
      logoStore: logos,
    );
    await tester.pumpWidget(SigacoApp(dependencies: deps));
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    return (brandingRepo, authRepo);
  }

  Future<void> signIn(WidgetTester tester) async {
    await tester.enterText(find.byType(EditableText).at(0), 'a@b.com');
    await tester.enterText(find.byType(EditableText).at(1), 'S3creto!x');
    await tester.tap(find.byType(FilledButton).first);
    await tester.pumpAndSettle();
  }

  SigacoPalette palette(WidgetTester tester) => Theme.of(
    tester.element(find.byType(Scaffold).first),
  ).extension<SigacoPalette>()!;

  /// Las preferencias (idioma, apariencia y colores) estan en el perfil.
  Future<void> openPreferences(WidgetTester tester) async {
    await tester.tap(find.text('JP'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Preferencias'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }

  testWidgets('antes de iniciar sesion siempre son los colores de SIGACO', (
    tester,
  ) async {
    final (repo, _) = await launch(tester, brands: {'c0': _blue});
    expect(palette(tester).accent, SigacoPalette.original.accent);
    expect(repo.loads, isEmpty);
  });

  testWidgets('al iniciar sesion se aplican los colores de la concesion', (
    tester,
  ) async {
    final (repo, _) = await launch(tester, brands: {'c0': _blue});
    await signIn(tester);

    expect(repo.loads, ['c0']);
    final p = palette(tester);
    expect(p.accent, _blueAccent);
    expect(p.gradientTop, const Color(0xFF0B1F3A));
    expect(p.navBackground, const Color(0xFF0F172A));
    // Lo derivado se recalcula para el nuevo color.
    expect(
      SigacoPalette.contrast(p.onAccent, p.accent),
      greaterThanOrEqualTo(4.5),
    );
    // Y los estatus y el error no cambian.
    expect(p.error, SigacoPalette.original.error);
  });

  testWidgets('el logo de la concesion se muestra en el inicio', (
    tester,
  ) async {
    await launch(tester, brands: {'c0': _blue});
    await signIn(tester);

    expect(find.byType(Image), findsOneWidget);
    expect(
      logos.asked.single.$1,
      'https://cdn.example.com/oscuro.png',
      reason: 'la cabecera va sobre fondo oscuro',
    );
  });

  testWidgets('el logo de la concesion va arriba de SIGACO, en la cabecera', (
    tester,
  ) async {
    await launch(tester, brands: {'c0': _blue});
    await signIn(tester);

    final logo = tester.getRect(find.byType(Image));
    final wordmark = tester.getRect(find.byType(SigacoWordmark).first);
    expect(logo.bottom, lessThanOrEqualTo(wordmark.top));
    expect(logo.left, wordmark.left, reason: 'alineado con SIGACO');
    // Es uno solo: ya no se repite en la tarjeta del saludo.
    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('sin marca propia se usan los colores de SIGACO y no hay logo', (
    tester,
  ) async {
    await launch(tester, brands: const {});
    await signIn(tester);
    expect(palette(tester).accent, SigacoPalette.original.accent);
    expect(find.byType(Image), findsNothing);

    // No hay nada que elegir: las preferencias no ofrecen el origen de los colores.
    await openPreferences(tester);
    expect(find.text('Apariencia'), findsOneWidget);
    expect(find.text('Colores de mi concesión'), findsNothing);
  });

  testWidgets('un color que no cumple las reglas se ignora', (tester) async {
    await launch(tester, brands: {'c0': _red});
    await signIn(tester);
    expect(palette(tester).accent, SigacoPalette.original.accent);
    await openPreferences(tester);
    expect(find.text('Colores de mi concesión'), findsNothing);
  });

  testWidgets('el usuario puede elegir los colores de SIGACO y se recuerda', (
    tester,
  ) async {
    await launch(tester, brands: {'c0': _blue});
    await signIn(tester);
    expect(palette(tester).accent, _blueAccent);

    await openPreferences(tester);
    expect(find.text('Colores de mi concesión'), findsOneWidget);
    // El de los colores va antes que el de datos de ejemplo, que es el ultimo.
    expect(tester.widget<Switch>(find.byType(Switch).first).value, isTrue);
    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();
    expect(palette(tester).accent, SigacoPalette.original.accent);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('color_origin'), 'sigaco');
    expect(find.text('Se usan los colores de SIGACO.'), findsOneWidget);

    await tester.tap(find.text('Colores de mi concesión'));
    await tester.pumpAndSettle();
    expect(palette(tester).accent, _blueAccent);
    expect(prefs.getString('color_origin'), 'concession');
  });

  testWidgets('lo elegido antes se respeta al iniciar sesion', (tester) async {
    await launch(
      tester,
      brands: {'c0': _blue},
      prefsValues: {'color_origin': 'sigaco'},
    );
    await signIn(tester);
    expect(palette(tester).accent, SigacoPalette.original.accent);
  });

  testWidgets('la marca tambien aplica en los temas Dia y Noche', (
    tester,
  ) async {
    await launch(
      tester,
      brands: {'c0': _blue},
      prefsValues: {'appearance': 'day'},
    );
    await signIn(tester);
    final p = palette(tester);
    expect(p.accent, _blueAccent);
    // En Dia el fondo inferior claro es del sistema, no de la concesion.
    expect(p.gradientBottom, SigacoPalette.light.gradientBottom);
    expect(p.lightBottom, isTrue);
  });

  testWidgets('al cerrar sesion vuelven los colores de SIGACO (MAR-09)', (
    tester,
  ) async {
    await launch(tester, brands: {'c0': _blue});
    await signIn(tester);
    expect(palette(tester).accent, _blueAccent);

    await tester.tap(find.text('JP'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Cerrar sesión'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Cerrar sesión'));
    await tester.pumpAndSettle();

    expect(find.text('Bienvenido'), findsOneWidget);
    expect(palette(tester).accent, SigacoPalette.original.accent);
  });

  testWidgets('al cambiar de concesion se carga la marca de la nueva', (
    tester,
  ) async {
    final (repo, _) = await launch(
      tester,
      brands: {'c0': _blue}, // c1 no tiene marca propia
      auth: FakeAuthRepository(result: outcome(concessions: 2)),
    );
    await signIn(tester);
    // Varias concesiones: primero se elige, y hasta entonces no hay marca.
    expect(find.text('Selecciona tu concesión'), findsOneWidget);
    expect(palette(tester).accent, SigacoPalette.original.accent);
    await tester.tap(find.text('Concesion 0'));
    await tester.pumpAndSettle();
    expect(repo.loads, ['c0']);
    expect(palette(tester).accent, _blueAccent);

    // Cambiar a la concesion sin marca: se descarta la anterior.
    await tester.tap(find.text('JP'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Cambiar de concesión'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Cambiar de concesión'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Concesion 1'));
    await tester.pumpAndSettle();

    expect(repo.loads, ['c0', 'c1']);
    expect(palette(tester).accent, SigacoPalette.original.accent);
    expect(find.byType(Image), findsNothing);
  });
}
