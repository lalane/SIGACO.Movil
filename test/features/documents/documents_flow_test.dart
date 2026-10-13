import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sigaco_movil/app/app.dart';
import 'package:sigaco_movil/app/dependencies.dart';
import 'package:sigaco_movil/core/files/picked_file.dart';
import 'package:sigaco_movil/features/documents/data/repositories/sample_documents_repository.dart';
import 'package:sigaco_movil/features/documents/domain/entities/document_access.dart';
import 'package:sigaco_movil/features/documents/domain/repositories/documents_repository.dart';
import 'package:sigaco_movil/features/navigation/domain/entities/navigation_entities.dart';

import '../../support/fakes.dart';
import '../../support/fonts.dart';
import '../../support/surface.dart';

final _now = DateTime.utc(2026, 10, 12, 12);

const _viewOnly = [DocumentAccess.viewKey];
const _viewAndUpload = [DocumentAccess.viewKey, DocumentAccess.uploadKey];

/// Vista previa y carga de documentos de punta a punta (DEV-MOB-071, 072, 073,
/// 082, 083 y 092).
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

  late SampleDocumentsRepository repo;
  late FakeSyncCubit sync;
  late FakeFileSource files;
  late MemoryFileStore store;

  Future<void> launch(
    WidgetTester tester, {
    List<String> permissions = _viewAndUpload,
    bool openModule = true,
  }) async {
    await tester.runAsync(loadAppFonts);
    useSurface(tester, TestSurface.phone);
    SharedPreferences.setMockInitialValues({});
    repo = SampleDocumentsRepository(clock: () => _now);
    sync = FakeSyncCubit();
    files = FakeFileSource();
    store = MemoryFileStore();
    final deps = AppDependencies(
      prefs: await SharedPreferences.getInstance(),
      authRepository: FakeAuthRepository(),
      credentialStore: FakeCredentialStore(supportsBiometrics: false),
      navigationRepository: FakeNavigationRepository(
        menu: NavigationMenu(
          modules: const [
            NavigationItem(code: 'DOCUMENTOS', name: 'Documentos'),
          ],
          permissions: permissions,
        ),
      ),
      brandingRepository: FakeBrandingRepository(),
      logoStore: FakeLogoStore(),
      documentsRepository: repo,
      fileSource: files,
      fileStore: store,
      accessRefreshGap: Duration.zero,
      brandingRefreshGap: Duration.zero,
      sync: sync,
    );
    await tester.pumpWidget(SigacoApp(dependencies: deps));
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText).at(0), 'a@b.com');
    await tester.enterText(find.byType(EditableText).at(1), 'S3creto!x');
    await tester.tap(find.byType(FilledButton).first);
    await tester.pumpAndSettle();
    if (openModule) {
      await tester.tap(find.text('Gestor documental'));
      await tester.pumpAndSettle();
    }
  }

  Finder tile(String id) => find.byKey(Key('doc-tile-$id'));

  Future<void> openDoc(WidgetTester tester, String id) async {
    await tester.scrollUntilVisible(
      tile(id),
      200,
      scrollable: find.descendant(
        of: find.byKey(const Key('docs-list')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.ensureVisible(tile(id));
    await tester.pumpAndSettle();
    await tester.tap(tile(id));
    await tester.pumpAndSettle();
  }

  group('vista previa (071)', () {
    testWidgets('una imagen se muestra con el visor', (tester) async {
      await launch(tester, permissions: _viewOnly);
      await openDoc(tester, 'd-004');
      await tester.tap(find.byKey(const Key('docs-detail-preview')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('docs-preview-image')), findsOneWidget);
      expect(find.text('Vista previa'), findsOneWidget);
      // Ni descarga ni abrir en otra app: no es parte del alcance movil.
      expect(find.byIcon(Icons.download), findsNothing);
      expect(find.byIcon(Icons.open_in_new), findsNothing);
    });

    testWidgets('un PDF avisa que este dispositivo aun no lo muestra', (
      tester,
    ) async {
      await launch(tester, permissions: _viewOnly);
      await openDoc(tester, 'd-001');
      await tester.tap(find.byKey(const Key('docs-detail-preview')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('docs-state-previewUnavailable')),
        findsOneWidget,
      );
      expect(
        find.text('Este dispositivo todavía no muestra documentos PDF.'),
        findsOneWidget,
      );
    });

    testWidgets('un formato sin visor no ofrece la vista previa y lo dice', (
      tester,
    ) async {
      await launch(tester, permissions: _viewOnly);
      await openDoc(tester, 'd-002');
      expect(find.byKey(const Key('docs-detail-preview')), findsNothing);
      expect(find.byKey(const Key('docs-detail-no-preview')), findsOneWidget);
      expect(
        find.text('Este formato no tiene vista previa en la app.'),
        findsOneWidget,
      );
    });

    testWidgets(
      'Ver sin Descargar basta para la ficha y la vista previa (CA-06)',
      (tester) async {
        await launch(tester, permissions: _viewOnly);
        await openDoc(tester, 'd-004');
        expect(find.byKey(const Key('docs-detail-preview')), findsOneWidget);
      },
    );

    testWidgets('sin conexion y sin copia local: pide conexion (CA-07)', (
      tester,
    ) async {
      await launch(tester, permissions: _viewOnly);
      await openDoc(tester, 'd-004');
      repo.failNextWith = DocumentsError.notAvailableOffline;
      await tester.tap(find.byKey(const Key('docs-detail-preview')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('docs-state-notAvailableOffline')),
        findsOneWidget,
      );
      expect(find.text('Contenido no disponible sin conexión'), findsOneWidget);
      // Reintentar vuelve a pedir la representacion.
      await tester.tap(find.byKey(const Key('docs-state-action')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('docs-preview-image')), findsOneWidget);
    });

    testWidgets('un error del servidor se puede reintentar', (tester) async {
      await launch(tester, permissions: _viewOnly);
      await openDoc(tester, 'd-004');
      repo.failNextWith = DocumentsError.server;
      await tester.tap(find.byKey(const Key('docs-detail-preview')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('docs-state-error')), findsOneWidget);
    });
  });

  group('boton de carga (092)', () {
    testWidgets('solo con Ver + Cargar', (tester) async {
      await launch(tester);
      expect(find.byKey(const Key('docs-upload')), findsOneWidget);
    });

    testWidgets('con solo Ver no se ofrece', (tester) async {
      await launch(tester, permissions: _viewOnly);
      expect(find.byKey(const Key('docs-upload')), findsNothing);
    });

    testWidgets('Cargar sin Ver no concede nada', (tester) async {
      await launch(
        tester,
        permissions: const [DocumentAccess.uploadKey],
        openModule: false,
      );
      // Sin Ver ni siquiera aparece la tarjeta: no habria nada que abrir.
      expect(find.text('Gestor documental'), findsNothing);
      expect(find.byKey(const Key('docs-upload')), findsNothing);
    });
  });

  group('carga de documentos (072, 073, 082, 083)', () {
    const acta = SelectedFile(
      name: 'acta.pdf',
      path: '/tmp/acta.pdf',
      sizeBytes: 2048,
    );
    const foto = SelectedFile(
      name: 'foto.jpg',
      path: '/tmp/foto.jpg',
      sizeBytes: 4096,
    );

    Future<void> openUpload(WidgetTester tester) async {
      await tester.tap(find.byKey(const Key('docs-upload')));
      await tester.pumpAndSettle();
    }

    Future<void> pick(WidgetTester tester, List<SelectedFile> list) async {
      files.files = list;
      await tester.tap(find.byKey(const Key('upload-pick')));
      await tester.pumpAndSettle();
    }

    Future<void> chooseType(WidgetTester tester, String label) async {
      await tester.ensureVisible(find.byKey(const Key('upload-type')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('upload-type')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(label).last);
      await tester.pumpAndSettle();
    }

    Future<void> save(WidgetTester tester) async {
      await tester.ensureVisible(find.byKey(const Key('upload-save')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('upload-save')));
      await tester.pumpAndSettle();
    }

    testWidgets('el formulario empieza pidiendo archivos', (tester) async {
      await launch(tester);
      await openUpload(tester);
      expect(find.byKey(const Key('upload-no-files')), findsOneWidget);
      expect(
        find.text('Elige uno o varios archivos, o toma una foto.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('upload-pick')), findsOneWidget);
      expect(find.byKey(const Key('upload-photo')), findsOneWidget);
    });

    testWidgets('el archivo elegido se muestra con su extension fija', (
      tester,
    ) async {
      await launch(tester);
      await openUpload(tester);
      await pick(tester, [acta]);
      expect(find.byKey(const Key('upload-name-0')), findsOneWidget);
      expect(find.text('acta'), findsOneWidget);
      expect(find.text('.pdf'), findsOneWidget);
      expect(find.text('2 KB'), findsOneWidget);
    });

    testWidgets(
      'guardar sin completar marca lo que falta y conserva lo escrito',
      (tester) async {
        await launch(tester);
        await openUpload(tester);
        await pick(tester, [acta]);
        await tester.enterText(
          find.byKey(const Key('upload-name-0')),
          'Acta de obra',
        );
        await save(tester);
        expect(find.text('Elige el tipo documental.'), findsOneWidget);
        expect(find.byKey(const Key('upload-done')), findsNothing);
        expect(sync.enqueued, isEmpty);
        expect(find.text('Acta de obra'), findsOneWidget);
      },
    );

    testWidgets('una extension bloqueada se marca en su archivo', (
      tester,
    ) async {
      await launch(tester);
      await openUpload(tester);
      await pick(tester, [
        const SelectedFile(name: 'virus.exe', path: '/tmp/v', sizeBytes: 10),
      ]);
      await chooseType(tester, 'Informe');
      await save(tester);
      expect(
        find.byKey(const Key('upload-issue-0-blockedExtension')),
        findsOneWidget,
      );
      expect(
        find.text('Este tipo de archivo no está permitido.'),
        findsOneWidget,
      );
      expect(sync.enqueued, isEmpty);
    });

    testWidgets('un nombre invalido se marca', (tester) async {
      await launch(tester);
      await openUpload(tester);
      await pick(tester, [acta]);
      await tester.enterText(find.byKey(const Key('upload-name-0')), 'a/b');
      await chooseType(tester, 'Informe');
      await save(tester);
      expect(
        find.byKey(const Key('upload-issue-0-nameInvalid')),
        findsOneWidget,
      );
      expect(sync.enqueued, isEmpty);
    });

    testWidgets('el tipo Otro exige una descripcion', (tester) async {
      await launch(tester);
      await openUpload(tester);
      await pick(tester, [acta]);
      await chooseType(tester, 'Otro');
      expect(
        find.text('Descripción (obligatoria para «Otro»)'),
        findsOneWidget,
      );
      await save(tester);
      expect(
        find.textContaining('Para el tipo «Otro» escribe una descripción'),
        findsOneWidget,
      );
      expect(sync.enqueued, isEmpty);

      await tester.enterText(
        find.byKey(const Key('upload-description')),
        'Croquis del acceso provisional',
      );
      await save(tester);
      expect(find.byKey(const Key('upload-done')), findsOneWidget);
      expect(sync.enqueued, hasLength(1));
    });

    testWidgets('guardar deja el documento en la cola y no lo da por cargado', (
      tester,
    ) async {
      await launch(tester);
      await openUpload(tester);
      await pick(tester, [acta, foto]);
      await tester.enterText(
        find.byKey(const Key('upload-name-1')),
        'Daño en junta',
      );
      await chooseType(tester, 'Registro o evidencia');
      await save(tester);

      expect(find.byKey(const Key('upload-done')), findsOneWidget);
      expect(find.text('Guardado en el dispositivo'), findsOneWidget);
      expect(
        find.textContaining('2 documentos pendientes de sincronización'),
        findsOneWidget,
      );
      expect(find.textContaining('No estarán en el servidor'), findsOneWidget);
      expect(find.textContaining('cargado'), findsNothing);
      expect(sync.enqueued.map((o) => o.payload['name']), [
        'acta.pdf',
        'Daño en junta.jpg',
      ]);
      expect(sync.enqueued.every((o) => o.entity == 'documento'), isTrue);
      expect(store.kept, hasLength(2));
    });

    testWidgets('el aviso explica que se guarda en el dispositivo', (
      tester,
    ) async {
      await launch(tester);
      await openUpload(tester);
      expect(
        find.textContaining('Se guarda en el dispositivo y se envía'),
        findsOneWidget,
      );
    });

    testWidgets('volver al listado lo refresca', (tester) async {
      await launch(tester);
      await openUpload(tester);
      await pick(tester, [acta]);
      await chooseType(tester, 'Informe');
      await save(tester);
      await tester.tap(find.byKey(const Key('upload-done-back')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('docs-list')), findsOneWidget);
      expect(find.byKey(const Key('upload-done')), findsNothing);
    });

    testWidgets('Ver pendientes abre el centro de sincronizacion', (
      tester,
    ) async {
      await launch(tester);
      await openUpload(tester);
      await pick(tester, [acta]);
      await chooseType(tester, 'Informe');
      await save(tester);
      await tester.tap(find.byKey(const Key('upload-done-sync')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('sync-now')), findsOneWidget);
    });

    testWidgets('se puede quitar un archivo', (tester) async {
      await launch(tester);
      await openUpload(tester);
      await pick(tester, [acta, foto]);
      await tester.tap(find.byKey(const Key('upload-remove-0')));
      await tester.pumpAndSettle();
      expect(find.text('acta'), findsNothing);
      expect(find.text('foto'), findsOneWidget);
    });

    testWidgets('la camara agrega una foto', (tester) async {
      await launch(tester);
      await openUpload(tester);
      files.photo = foto;
      await tester.tap(find.byKey(const Key('upload-photo')));
      await tester.pumpAndSettle();
      expect(find.text('foto'), findsOneWidget);
      expect(find.text('.jpg'), findsOneWidget);
    });

    testWidgets(
      'si no se puede guardar en el telefono, lo avisa y conserva el archivo',
      (tester) async {
        await launch(tester);
        await openUpload(tester);
        await pick(tester, [acta]);
        await chooseType(tester, 'Informe');
        store.failNames.add('acta.pdf');
        await save(tester);
        expect(find.byKey(const Key('upload-save-failed')), findsOneWidget);
        expect(find.byKey(const Key('upload-done')), findsNothing);
        expect(find.text('acta'), findsOneWidget);
      },
    );

    testWidgets('cancelar vuelve al listado sin guardar nada', (tester) async {
      await launch(tester);
      await openUpload(tester);
      await pick(tester, [acta]);
      await tester.ensureVisible(find.byKey(const Key('upload-cancel')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('upload-cancel')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('docs-list')), findsOneWidget);
      expect(sync.enqueued, isEmpty);
    });
  });
}
