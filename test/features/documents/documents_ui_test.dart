import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sigaco_movil/app/app.dart';
import 'package:sigaco_movil/app/dependencies.dart';
import 'package:sigaco_movil/core/settings/settings_cubit.dart';
import 'package:sigaco_movil/core/theme/app_theme.dart';
import 'package:sigaco_movil/features/branding/domain/entities/concession_branding.dart';
import 'package:sigaco_movil/features/documents/data/repositories/sample_documents_repository.dart';
import 'package:sigaco_movil/features/documents/domain/entities/document.dart';
import 'package:sigaco_movil/features/documents/domain/entities/document_access.dart';
import 'package:sigaco_movil/features/documents/domain/entities/document_catalogs.dart';
import 'package:sigaco_movil/features/documents/domain/entities/document_preview.dart';
import 'package:sigaco_movil/features/documents/domain/entities/document_query.dart';
import 'package:sigaco_movil/features/documents/domain/repositories/documents_repository.dart';
import 'package:sigaco_movil/features/documents/presentation/bloc/documents_cubit.dart';
import 'package:sigaco_movil/features/documents/presentation/pages/documents_page.dart';
import 'package:sigaco_movil/features/documents/presentation/widgets/document_filters_sheet.dart';
import 'package:sigaco_movil/features/documents/presentation/widgets/document_state_view.dart';
import 'package:sigaco_movil/features/navigation/domain/entities/navigation_entities.dart';
import 'package:sigaco_movil/l10n/app_localizations.dart';

import '../../support/fakes.dart';
import '../../support/fonts.dart';
import '../../support/surface.dart';

final _now = DateTime.utc(2026, 10, 12, 12);

NavigationMenu _menu({
  bool module = true,
  List<String> permissions = const [DocumentAccess.viewKey],
}) => NavigationMenu(
  modules: [
    const NavigationItem(code: 'PANEL', name: 'Panel'),
    if (module) const NavigationItem(code: 'DOCUMENTOS', name: 'Documentos'),
  ],
  permissions: permissions,
);

/// Gestor documental de punta a punta con documentos de ejemplo: la tarjeta del
/// menu, las cuatro vistas, la busqueda, los filtros, la ficha y los estados
/// (DEV-MOB-068 a 070, 077, 078, 091 y 092).
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

  Future<SampleDocumentsRepository> launch(
    WidgetTester tester, {
    NavigationMenu? menu,
    DocumentsRepository? repo,
    Map<String, ConcessionBranding> brands = const {},
  }) async {
    await tester.runAsync(loadAppFonts);
    useSurface(tester, TestSurface.phone);
    SharedPreferences.setMockInitialValues({});
    final sample = SampleDocumentsRepository(clock: () => _now);
    final deps = AppDependencies(
      prefs: await SharedPreferences.getInstance(),
      authRepository: FakeAuthRepository(),
      credentialStore: FakeCredentialStore(supportsBiometrics: false),
      navigationRepository: FakeNavigationRepository(menu: menu ?? _menu()),
      brandingRepository: FakeBrandingRepository(brands),
      logoStore: FakeLogoStore(),
      documentsRepository: repo ?? sample,
      accessRefreshGap: Duration.zero,
      brandingRefreshGap: Duration.zero,
    );
    await tester.pumpWidget(SigacoApp(dependencies: deps));
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText).at(0), 'a@b.com');
    await tester.enterText(find.byType(EditableText).at(1), 'S3creto!x');
    await tester.tap(find.byType(FilledButton).first);
    await tester.pumpAndSettle();
    return sample;
  }

  Future<void> openModule(WidgetTester tester) async {
    await tester.tap(find.text('Gestor documental'));
    await tester.pumpAndSettle();
  }

  Finder tile(String id) => find.byKey(Key('doc-tile-$id'));

  /// Elige una vista; en un telefono la fila de vistas se desplaza.
  Future<void> pickView(WidgetTester tester, String name) async {
    final chip = find.byKey(Key('docs-view-$name'));
    await tester.ensureVisible(chip);
    await tester.pumpAndSettle();
    await tester.tap(chip);
    await tester.pumpAndSettle();
  }

  /// Abre la ficha de un documento, bajando por la lista si hace falta.
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

  group('tarjeta del menu (091)', () {
    testWidgets('aparece cuando el menu trae el modulo', (tester) async {
      await launch(tester);
      expect(find.text('Gestor documental'), findsOneWidget);
      expect(find.text('Consulta y firma de documentos'), findsOneWidget);
    });

    testWidgets('no aparece si el menu no lo trae', (tester) async {
      await launch(tester, menu: _menu(module: false));
      expect(find.text('Gestor documental'), findsNothing);
    });

    testWidgets('abre la consulta de documentos', (tester) async {
      await launch(tester);
      await openModule(tester);
      expect(find.byKey(const Key('docs-search')), findsOneWidget);
      expect(find.byKey(const Key('docs-list')), findsOneWidget);
      expect(tile('d-004'), findsOneWidget);
    });
  });

  group('vistas (068)', () {
    testWidgets('las cuatro vistas estan y Todos es la de inicio', (
      tester,
    ) async {
      await launch(tester);
      await openModule(tester);
      for (final label in [
        'Todos',
        'Recientes',
        'Favoritos',
        'Mis documentos',
      ]) {
        expect(find.widgetWithText(ChoiceChip, label), findsOneWidget);
      }
      final all = tester.widget<ChoiceChip>(
        find.byKey(const Key('docs-view-all')),
      );
      expect(all.selected, isTrue);
    });

    testWidgets('Favoritos muestra solo los marcados', (tester) async {
      await launch(tester);
      await openModule(tester);
      await pickView(tester, 'favorites');
      expect(tile('d-001'), findsOneWidget);
      expect(tile('d-003'), findsOneWidget);
      expect(tile('d-008'), findsOneWidget);
      expect(tile('d-004'), findsNothing);
    });

    testWidgets('Mis documentos muestra solo los del usuario', (tester) async {
      await launch(tester);
      await openModule(tester);
      await pickView(tester, 'mine');
      expect(tile('d-004'), findsOneWidget);
      expect(tile('d-002'), findsNothing);
    });

    testWidgets('Recientes empieza por lo ultimo que hizo el usuario', (
      tester,
    ) async {
      await launch(tester);
      await openModule(tester);
      await pickView(tester, 'recent');
      expect(tile('d-004'), findsOneWidget);
      expect(tile('d-006'), findsNothing);
      expect(
        tester.getTopLeft(tile('d-004')).dy,
        lessThan(tester.getTopLeft(tile('d-001')).dy),
      );
    });

    testWidgets('cada fila muestra tipo, categoria, propietario y firma', (
      tester,
    ) async {
      await launch(tester);
      await openModule(tester);
      expect(find.text('Foto puente km 87.jpg'), findsOneWidget);
      expect(find.text('Registro o evidencia · Mantenimiento'), findsWidgets);
      expect(find.textContaining('amartinez ·'), findsWidgets);
      expect(find.text('Sin firma'), findsWidgets);
      expect(find.text('Validado'), findsWidgets);
    });

    testWidgets('el favorito se marca desde la fila sin abrir la ficha', (
      tester,
    ) async {
      final repo = await launch(tester);
      await openModule(tester);
      await tester.tap(find.byKey(const Key('doc-fav-d-004')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('docs-detail')), findsNothing);
      final favorites = await repo.list(
        const DocumentQuery(view: DocumentView.favorites),
      );
      expect(favorites.map((d) => d.id), contains('d-004'));
    });
  });

  group('busqueda y filtros (069)', () {
    testWidgets('buscar combina con la vista y se puede limpiar', (
      tester,
    ) async {
      await launch(tester);
      await openModule(tester);
      await tester.enterText(
        find.byKey(const Key('docs-search')),
        'inspección',
      );
      // La busqueda espera a que se deje de escribir.
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      expect(tile('d-001'), findsOneWidget);
      expect(tile('d-004'), findsNothing);

      await tester.enterText(find.byKey(const Key('docs-search')), 'zzz');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('docs-state-noResults')), findsOneWidget);
      expect(find.text('Sin resultados'), findsOneWidget);

      await tester.tap(find.byKey(const Key('docs-state-action')));
      await tester.pumpAndSettle();
      expect(tile('d-004'), findsOneWidget);
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('docs-search')))
            .controller!
            .text,
        isEmpty,
      );
    });

    testWidgets('el filtro por tipo se aplica y se cuenta', (tester) async {
      await launch(tester);
      await openModule(tester);
      await tester.tap(find.byKey(const Key('docs-filters-button')));
      await tester.pumpAndSettle();
      expect(find.text('Filtros'), findsOneWidget);
      await tester.tap(find.byKey(const Key('filter-type')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Registro o evidencia').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('filters-apply')));
      await tester.pumpAndSettle();

      expect(tile('d-004'), findsOneWidget);
      expect(tile('d-012'), findsOneWidget);
      expect(tile('d-001'), findsNothing);
      expect(find.text('1'), findsOneWidget); // el aviso de un filtro activo
    });

    testWidgets('limpiar filtros desde la hoja los quita', (tester) async {
      await launch(tester);
      await openModule(tester);
      await tester.tap(find.byKey(const Key('docs-filters-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('filter-type')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Registro o evidencia').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('filters-apply')));
      await tester.pumpAndSettle();
      expect(tile('d-001'), findsNothing);

      await tester.tap(find.byKey(const Key('docs-filters-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('filters-clear')));
      await tester.pumpAndSettle();
      expect(tile('d-001'), findsOneWidget);
    });
  });

  group('ficha (070)', () {
    testWidgets('muestra metadatos y la version vigente, sin historial', (
      tester,
    ) async {
      await launch(tester);
      await openModule(tester);
      await openDoc(tester, 'd-001');

      expect(find.byKey(const Key('docs-detail-name')), findsOneWidget);
      expect(find.text('Informe de inspección km 120-140.pdf'), findsOneWidget);
      expect(find.text('Informe'), findsOneWidget);
      expect(find.text('Mantenimiento'), findsOneWidget);
      expect(find.text('Mantenimiento/Inspecciones'), findsOneWidget);
      expect(
        find.text('Resultados de la inspección de pavimento del tramo.'),
        findsOneWidget,
      );
      expect(find.text('V3'), findsOneWidget);
      expect(find.text('Validado'), findsOneWidget);
      expect(
        find.textContaining('historial', findRichText: true),
        findsNothing,
      );
    });

    testWidgets('un documento sin categoria ni carpeta lo dice', (
      tester,
    ) async {
      await launch(tester);
      await openModule(tester);
      await openDoc(tester, 'd-007');
      expect(find.text('Sin categoría'), findsOneWidget);
      expect(find.text('Nivel inicial de la concesión'), findsOneWidget);
    });

    testWidgets('la fecha se muestra en la zona de la concesion', (
      tester,
    ) async {
      await launch(
        tester,
        brands: const {
          'c0': ConcessionBranding(
            version: 1,
            primary: '#0EA5E9',
            timezone: 'America/Sao_Paulo',
          ),
        },
      );
      await openModule(tester);
      // d-004 se modifico a las 10:00 UTC: 07:00 en Brasilia.
      await openDoc(tester, 'd-004');
      expect(find.textContaining('7:00'), findsOneWidget);
      expect(find.textContaining('10:00'), findsNothing);
    });

    testWidgets('el favorito de la ficha se refleja al volver a la lista', (
      tester,
    ) async {
      await launch(tester);
      await openModule(tester);
      await openDoc(tester, 'd-002');
      await tester.tap(find.byKey(const Key('docs-detail-favorite')));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await pickView(tester, 'favorites');
      expect(tile('d-002'), findsOneWidget);
    });

    testWidgets('abrir la ficha cuenta como actividad reciente', (
      tester,
    ) async {
      await launch(tester);
      await openModule(tester);
      await openDoc(tester, 'd-009');
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await pickView(tester, 'recent');
      expect(tile('d-009'), findsOneWidget);
    });

    testWidgets('cambiar de vista empieza arriba, no donde estaba la lista', (
      tester,
    ) async {
      await launch(tester);
      await openModule(tester);
      await tester.scrollUntilVisible(
        tile('d-011'),
        200,
        scrollable: find.descendant(
          of: find.byKey(const Key('docs-list')),
          matching: find.byType(Scrollable),
        ),
      );
      expect(tile('d-004'), findsNothing);
      await pickView(tester, 'mine');
      expect(tile('d-004'), findsOneWidget);
    });
  });

  group('estados de pantalla (078)', () {
    testWidgets('sin el permiso Ver no aparece la tarjeta (092)', (
      tester,
    ) async {
      final repo = _Counting();
      await launch(
        tester,
        menu: _menu(permissions: const [DocumentAccess.uploadKey]),
        repo: repo,
      );
      expect(find.text('Gestor documental'), findsNothing);
      expect(repo.calls, 0);
    });

    testWidgets('la pantalla tampoco consulta nada sin Ver, aunque se abra', (
      tester,
    ) async {
      await tester.runAsync(loadAppFonts);
      useSurface(tester, TestSurface.phone);
      final repo = _Counting();
      await tester.pumpWidget(
        _Host(
          child: BlocProvider(
            create: (_) => DocumentsCubit(repo),
            child: const DocumentsPage(access: DocumentAccess.none),
          ),
        ),
      );
      await tester.pump();
      expect(find.byKey(const Key('docs-state-noPermission')), findsOneWidget);
      expect(find.text('Sin permiso para ver documentos'), findsOneWidget);
      expect(find.byKey(const Key('docs-search')), findsNothing);
      expect(repo.calls, 0);
    });

    testWidgets('error del servidor: mensaje y reintentar', (tester) async {
      final repo = await launch(tester);
      await openModule(tester);
      repo.failNextWith = DocumentsError.server;
      await pickView(tester, 'mine');
      expect(find.byKey(const Key('docs-state-error')), findsOneWidget);
      expect(find.text('No se pudieron cargar los documentos'), findsOneWidget);
      await tester.tap(find.byKey(const Key('docs-state-action')));
      await tester.pumpAndSettle();
      expect(tile('d-004'), findsOneWidget);
    });

    testWidgets('sin conexion: aviso y reintentar', (tester) async {
      final repo = await launch(tester);
      await openModule(tester);
      repo.failNextWith = DocumentsError.network;
      await pickView(tester, 'favorites');
      expect(find.byKey(const Key('docs-state-offline')), findsOneWidget);
      expect(find.text('Sin conexión'), findsWidgets);
    });

    testWidgets('el servidor niega Ver: sin permiso', (tester) async {
      final repo = await launch(tester);
      await openModule(tester);
      repo.failNextWith = DocumentsError.permissionDenied;
      await pickView(tester, 'mine');
      expect(find.byKey(const Key('docs-state-noPermission')), findsOneWidget);
    });

    testWidgets('mientras no hay documentos favoritos, lo explica', (
      tester,
    ) async {
      final repo = await launch(tester);
      for (final d in await repo.list(
        const DocumentQuery(view: DocumentView.favorites),
      )) {
        await repo.setFavorite(d.id, favorite: false);
      }
      await openModule(tester);
      await pickView(tester, 'favorites');
      expect(find.byKey(const Key('docs-state-empty')), findsOneWidget);
      expect(find.text('Sin favoritos'), findsOneWidget);
    });

    testWidgets('una ficha que ya no existe lo dice', (tester) async {
      final repo = await launch(tester);
      await openModule(tester);
      repo.failNextWith = DocumentsError.notFound;
      await openDoc(tester, 'd-004');
      expect(find.byKey(const Key('docs-state-notFound')), findsOneWidget);
    });

    testWidgets('el repositorio sin backend ofrece reintentar', (tester) async {
      await launch(tester, repo: _Counting(fail: DocumentsError.server));
      await openModule(tester);
      expect(find.byKey(const Key('docs-state-error')), findsOneWidget);
    });

    for (final (state, text) in [
      (DocumentScreenState.loading, null),
      (DocumentScreenState.empty, 'Aún no hay documentos'),
      (DocumentScreenState.noResults, 'Sin resultados'),
      (DocumentScreenState.error, 'No se pudieron cargar los documentos'),
      (DocumentScreenState.offline, 'Sin conexión'),
      (DocumentScreenState.noPermission, 'Sin permiso para ver documentos'),
      (DocumentScreenState.noRoadAccess, 'Sin carreteras asignadas'),
      (DocumentScreenState.notFound, 'El documento ya no está disponible'),
      (
        DocumentScreenState.notAvailableOffline,
        'Contenido no disponible sin conexión',
      ),
    ]) {
      testWidgets('el estado ${state.name} existe', (tester) async {
        await tester.runAsync(loadAppFonts);
        useSurface(tester, TestSurface.phone);
        await tester.pumpWidget(_Host(child: DocumentStateView(state: state)));
        await tester.pump();
        expect(find.byKey(Key('docs-state-${state.name}')), findsOneWidget);
        if (text != null) expect(find.text(text), findsOneWidget);
      });
    }
  });

  group('hoja de filtros', () {
    testWidgets('Desde posterior a Hasta: error y no se puede aplicar', (
      tester,
    ) async {
      await tester.runAsync(loadAppFonts);
      useSurface(tester, TestSurface.phone);
      DocumentFilters? result;
      await tester.pumpWidget(
        _Host(
          child: Builder(
            builder: (context) => TextButton(
              onPressed: () async => result = await showDocumentFilters(
                context,
                current: DocumentFilters(
                  from: DateTime.utc(2026, 10, 5),
                  to: DateTime.utc(2026, 10, 1),
                ),
                catalogs: const DocumentCatalogs(
                  types: [CatalogEntry('TD01', 'Plano')],
                ),
              ),
              child: const Text('abrir'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('filter-range-error')), findsOneWidget);
      expect(
        find.text('La fecha Desde no puede ser posterior a Hasta.'),
        findsOneWidget,
      );
      final apply = tester.widget<FilledButton>(
        find.byKey(const Key('filters-apply')),
      );
      expect(apply.onPressed, isNull);
      expect(result, isNull);
    });

    testWidgets('un rango valido se aplica tal cual', (tester) async {
      await tester.runAsync(loadAppFonts);
      useSurface(tester, TestSurface.phone);
      DocumentFilters? result;
      final from = DateTime.utc(2026, 10, 1);
      final to = DateTime.utc(2026, 10, 5);
      await tester.pumpWidget(
        _Host(
          child: Builder(
            builder: (context) => TextButton(
              onPressed: () async => result = await showDocumentFilters(
                context,
                current: DocumentFilters(from: from, to: to),
                catalogs: const DocumentCatalogs(),
              ),
              child: const Text('abrir'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('filter-range-error')), findsNothing);
      await tester.tap(find.byKey(const Key('filters-apply')));
      await tester.pumpAndSettle();
      expect(result, DocumentFilters(from: from, to: to));
    });
  });
}

/// Un repositorio que cuenta las consultas y puede fallar siempre.
class _Counting implements DocumentsRepository {
  _Counting({this.fail});

  final DocumentsError? fail;
  int calls = 0;

  @override
  Future<List<DocumentSummary>> list(DocumentQuery query) async {
    calls++;
    if (fail != null) throw DocumentsException(fail!);
    return const [];
  }

  @override
  Future<DocumentDetail> detail(String id) async {
    calls++;
    throw const DocumentsException(DocumentsError.notFound);
  }

  @override
  Future<DocumentPreview> preview(String id) async {
    calls++;
    throw const DocumentsException(DocumentsError.notFound);
  }

  @override
  Future<void> setFavorite(String id, {required bool favorite}) async {
    calls++;
  }

  @override
  Future<DocumentCatalogs> catalogs() async {
    calls++;
    return const DocumentCatalogs();
  }
}

/// Una pantalla suelta con el tema y los textos de la app, para probar un
/// componente sin iniciar sesion.
class _Host extends StatelessWidget {
  const _Host({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => MaterialApp(
    theme: AppTheme.forAppearance(Appearance.original),
    locale: const Locale('es'),
    supportedLocales: SettingsCubit.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: Scaffold(body: Center(child: child)),
  );
}
