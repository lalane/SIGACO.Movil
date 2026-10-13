// ignore_for_file: invalid_use_of_visible_for_testing_member
// Genera capturas (1080x2400) de todas las pantallas implementadas, sin
// dispositivo y con datos de ejemplo.
// Uso: fvm flutter test tool/capture_screens_test.dart
// Variables: CAPTURE_DIR (salida, por defecto ./capturas) y MATERIAL_ICONS_FONT.
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sigaco_movil/app/app.dart';
import 'package:sigaco_movil/app/dependencies.dart';
import 'package:sigaco_movil/core/connectivity/connectivity_source.dart';
import 'package:sigaco_movil/core/device/device_info_source.dart';
import 'package:sigaco_movil/core/files/file_source.dart';
import 'package:sigaco_movil/core/files/picked_file.dart';
import 'package:sigaco_movil/core/offline/operation.dart';
import 'package:sigaco_movil/core/offline/sync_cubit.dart';
import 'package:sigaco_movil/features/documents/data/repositories/sample_documents_repository.dart';
import 'package:sigaco_movil/features/documents/domain/entities/document_access.dart';
import 'package:sigaco_movil/features/documents/domain/entities/document_preview.dart';
import 'package:sigaco_movil/features/documents/domain/repositories/documents_repository.dart';
import 'package:sigaco_movil/features/auth/domain/entities/auth_entities.dart';
import 'package:sigaco_movil/features/navigation/domain/entities/navigation_entities.dart';

import '../test/support/fakes.dart';
import '../test/support/fonts.dart';

class _CaptureNetwork implements ConnectivitySource {
  final controller = StreamController<bool>.broadcast();

  @override
  Future<bool> get isConnected async => true;

  @override
  Stream<bool> get changes => controller.stream;
}

class _CaptureDevice implements DeviceInfoSource {
  @override
  Future<String> describe() async => 'Samsung SM-A155M · Android 14';
}

const _allModules = NavigationMenu(
  modules: [
    NavigationItem(code: 'PANEL', name: 'Panel'),
    NavigationItem(code: 'MANTENIMIENTO', name: 'Mantenimiento'),
    NavigationItem(code: 'INVENTARIO', name: 'Inventario'),
    NavigationItem(code: 'REPORTES', name: 'Reportes'),
    NavigationItem(code: 'TICKETS', name: 'Tickets'),
    NavigationItem(code: 'ALERTAS_OPERATIVAS', name: 'Alertas'),
    NavigationItem(
      code: 'ANTT',
      name: 'ANTT',
      submodules: [NavigationItem(code: 'ANTT.ACCIDENTES', name: 'Accidentes')],
    ),
  ],
);

const _docsMenu = NavigationMenu(
  modules: [
    NavigationItem(code: 'PANEL', name: 'Panel'),
    NavigationItem(code: 'MANTENIMIENTO', name: 'Mantenimiento'),
    NavigationItem(code: 'INVENTARIO', name: 'Inventario'),
    NavigationItem(code: 'REPORTES', name: 'Reportes'),
    NavigationItem(code: 'TICKETS', name: 'Tickets'),
    NavigationItem(code: 'ALERTAS_OPERATIVAS', name: 'Alertas'),
    NavigationItem(code: 'DOCUMENTOS', name: 'Gestor documental'),
  ],
  permissions: [
    DocumentAccess.viewKey,
    DocumentAccess.uploadKey,
    DocumentAccess.signKey,
  ],
);

final _docsNow = DateTime.utc(2026, 10, 12, 12);

/// Documentos de ejemplo con una imagen de verdad para la vista previa.
class _DocsWithImage extends SampleDocumentsRepository {
  _DocsWithImage(this.image) : super(clock: () => _docsNow);

  final Uint8List image;

  @override
  Future<DocumentPreview> preview(String id) async {
    final p = await super.preview(id);
    return p.kind == PreviewKind.image
        ? DocumentPreview(kind: PreviewKind.image, bytes: image)
        : p;
  }
}

/// Un plano de ejemplo dibujado a mano: cuadricula, trazo de vialidad y marcas.
Future<Uint8List> _drawSampleImage() async {
  const w = 900.0, h = 700.0;
  final recorder = ui.PictureRecorder();
  final c = Canvas(recorder);
  c.drawRect(
    const Rect.fromLTWH(0, 0, w, h),
    Paint()..color = const Color(0xFFEFF3F1),
  );
  final grid = Paint()
    ..color = const Color(0xFFCBD5D1)
    ..strokeWidth = 1;
  for (var x = 0.0; x <= w; x += 50) {
    c.drawLine(Offset(x, 0), Offset(x, h), grid);
  }
  for (var y = 0.0; y <= h; y += 50) {
    c.drawLine(Offset(0, y), Offset(w, y), grid);
  }
  final road = Path()
    ..moveTo(-20, 560)
    ..cubicTo(250, 520, 380, 300, 560, 260)
    ..cubicTo(700, 230, 800, 140, 940, 90);
  c.drawPath(
    road,
    Paint()
      ..color = const Color(0xFF7C8794)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 46,
  );
  c.drawPath(
    road,
    Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4,
  );
  for (final (x, y) in [(300.0, 470.0), (560.0, 260.0), (780.0, 160.0)]) {
    c.drawCircle(Offset(x, y), 26, Paint()..color = const Color(0xFFFBBF24));
    c.drawCircle(
      Offset(x, y),
      26,
      Paint()
        ..color = const Color(0xFF160F3E)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5,
    );
  }
  final image = await recorder.endRecording().toImage(w.toInt(), h.toInt());
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  return data!.buffer.asUint8List();
}

void main() {
  final outDir = Platform.environment['CAPTURE_DIR'] ?? 'capturas';
  final iconsFont = Platform.environment['MATERIAL_ICONS_FONT'];
  GlobalKey? boundary;

  Future<void> shoot(WidgetTester tester, String name) async {
    await tester.runAsync(() async {
      final render =
          boundary!.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      final image = await render.toImage(pixelRatio: 3);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      File('$outDir/$name').writeAsBytesSync(data!.buffer.asUint8List());
    });
  }

  /// Abre la app desde cero con los datos de ejemplo indicados.
  Future<void> launch(
    WidgetTester tester, {
    String appearance = 'original',
    String locale = 'es',
    FakeAuthRepository? repo,
    bool skipSplash = true,
    FakeCredentialStore? store,
    String? deepLink,
    FakeNavigationRepository? nav,
    ConnectivitySource? network,
    Stream<bool>? server,
    DocumentsRepository? documents,
    SyncCubit? sync,
    FileSource? files,
  }) async {
    // Enlace que abre la app (por ejemplo el regreso del navegador).
    if (deepLink == null) {
      tester.platformDispatcher.clearDefaultRouteNameTestValue();
    } else {
      tester.platformDispatcher.defaultRouteNameTestValue = deepLink;
    }
    SharedPreferences.setMockInitialValues({
      'appearance': appearance,
      'app_locale': locale,
    });
    PackageInfo.setMockInitialValues(
      appName: 'SIGACO',
      packageName: 'com.idare.sigaco_movil',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
    final deps = AppDependencies(
      prefs: await SharedPreferences.getInstance(),
      authRepository: repo ?? FakeAuthRepository(),
      // Por omision el aviso de biometria ya esta rechazado, para no tapar las vistas.
      credentialStore:
          store ?? (FakeCredentialStore()..declineBiometricOffer()),
      navigationRepository: nav ?? FakeNavigationRepository(menu: _allModules),
      connectivity: network ?? const AlwaysOnlineSource(),
      serverReachable: server ?? const Stream<bool>.empty(),
      deviceInfo: _CaptureDevice(),
      documentsRepository: documents,
      sync: sync,
      fileSource: files ?? const NoFileSource(),
      fileStore: MemoryFileStore(),
    );
    boundary = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: boundary,
        child: SigacoApp(dependencies: deps),
      ),
    );
    await tester.runAsync(() async {
      final ctx = tester.element(find.byType(SigacoApp));
      for (final a in ['pattern', 'tekia_white', 'tekia_dark']) {
        await precacheImage(AssetImage('assets/branding/$a.png'), ctx);
      }
    });
    if (skipSplash) {
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
    }
  }

  Future<void> signIn(WidgetTester tester) async {
    await tester.enterText(find.byType(EditableText).at(0), 'a@b.com');
    await tester.enterText(find.byType(EditableText).at(1), 'S3creto!x');
    await tester.tap(find.byType(FilledButton).first);
    await tester.pumpAndSettle();
  }

  Future<void> reset(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
  }

  setUpAll(() => Directory(outDir).createSync(recursive: true));

  testWidgets('capturas de todas las pantallas', (tester) async {
    addTearDown(tester.view.reset);
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    await tester.runAsync(() async {
      await loadAppFonts();
      if (iconsFont != null && File(iconsFont).existsSync()) {
        final bytes = File(iconsFont).readAsBytesSync();
        final loader = FontLoader('MaterialIcons')
          ..addFont(Future.value(ByteData.sublistView(bytes)));
        await loader.load();
      }
    });

    // Arranque
    await launch(tester, skipSplash: false);
    await tester.pump(const Duration(milliseconds: 300));
    await shoot(tester, '00_arranque.png');

    // Login: tres apariencias, error y portugues
    for (final (a, n) in [
      ('original', '01_login_original'),
      ('day', '02_login_dia'),
      ('night', '03_login_noche'),
    ]) {
      await reset(tester);
      await launch(tester, appearance: a);
      await shoot(tester, '$n.png');
    }
    await reset(tester);
    await launch(
      tester,
      repo: FakeAuthRepository()..failure = AuthError.invalidCredentials,
    );
    await signIn(tester);
    await shoot(tester, '04_login_error.png');
    await reset(tester);
    await launch(tester, locale: 'pt');
    await shoot(tester, '05_login_portugues.png');

    // Recuperar contrasena
    await reset(tester);
    await launch(tester);
    await tester.tap(find.text('¿Olvidaste tu contraseña?'));
    await tester.pumpAndSettle();
    await shoot(tester, '06_recuperar_contrasena.png');

    // Pasos que exige el servidor tras el login
    for (final (result, n) in [
      (outcome(mfa: true, active: 'c0'), '07_mfa_codigo'),
      (outcome(enroll: true, active: 'c0'), '08_mfa_enrolamiento'),
      (outcome(force: true, active: 'c0'), '09_cambio_obligatorio_contrasena'),
      (outcome(concessions: 2), '10_selector_concesion'),
    ]) {
      await reset(tester);
      await launch(tester, repo: FakeAuthRepository(result: result));
      await signIn(tester);
      await shoot(tester, '$n.png');
    }

    // Menu principal
    for (final (a, l, n) in [
      ('original', 'es', '11_menu_original'),
      ('day', 'es', '12_menu_dia'),
      ('night', 'es', '13_menu_noche'),
      ('original', 'pt', '14_menu_portugues'),
    ]) {
      await reset(tester);
      await launch(tester, appearance: a, locale: l);
      await signIn(tester);
      await shoot(tester, '$n.png');
    }

    // Cuenta
    for (final (a, n) in [
      ('original', '15_cuenta_original'),
      ('day', '16_cuenta_dia'),
      ('night', '17_cuenta_noche'),
    ]) {
      await reset(tester);
      await launch(tester, appearance: a);
      await signIn(tester);
      await tester.tap(find.text('JP'));
      await tester.pumpAndSettle();
      await shoot(tester, '$n.png');
    }

    // Cuenta: cambiar contrasena y cambiar de concesion
    await reset(tester);
    await launch(tester);
    await signIn(tester);
    await tester.tap(find.text('JP'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cambiar de concesión'));
    await tester.pumpAndSettle();
    await shoot(tester, '19_cuenta_cambiar_concesion.png');
    await tester.tapAt(const Offset(180, 100));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cambiar contraseña'));
    await tester.pumpAndSettle();
    await shoot(tester, '18_cuenta_cambiar_contrasena.png');

    // Aviso de sesion por vencer (a 30 s del cierre por inactividad)
    await reset(tester);
    final nearExpiry = FakeAuthRepository()
      ..activity = DateTime.now().subtract(
        const Duration(minutes: 9, seconds: 30),
      );
    await launch(tester, repo: nearExpiry);
    await signIn(tester);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    await shoot(tester, '20_sesion_por_vencer.png');

    // Aviso para activar la biometria tras el primer acceso con contrasena
    await reset(tester);
    await launch(tester, store: FakeCredentialStore());
    await signIn(tester);
    await shoot(tester, '21_oferta_biometria.png');

    // Cuenta con la biometria activada desde el aviso
    await tester.tap(find.text('Activar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('JP'));
    await tester.pumpAndSettle();
    await shoot(tester, '22_cuenta_biometria_activa.png');

    // Recuperar contrasena: enlace enviado y pasos para volver
    await reset(tester);
    await launch(tester);
    await tester.tap(find.text('¿Olvidaste tu contraseña?'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(EditableText).first,
      'jperez@example.com',
    );
    await tester.tap(find.byType(FilledButton).first);
    await tester.pumpAndSettle();
    await shoot(tester, '23_recuperar_enviado.png');

    // Regreso del navegador tras restablecer: sigaco://app/login?reset=ok
    await reset(tester);
    final remembered = FakeCredentialStore();
    await remembered.setRemembered(
      remember: true,
      credentials: (email: 'jperez@example.com', password: 'Vieja#1234'),
    );
    await launch(tester, store: remembered, deepLink: '/login?reset=ok');
    await shoot(tester, '24_regreso_restablecer.png');

    // Perfil: seguridad y preferencias (idioma, apariencia) al final de la lista
    await reset(tester);
    await launch(
      tester,
      repo: FakeAuthRepository(result: outcome(mfa: true, active: 'c0')),
    );
    await signIn(tester);
    await tester.enterText(find.byType(EditableText).first, '123456');
    await tester.tap(find.byType(FilledButton).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('JP'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).first, const Offset(0, -900));
    await tester.pumpAndSettle();
    await shoot(tester, '25_cuenta_seguridad_preferencias.png');

    // Hoja para elegir el idioma
    await tester.tap(find.text('Idioma'));
    await tester.pumpAndSettle();
    await shoot(tester, '26_cuenta_elegir_idioma.png');
    await tester.tap(find.text('Español').last);
    await tester.pumpAndSettle();

    // Volver a configurar la verificacion en dos pasos
    await tester.tap(find.text('Verificación en dos pasos'));
    await tester.pumpAndSettle();
    await shoot(tester, '27_mfa_reconfigurar.png');
    await tester.tap(find.text('Generar clave nueva'));
    await tester.pumpAndSettle();
    await shoot(tester, '28_mfa_clave_nueva.png');

    // Estados de acceso del inicio (MQ-MOB-08): sin permiso, error al validar
    // los accesos y perfil sin modulos.
    for (final (nav, n) in [
      (
        FakeNavigationRepository(failure: NavigationError.permissionDenied),
        '29_sin_permiso',
      ),
      (
        FakeNavigationRepository(failure: NavigationError.server),
        '30_error_autorizacion',
      ),
      (
        FakeNavigationRepository(menu: const NavigationMenu()),
        '31_perfil_sin_modulos',
      ),
    ]) {
      await reset(tester);
      await launch(tester, nav: nav);
      await signIn(tester);
      await shoot(tester, '$n.png');
    }

    // Sin conexion (MQ-MOB-10): aviso persistente y aviso al volver la red.
    await reset(tester);
    final network = _CaptureNetwork();
    final server = StreamController<bool>.broadcast();
    await launch(tester, network: network, server: server.stream);
    await signIn(tester);
    server.add(true);
    await tester.pump();
    network.controller.add(false);
    await tester.pumpAndSettle();
    await shoot(tester, '32_sin_conexion.png');
    network.controller.add(true);
    await tester.pump();
    await tester.pump();
    await shoot(tester, '33_conexion_restablecida.png');
    await tester.pump(const Duration(seconds: 4));

    // Cuenta con los datos del telefono y la ultima conexion.
    await tester.tap(find.text('JP'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).first, const Offset(0, -330));
    await tester.pumpAndSettle();
    await shoot(tester, '34_cuenta_dispositivo.png');
    await server.close();
    await network.controller.close();
  });
  testWidgets('capturas del gestor documental y la sincronizacion', (
    tester,
  ) async {
    addTearDown(tester.view.reset);
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    late Uint8List sample;
    await tester.runAsync(() async {
      await loadAppFonts();
      if (iconsFont != null && File(iconsFont).existsSync()) {
        final bytes = File(iconsFont).readAsBytesSync();
        final loader = FontLoader('MaterialIcons')
          ..addFont(Future.value(ByteData.sublistView(bytes)));
        await loader.load();
      }
      sample = await _drawSampleImage();
    });

    const scope = OfflineScope(userId: 'u1', concessionId: 'c0');
    final pending = SyncState(
      scope: scope,
      lastSyncAt: DateTime.utc(2026, 10, 12, 15, 30),
      items: [
        fakeOperation('a', name: 'Acta de obra.pdf'),
        fakeOperation('b', name: 'Foto puente km 87.jpg'),
        fakeOperation(
          'c',
          status: OperationStatus.rejected,
          name: 'virus.exe',
          error: 'Extensión bloqueada: .exe',
          attempts: 2,
        ),
        fakeOperation(
          'd',
          status: OperationStatus.conflict,
          entity: 'documento_firma',
          kind: OperationKind.update,
        ),
      ],
    );

    Future<void> tapKey(WidgetTester t, String key) async {
      await t.ensureVisible(find.byKey(Key(key)));
      await t.pumpAndSettle();
      await t.tap(find.byKey(Key(key)));
      await t.pumpAndSettle();
    }

    Future<void> back(WidgetTester t) async {
      await t.tap(find.byType(BackButton));
      await t.pumpAndSettle();
    }

    // Menu con el gestor documental y el aviso de lo pendiente.
    final repo = _DocsWithImage(sample);
    final sync = FakeSyncCubit(pending);
    final files = FakeFileSource(
      files: const [
        SelectedFile(
          name: 'Acta de obra.pdf',
          path: '/tmp/acta.pdf',
          sizeBytes: 2457600,
        ),
        SelectedFile(
          name: 'Foto puente km 87.jpg',
          path: '/tmp/foto.jpg',
          sizeBytes: 3145728,
        ),
      ],
    );
    await reset(tester);
    await launch(
      tester,
      nav: FakeNavigationRepository(menu: _docsMenu),
      documents: repo,
      sync: sync,
      files: files,
    );
    await signIn(tester);
    await shoot(tester, '35_menu_aviso_pendientes.png');
    await tester.ensureVisible(find.text('Gestor documental'));
    await tester.pumpAndSettle();
    await shoot(tester, '35b_menu_tarjeta_gestor_documental.png');

    // Consulta
    await tester.tap(find.text('Gestor documental'));
    await tester.pumpAndSettle();
    await shoot(tester, '36_documentos_todos.png');
    await tapKey(tester, 'docs-view-recent');
    await shoot(tester, '37_documentos_recientes.png');
    await tapKey(tester, 'docs-view-favorites');
    await shoot(tester, '38_documentos_favoritos.png');
    await tapKey(tester, 'docs-view-all');
    await tester.enterText(find.byKey(const Key('docs-search')), 'inspección');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    await shoot(tester, '39_documentos_busqueda.png');
    await tester.enterText(find.byKey(const Key('docs-search')), 'zzz');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    await shoot(tester, '40_documentos_sin_resultados.png');
    await tester.tap(find.byKey(const Key('docs-state-action')));
    await tester.pumpAndSettle();

    // Filtros
    await tapKey(tester, 'docs-filters-button');
    await tapKey(tester, 'filter-type');
    await tester.tap(find.text('Registro o evidencia').last);
    await tester.pumpAndSettle();
    await shoot(tester, '41_documentos_filtros.png');
    await tapKey(tester, 'filters-clear');

    // Ficha y vista previa
    await tester.tap(find.byKey(const Key('doc-tile-d-001')));
    await tester.pumpAndSettle();
    await shoot(tester, '42_documento_ficha.png');
    await tapKey(tester, 'docs-detail-preview');
    await shoot(tester, '43_vista_previa_pdf_pendiente.png');
    await back(tester);
    await back(tester);
    // La imagen se decodifica de forma asincrona: se precarga para la captura.
    await tester.runAsync(() async {
      await precacheImage(
        MemoryImage(sample),
        tester.element(find.byType(SigacoApp)),
      );
    });
    await tester.tap(find.byKey(const Key('doc-tile-d-004')));
    await tester.pumpAndSettle();
    await tapKey(tester, 'docs-detail-preview');
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
    await shoot(tester, '44_vista_previa_imagen.png');
    await back(tester);
    await back(tester);

    // Carga
    await tapKey(tester, 'docs-upload');
    await shoot(tester, '45_carga_vacia.png');
    await tapKey(tester, 'upload-pick');
    await shoot(tester, '46_carga_con_archivos.png');
    await tapKey(tester, 'upload-save');
    await shoot(tester, '47_carga_con_errores.png');
    await tapKey(tester, 'upload-type');
    await tester.tap(find.text('Informe').last);
    await tester.pumpAndSettle();
    await tapKey(tester, 'upload-save');
    await shoot(tester, '48_carga_guardada_en_dispositivo.png');
    await tapKey(tester, 'upload-done-back');

    // Estados
    await reset(tester);
    await launch(
      tester,
      nav: FakeNavigationRepository(
        menu: const NavigationMenu(
          modules: [
            NavigationItem(code: 'DOCUMENTOS', name: 'Gestor documental'),
          ],
          permissions: [DocumentAccess.uploadKey],
        ),
      ),
      documents: _DocsWithImage(sample),
    );
    await signIn(tester);
    await tester.ensureVisible(find.text('Gestor documental'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gestor documental'));
    await tester.pumpAndSettle();
    await shoot(tester, '49_documentos_sin_permiso.png');

    await reset(tester);
    final failing = _DocsWithImage(sample)
      ..failNextWith = DocumentsError.server;
    await launch(
      tester,
      nav: FakeNavigationRepository(menu: _docsMenu),
      documents: failing,
    );
    await signIn(tester);
    await tester.ensureVisible(find.text('Gestor documental'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gestor documental'));
    await tester.pumpAndSettle();
    // El primer fallo lo consume el catalogo; se fuerza otro para la lista.
    failing.failNextWith = DocumentsError.network;
    await tapKey(tester, 'docs-view-mine');
    await shoot(tester, '50_documentos_sin_conexion.png');

    // Centro de sincronizacion y conflicto
    await reset(tester);
    final sync2 = FakeSyncCubit(pending);
    sync2.conflicts['d'] = SyncConflict(
      operationId: 'd',
      createdAt: DateTime.utc(2026, 10, 12, 16),
      localVersion: 3,
      serverVersion: 4,
      serverPayload: const {
        'hash': 'xyz',
        'estado': 'validado',
        'nota': 'igual',
      },
      message: 'La versión ya fue firmada por otra persona',
    );
    await launch(
      tester,
      nav: FakeNavigationRepository(menu: _docsMenu),
      documents: _DocsWithImage(sample),
      sync: sync2,
    );
    await signIn(tester);
    await tester.tap(find.byKey(const Key('sync-strip')));
    await tester.pumpAndSettle();
    await shoot(tester, '51_sincronizacion_centro.png');
    await tapKey(tester, 'sync-review-d');
    await shoot(tester, '52_sincronizacion_conflicto.png');
  });
}
