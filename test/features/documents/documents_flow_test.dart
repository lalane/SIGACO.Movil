import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sigaco_movil/app/app.dart';
import 'package:sigaco_movil/app/dependencies.dart';
import 'package:sigaco_movil/app/feature_flags.dart';
import 'package:sigaco_movil/core/connectivity/connectivity_source.dart';
import 'package:sigaco_movil/core/files/picked_file.dart';
import 'package:sigaco_movil/core/offline/operation.dart';
import 'package:sigaco_movil/core/offline/sync_cubit.dart';
import 'package:sigaco_movil/core/session/session_scope.dart';
import 'package:sigaco_movil/core/time/concession_zone.dart';
import 'package:sigaco_movil/core/time/concession_zone_source.dart';
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
const _viewAndSign = [DocumentAccess.viewKey, DocumentAccess.signKey];

/// Una red que se puede apagar: sin ella, firmar deja la firma pendiente.
class _Network implements ConnectivitySource {
  _Network({this.online = true});

  final bool online;

  @override
  Future<bool> get isConnected async => online;

  @override
  Stream<bool> get changes => const Stream.empty();
}

/// La zona que el servidor dice para la concesion (nula si no la sabe).
class _Zones implements ConcessionZoneSource {
  _Zones(this.zone);

  final ConcessionZone? zone;
  final loaded = <String>[];

  @override
  Future<ConcessionZone?> load(String concessionId) async {
    loaded.add(concessionId);
    return zone;
  }
}

/// Un cache de sesion que anota a quien se le fijo el alcance.
class _RecordingScope implements ScopeBound {
  final events = <String>[];

  @override
  Future<void> bind(OfflineScope? scope) async =>
      events.add('bind:${scope?.userId}/${scope?.concessionId}');

  @override
  Future<void> clear() async => events.add('clear');
}

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
  late FakePdfRenderer pdf;

  Future<void> launch(
    WidgetTester tester, {
    List<String> permissions = _viewAndUpload,
    bool openModule = true,
    FakePdfRenderer? pdfRenderer,
    bool online = true,
    SessionScope? scope,
    ConcessionZoneSource? zones,
  }) async {
    await tester.runAsync(loadAppFonts);
    useSurface(tester, TestSurface.phone);
    SharedPreferences.setMockInitialValues({});
    repo = SampleDocumentsRepository(clock: () => _now);
    sync = FakeSyncCubit(
      const SyncState(
        scope: OfflineScope(userId: 'u1', concessionId: 'c0'),
      ),
    );
    files = FakeFileSource();
    store = MemoryFileStore();
    pdf = pdfRenderer ?? FakePdfRenderer();
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
      features: const FeatureFlags(documents: true),
      documentsRepository: repo,
      fileSource: files,
      pdfRenderer: pdf,
      fileStore: store,
      connectivity: _Network(online: online),
      sessionScope: scope,
      zoneSource: zones ?? const NoConcessionZoneSource(),
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

    testWidgets('un PDF se muestra por paginas con el visor', (tester) async {
      await launch(tester, permissions: _viewOnly);
      await openDoc(tester, 'd-001');
      await tester.tap(find.byKey(const Key('docs-detail-preview')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('docs-preview-pdf')), findsOneWidget);
      expect(find.byKey(const Key('docs-pdf-page-1')), findsOneWidget);
      expect(find.text('Página 1 de 3'), findsWidgets);
      expect(pdf.opened, 1);
    });

    testWidgets('si el PDF no se puede abrir, lo dice sin inventar nada', (
      tester,
    ) async {
      await launch(
        tester,
        permissions: _viewOnly,
        pdfRenderer: FakePdfRenderer(failOpen: true),
      );
      await openDoc(tester, 'd-001');
      await tester.tap(find.byKey(const Key('docs-detail-preview')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('docs-state-previewUnavailable')),
        findsOneWidget,
      );
      expect(find.text('No se pudo mostrar el PDF.'), findsOneWidget);
    });

    testWidgets('al salir de la vista previa se libera el PDF', (tester) async {
      await launch(tester, permissions: _viewOnly);
      await openDoc(tester, 'd-001');
      await tester.tap(find.byKey(const Key('docs-detail-preview')));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(pdf.closed, 1);
    });

    testWidgets('acercar vuelve a dibujar las paginas mas anchas', (
      tester,
    ) async {
      await launch(tester, permissions: _viewOnly);
      await openDoc(tester, 'd-001');
      await tester.tap(find.byKey(const Key('docs-detail-preview')));
      await tester.pumpAndSettle();
      final before = pdf.rendered
          .map((r) => r.$2)
          .reduce((a, b) => a > b ? a : b);
      await tester.tap(find.byKey(const Key('docs-pdf-zoom-in')));
      await tester.pumpAndSettle();
      final after = pdf.rendered
          .map((r) => r.$2)
          .reduce((a, b) => a > b ? a : b);
      expect(after, greaterThan(before));
      // Alejar hasta el minimo deja el boton sin efecto.
      await tester.tap(find.byKey(const Key('docs-pdf-zoom-out')));
      await tester.pumpAndSettle();
      final out = tester.widget<IconButton>(
        find.byKey(const Key('docs-pdf-zoom-out')),
      );
      expect(out.onPressed, isNull);
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

  group('firma (074, 075, 084)', () {
    Future<void> openSignable(
      WidgetTester tester, {
      List<String> permissions = _viewAndSign,
      String id = 'd-006',
      bool online = true,
    }) async {
      await launch(tester, permissions: permissions, online: online);
      await openDoc(tester, id);
    }

    final signButton = find.byKey(const Key('docs-detail-sign'));

    Future<void> confirm(WidgetTester tester) async {
      await tester.ensureVisible(signButton);
      await tester.tap(signButton);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('docs-sign-confirm')));
      await tester.pumpAndSettle();
    }

    testWidgets('con Ver y Firmar, un documento sin firma se puede firmar', (
      tester,
    ) async {
      await openSignable(tester);
      expect(signButton, findsOneWidget);
      expect(find.text('Sin firma'), findsOneWidget);

      await confirm(tester);

      expect(find.text('Validado'), findsOneWidget);
      expect(find.text('Documento firmado.'), findsOneWidget);
      expect(signButton, findsNothing);
      expect(sync.enqueued, isEmpty);
    });

    testWidgets('pide confirmacion con el nombre y la version', (tester) async {
      await openSignable(tester);
      await tester.ensureVisible(signButton);
      await tester.tap(signButton);
      await tester.pumpAndSettle();

      expect(find.text('¿Firmar este documento?'), findsOneWidget);
      expect(
        find.textContaining('Licencia ambiental tramo sur.pdf'),
        findsWidgets,
      );
      expect(find.textContaining('V1'), findsWidgets);
      // Con conexion no se habla de dejarla pendiente.
      expect(find.textContaining('Sin conexión:'), findsNothing);
    });

    testWidgets('cancelar no firma nada', (tester) async {
      await openSignable(tester);
      await tester.ensureVisible(signButton);
      await tester.tap(signButton);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('docs-sign-cancel')));
      await tester.pumpAndSettle();

      expect(find.text('Sin firma'), findsOneWidget);
      expect(signButton, findsOneWidget);
      expect(sync.enqueued, isEmpty);
    });

    testWidgets('sin el permiso Firmar no se ofrece', (tester) async {
      await openSignable(tester, permissions: _viewOnly);

      expect(signButton, findsNothing);
    });

    testWidgets('con Firmar pero sin Ver no hay nada que firmar', (
      tester,
    ) async {
      await launch(
        tester,
        permissions: const [DocumentAccess.signKey],
        openModule: false,
      );

      // La tarjeta del gestor no aparece sin Ver.
      expect(find.text('Gestor documental'), findsNothing);
    });

    testWidgets('un documento ya validado no se ofrece', (tester) async {
      await openSignable(tester, id: 'd-001');

      expect(find.text('Validado'), findsOneWidget);
      expect(signButton, findsNothing);
    });

    testWidgets('sin conexion queda pendiente y no se presenta como firmada', (
      tester,
    ) async {
      await openSignable(tester, online: false);
      await tester.ensureVisible(signButton);
      await tester.tap(signButton);
      await tester.pumpAndSettle();
      expect(find.textContaining('Sin conexión:'), findsOneWidget);

      await tester.tap(find.byKey(const Key('docs-sign-confirm')));
      await tester.pumpAndSettle();

      expect(sync.enqueued.single.entity, 'documento_firma');
      expect(
        find.text('Firma guardada. Se aplicará al sincronizar.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('docs-detail-sign-pending')), findsOneWidget);
      expect(find.text('Firma pendiente de sincronizar'), findsOneWidget);
      expect(find.text('Sin firma'), findsOneWidget);
      expect(signButton, findsNothing);
    });

    testWidgets('si la firma pendiente pide decision, lo dice', (tester) async {
      await openSignable(tester, online: false);
      await confirm(tester);

      final op = sync.enqueued.single;
      sync.show(
        sync.state.copyWith(
          items: [
            fakeOperation(
              op.id,
              entity: 'documento_firma',
              status: OperationStatus.conflict,
              recordId: 'd-006',
              baseVersion: 1,
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(
          'La firma pendiente necesita tu decisión en el centro de sincronización.',
        ),
        findsOneWidget,
      );
      expect(signButton, findsNothing);
    });

    testWidgets('al aplicarse la firma pendiente, la ficha se actualiza', (
      tester,
    ) async {
      await openSignable(tester, online: false);
      await confirm(tester);
      expect(find.text('Sin firma'), findsOneWidget);

      // El sincronizador la envio y el servidor la acepto: ya no esta en la cola.
      await repo.sign('d-006', '');
      sync.show(sync.state.copyWith(items: const []));
      await tester.pumpAndSettle();

      expect(find.text('Validado'), findsOneWidget);
      expect(find.byKey(const Key('docs-detail-sign-pending')), findsNothing);
    });

    testWidgets('si otra persona la firmo antes, se avisa y se actualiza', (
      tester,
    ) async {
      await openSignable(tester);
      // Entre abrir la ficha y firmar, otra persona la firmo.
      await repo.sign('d-006', '');

      await confirm(tester);

      expect(
        find.text('Esta versión ya fue firmada por otra persona.'),
        findsOneWidget,
      );
      expect(find.text('Validado'), findsOneWidget);
      expect(signButton, findsNothing);
    });
  });

  group('zona horaria de la concesion (057, RN-04)', () {
    testWidgets('sin zona de la marca, se usa la que dice el servidor', (
      tester,
    ) async {
      final zones = _Zones(ConcessionZone.tryParse('America/Sao_Paulo'));
      await launch(tester, zones: zones);

      expect(zones.loaded, ['c0']);
      expect(find.byKey(const Key('docs-zone-legend')), findsOneWidget);
      expect(find.textContaining('America/Sao_Paulo'), findsOneWidget);
    });

    testWidgets('si el servidor no la sabe, no se inventa una', (tester) async {
      await launch(tester, zones: _Zones(null));

      expect(find.byKey(const Key('docs-zone-legend')), findsNothing);
    });
  });

  group('lo guardado es de una persona y una concesion (RN-CTX-02)', () {
    testWidgets('al iniciar sesion se fija el alcance en los caches', (
      tester,
    ) async {
      final scope = _RecordingScope();
      await launch(tester, scope: SessionScope()..register(scope));

      expect(scope.events, contains(startsWith('bind:')));
      expect(scope.events.where((e) => e.startsWith('bind:null')), isEmpty);
    });
  });
}
