import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sigaco_movil/app/app.dart';
import 'package:sigaco_movil/app/dependencies.dart';
import 'package:sigaco_movil/core/responsive/responsive.dart';
import 'package:sigaco_movil/features/navigation/domain/entities/navigation_entities.dart';

import '../support/fakes.dart';
import '../support/fonts.dart';
import '../support/surface.dart';

const _allModules = NavigationMenu(
  modules: [
    NavigationItem(code: 'PANEL', name: 'Panel'),
    NavigationItem(code: 'MANTENIMIENTO', name: 'Mantenimiento'),
    NavigationItem(code: 'INVENTARIO', name: 'Catálogo'),
    NavigationItem(code: 'REPORTES', name: 'Reportes'),
    NavigationItem(code: 'TICKETS', name: 'Registros'),
    NavigationItem(code: 'ALERTAS_OPERATIVAS', name: 'Alertas'),
    NavigationItem(
      code: 'ANTT',
      name: 'ANTT',
      submodules: [NavigationItem(code: 'ANTT.ACCIDENTES', name: 'Accidentes')],
    ),
  ],
);

/// Abre la app con datos de ejemplo y deja la pantalla de login lista.
Future<void> _launch(
  WidgetTester tester, {
  FakeAuthRepository? repo,
  String locale = 'es',
}) async {
  await tester.runAsync(loadAppFonts);
  SharedPreferences.setMockInitialValues({'app_locale': locale});
  PackageInfo.setMockInitialValues(
    appName: 'SIGACO',
    packageName: 'com.idare.sigaco_movil',
    version: '1.0.0',
    buildNumber: '1',
    buildSignature: '',
  );
  // Con biometria disponible (el login muestra su boton) pero ya rechazada, para
  // que el aviso de activarla no tape el resto del recorrido.
  final store = FakeCredentialStore(supportsBiometrics: true);
  await store.declineBiometricOffer();
  final deps = AppDependencies(
    prefs: await SharedPreferences.getInstance(),
    authRepository: repo ?? FakeAuthRepository(),
    credentialStore: store,
    navigationRepository: FakeNavigationRepository(menu: _allModules),
  );
  await tester.pumpWidget(SigacoApp(dependencies: deps));
  await tester.pump(const Duration(seconds: 2));
  await tester.pumpAndSettle();
}

Future<void> _signIn(WidgetTester tester) async {
  await tester.enterText(find.byType(EditableText).at(0), 'a@b.com');
  await tester.enterText(find.byType(EditableText).at(1), 'S3creto!x');
  await _tapPrimary(tester);
}

/// Pulsa el boton principal, desplazando la pantalla si hace falta (en un
/// telefono horizontal el formulario no cabe completo).
Future<void> _tapPrimary(WidgetTester tester) async {
  await tester.ensureVisible(find.byType(FilledButton).first);
  await tester.pumpAndSettle();
  await tester.tap(find.byType(FilledButton).first);
  await tester.pumpAndSettle();
}

/// Falla con el detalle del widget que desbordo, no solo con el mensaje.
void _noErrors(WidgetTester tester, String where) {
  final e = tester.takeException();
  if (e != null) {
    fail('$where: ${e is FlutterError ? e.toStringDeep() : e}');
  }
}

void main() {
  setUp(() => TestWidgetsFlutterBinding.ensureInitialized());

  group('clases de tamano', () {
    test('se calculan por el ancho de la ventana', () {
      expect(WindowSize.fromWidth(320), WindowSize.compact);
      expect(WindowSize.fromWidth(599.9), WindowSize.compact);
      expect(WindowSize.fromWidth(600), WindowSize.medium);
      expect(WindowSize.fromWidth(839.9), WindowSize.medium);
      expect(WindowSize.fromWidth(840), WindowSize.expanded);
      expect(WindowSize.fromWidth(1280), WindowSize.expanded);
    });

    test('compacta conserva las medidas del mockup desde 360 dp', () {
      expect(Responsive.forWidth(360).scale, 1.0);
      expect(Responsive.forWidth(392).scale, 1.0);
      expect(Responsive.forWidth(412).scale, 1.0);
      // Por debajo de 360 dp se reduce en proporcion, con un piso.
      expect(Responsive.forWidth(320).scale, closeTo(320 / 360, 0.001));
      expect(Responsive.forWidth(200).scale, 0.88);
    });

    test('media y expandida crecen en proporcion', () {
      expect(Responsive.forWidth(720).scale, 1.15);
      expect(Responsive.forWidth(1280).scale, 1.3);
      expect(Responsive.forWidth(720).s(20), closeTo(23, 0.001));
    });

    test('columnas y navegacion por clase', () {
      final c = Responsive.forWidth(360);
      final m = Responsive.forWidth(720);
      final e = Responsive.forWidth(1280);
      expect([c.moduleColumns, m.moduleColumns, e.moduleColumns], [2, 3, 4]);
      expect([c.useRail, m.useRail, e.useRail], [false, true, true]);
    });

    test('el contenido se centra con un ancho maximo', () {
      final e = Responsive.forWidth(1280);
      final pad = e.sidePadding(minGutter: 24);
      expect(pad.left, (1280 - Responsive.formMaxWidth) / 2);
      // En un telefono el margen minimo manda.
      final c = Responsive.forWidth(360);
      expect(c.sidePadding(minGutter: 24).left, 24);
    });
  });

  group('estructura por clase', () {
    testWidgets('compacta: barra inferior y 2 columnas', (tester) async {
      useSurface(tester, TestSurface.phone);
      await _launch(tester);
      await _signIn(tester);
      expect(find.byKey(const Key('home-bottom-bar')), findsOneWidget);
      expect(find.byKey(const Key('home-rail')), findsNothing);
      final grid = tester.widget<GridView>(find.byType(GridView));
      final d = grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(d.crossAxisCount, 2);
    });

    testWidgets('media: riel lateral y 3 columnas', (tester) async {
      useSurface(tester, TestSurface.medium, pixelRatio: 2);
      await _launch(tester);
      await _signIn(tester);
      expect(find.byKey(const Key('home-bottom-bar')), findsNothing);
      expect(find.byKey(const Key('home-rail')), findsOneWidget);
      final grid = tester.widget<GridView>(find.byType(GridView));
      final d = grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(d.crossAxisCount, 3);
    });

    testWidgets('expandida: riel lateral y 4 columnas', (tester) async {
      useSurface(tester, TestSurface.expanded, pixelRatio: 2);
      await _launch(tester);
      await _signIn(tester);
      expect(find.byKey(const Key('home-rail')), findsOneWidget);
      final grid = tester.widget<GridView>(find.byType(GridView));
      final d = grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(d.crossAxisCount, 4);
    });

    testWidgets('el login es de dos paneles solo en expandida', (tester) async {
      useSurface(tester, TestSurface.phone);
      await _launch(tester);
      expect(find.byKey(const Key('login-brand-panel')), findsNothing);

      await tester.pumpWidget(const SizedBox());
      useSurface(tester, TestSurface.expanded, pixelRatio: 2);
      await _launch(tester);
      expect(find.byKey(const Key('login-brand-panel')), findsOneWidget);
    });

    testWidgets('el contenido no se estira mas del ancho maximo', (
      tester,
    ) async {
      useSurface(tester, TestSurface.medium, pixelRatio: 2);
      await _launch(tester);
      final card = tester.getSize(find.byType(FilledButton).first);
      expect(card.width, lessThanOrEqualTo(Responsive.formMaxWidth));
    });

    testWidgets('los componentes crecen en la misma proporcion', (
      tester,
    ) async {
      // El boton primario mide 50 dp en el mockup (360 dp de ancho).
      useSurface(tester, TestSurface.phone);
      await _launch(tester);
      final phone = tester.getSize(find.byType(FilledButton).first).height;
      expect(phone, closeTo(50, 0.5));

      await tester.pumpWidget(const SizedBox());
      useSurface(tester, TestSurface.medium, pixelRatio: 2);
      await _launch(tester);
      final medium = tester.getSize(find.byType(FilledButton).first).height;
      expect(medium / phone, closeTo(1.15, 0.05));

      await tester.pumpWidget(const SizedBox());
      useSurface(tester, TestSurface.expanded, pixelRatio: 2);
      await _launch(tester);
      final expanded = tester.getSize(find.byType(FilledButton).first).height;
      expect(expanded / phone, closeTo(1.3, 0.05));
    });
  });

  // Matriz de pruebas: ninguna pantalla debe desbordar en ningun tamano ni con
  // el texto del sistema agrandado.
  final sizes = <String, (Size, double)>{
    'telefono pequeno 320x640': (TestSurface.smallPhone, 3),
    'telefono 360x800': (TestSurface.phone, 3),
    'telefono grande 412x915': (TestSurface.largePhone, 3),
    'telefono horizontal 800x360': (const Size(800, 360), 3),
    'plegable/tableta vertical 720x1024': (TestSurface.medium, 2),
    'tableta horizontal 1280x800': (TestSurface.expanded, 2),
    'tableta horizontal 1024x768': (const Size(1024, 768), 2),
  };

  for (final MapEntry(key: name, value: (size, ratio)) in sizes.entries) {
    for (final scale in [1.0, 1.3, 2.0]) {
      testWidgets('sin desbordes: $name, texto x$scale', (tester) async {
        await tester.runAsync(loadAppFonts);
        useSurface(tester, size, textScale: scale, pixelRatio: ratio);

        // Login: vista inicial y validacion de campos vacios.
        await _launch(tester);
        _noErrors(tester, 'login');
        await _tapPrimary(tester);
        _noErrors(tester, 'login con errores');

        // Recuperar contrasena: formulario y pasos tras pedir el enlace.
        await tester.ensureVisible(find.text('¿Olvidaste tu contraseña?'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('¿Olvidaste tu contraseña?'));
        await tester.pumpAndSettle();
        // Con poca altura y texto grande el campo queda bajo el titulo.
        await tester.scrollUntilVisible(
          find.byType(EditableText),
          100,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.enterText(find.byType(EditableText).first, 'a@b.com');
        await _tapPrimary(tester);
        await tester.scrollUntilVisible(
          find.text('Qué hacer ahora'),
          100,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text('Qué hacer ahora'), findsOneWidget);
        _noErrors(tester, 'recuperacion');
        await tester.ensureVisible(find.text('Volver a iniciar sesión'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Volver a iniciar sesión'));
        await tester.pumpAndSettle();

        // Menu principal con todos los modulos.
        await _signIn(tester);
        expect(find.text('Juan Perez'), findsOneWidget);
        // Se recorre la lista para construir todas las tarjetas de modulos.
        await tester.drag(find.byType(ListView).first, const Offset(0, -3000));
        await tester.pumpAndSettle();
        expect(find.text('Accidentes'), findsOneWidget);
        _noErrors(tester, 'menu');

        // Cuenta.
        await tester.tap(find.text('JP'));
        await tester.pumpAndSettle();
        expect(find.text('Información de la cuenta'), findsOneWidget);
        _noErrors(tester, 'cuenta');

        // Selector de concesion (pantalla de un paso).
        await tester.pumpWidget(const SizedBox());
        await _launch(
          tester,
          repo: FakeAuthRepository(result: outcome(concessions: 2)),
        );
        await _signIn(tester);
        expect(find.text('Selecciona tu concesión'), findsOneWidget);
        _noErrors(tester, 'selector');
      });
    }
  }
}
