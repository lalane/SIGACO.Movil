import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sigaco_movil/app/app.dart';
import 'package:sigaco_movil/app/dependencies.dart';
import 'package:sigaco_movil/app/shell/alert_routes.dart';
import 'package:sigaco_movil/core/ui/profile_avatar.dart';
import 'package:sigaco_movil/features/alerts/domain/entities/app_alert.dart';
import 'package:sigaco_movil/features/definitions/data/repositories/api_definitions_repository.dart';
import 'package:sigaco_movil/features/definitions/domain/entities/pending_definition.dart';
import 'package:sigaco_movil/features/definitions/domain/repositories/definitions_repository.dart';
import 'package:sigaco_movil/features/definitions/presentation/bloc/definition_detail_cubit.dart';
import 'package:sigaco_movil/features/definitions/presentation/bloc/definitions_cubit.dart';
import 'package:sigaco_movil/features/definitions/presentation/widgets/definitions_notice.dart';
import 'package:sigaco_movil/features/map/data/repositories/sample_map_repository.dart';
import 'package:sigaco_movil/features/works/data/repositories/sample_works_repository.dart';

import '../../support/fake_api.dart';
import '../../support/fakes.dart';
import '../../support/fonts.dart';
import '../../support/map_fakes.dart';
import '../../support/surface.dart';

Map<String, Object?> _dto(
  String code, {
  String status = 'ABIERTA',
  String priority = 'MEDIA',
  String module = 'TICKETS',
  String label = 'Tickets (registros)',
  String? mobile = 'tickets',
}) => {
  'code': code,
  'module': module,
  'moduleLabel': label,
  'indicator': null,
  'title': 'Título $code',
  'question': '¿Pregunta $code?',
  'assumption': 'Supuesto $code.',
  'ifVetoed': 'Se cambia.',
  'routes': ['/tickets'],
  'mobileModule': mobile,
  'source': 'DTF M11',
  'priority': priority,
  'status': status,
  'seedFile': 'tkt.json',
  'answerCount': 0,
  'lastAnswer': null,
  'updatedAt': '2026-11-10T12:00:00Z',
  'retiredAt': null,
  'relatedChecks': <String>[],
};

const _admin = {'canComment': true, 'canDecide': true, 'canReopen': false};

PendingDefinition _definition(
  String code, {
  DefinitionStatus status = DefinitionStatus.open,
  DefinitionPriority priority = DefinitionPriority.medium,
  String label = 'Tickets (registros)',
  String? mobile = 'tickets',
}) => PendingDefinition(
  code: code,
  module: 'TICKETS',
  moduleLabel: label,
  title: 'Título $code',
  question: '¿Pregunta $code?',
  assumption: 'Supuesto $code.',
  ifVetoed: 'Se cambia.',
  source: 'DTF',
  priority: priority,
  status: status,
  mobileModule: mobile,
);

/// Definiciones en memoria: responde y guarda el historial como el servidor.
class _MemoryDefinitions implements DefinitionsRepository {
  _MemoryDefinitions(
    this.items, {
    this.permissions = const DefinitionPermissions(
      canComment: true,
      canDecide: true,
    ),
  });

  final List<PendingDefinition> items;
  final DefinitionPermissions permissions;
  final answers = <(String, DefinitionAnswerKind, String?)>[];

  @override
  Future<DefinitionPage> list({String? mobileModule}) async => DefinitionPage(
    items: [
      for (final d in items)
        if (mobileModule == null || d.mobileModule == mobileModule) d,
    ],
    permissions: permissions,
  );

  @override
  Future<DefinitionDetail> get(String code) async => DefinitionDetail(
    definition: items.firstWhere((d) => d.code == code),
    history: const [],
    permissions: permissions,
  );

  @override
  Future<DefinitionDetail> answer(
    String code,
    DefinitionAnswerKind kind, {
    String? text,
  }) async {
    answers.add((code, kind, text));
    final i = items.indexWhere((d) => d.code == code);
    final d = items[i];
    final status = switch (kind) {
      DefinitionAnswerKind.agree => DefinitionStatus.accepted,
      DefinitionAnswerKind.change => DefinitionStatus.changeRequested,
      DefinitionAnswerKind.comment => DefinitionStatus.answered,
    };
    items[i] = _definition(d.code, status: status, mobile: d.mobileModule);
    return DefinitionDetail(
      definition: items[i],
      history: [
        DefinitionAnswer(
          kind: kind.code,
          text: text,
          newStatus: status,
          userName: 'Ana TEKIA',
          createdAt: DateTime.utc(2026, 11, 10, 15),
        ),
      ],
      permissions: permissions,
    );
  }
}

Matcher _fails(DefinitionsError e) =>
    throwsA(isA<DefinitionsException>().having((x) => x.error, 'error', e));

void main() {
  group('repositorio contra el API', () {
    late FakeApi api;
    late ApiDefinitionsRepository repo;

    setUp(() {
      api = FakeApi();
      repo = ApiDefinitionsRepository(api.client());
    });

    test(
      'la lista trae las definiciones y lo que puede hacer la persona',
      () async {
        api.on(
          'GET /api/definitions',
          FakeReply(200, {
            'items': [
              _dto('S-TKT-01', priority: 'ALTA'),
              _dto('S-TKT-02', status: 'CAMBIO_SOLICITADO'),
            ],
            'total': 2,
            'permissions': _admin,
          }),
        );

        final page = await repo.list(mobileModule: 'tickets');
        expect(api.to('GET /api/definitions').single.queryParameters, {
          'mobileModule': 'tickets',
        });
        expect(page.items.map((d) => d.code), ['S-TKT-01', 'S-TKT-02']);
        expect(page.items.first.priority, DefinitionPriority.high);
        expect(page.items.first.status.pending, isTrue);
        expect(page.items.last.status, DefinitionStatus.changeRequested);
        expect(page.items.last.status.pending, isFalse);
        expect(page.permissions.canDecide, isTrue);
        expect(page.permissions.canReopen, isFalse);
      },
    );

    test(
      'responder manda el tipo y el texto y devuelve el historial',
      () async {
        api.reply('POST /api/definitions/S-TKT-01/answer', (o) {
          expect(o.data, {'kind': 'CAMBIO', 'text': 'Son 48 h'});
          return FakeReply(200, {
            'definition': _dto('S-TKT-01', status: 'CAMBIO_SOLICITADO'),
            'history': [
              {
                'id': 'h1',
                'kind': 'CAMBIO',
                'text': 'Son 48 h',
                'previousStatus': 'ABIERTA',
                'newStatus': 'CAMBIO_SOLICITADO',
                'userName': 'Ana',
                'profileName': 'Administrador General',
                'client': 'MOBILE',
                'createdAt': '2026-11-10T15:00:00Z',
              },
            ],
            'permissions': _admin,
          });
        });

        final detail = await repo.answer(
          'S-TKT-01',
          DefinitionAnswerKind.change,
          text: '  Son 48 h ',
        );
        expect(detail.definition.status, DefinitionStatus.changeRequested);
        final h = detail.history.single;
        expect(h.previousStatus, DefinitionStatus.open);
        expect(h.fromApp, isTrue);
        expect(h.createdAt, DateTime.utc(2026, 11, 10, 15));
      },
    );

    test('cada falla del servidor se traduce', () async {
      api.on(
        'POST /api/definitions/S-TKT-01/answer',
        const FakeReply(403, {'code': 'DEFINITION_DECISION_DENIED'}),
      );
      api.on(
        'POST /api/definitions/S-TKT-02/answer',
        const FakeReply(422, {'code': 'DEFINITION_RETIRED'}),
      );
      await expectLater(
        repo.answer('S-TKT-01', DefinitionAnswerKind.agree),
        _fails(DefinitionsError.permissionDenied),
      );
      await expectLater(
        repo.answer('S-TKT-02', DefinitionAnswerKind.agree),
        _fails(DefinitionsError.retired),
      );
      await expectLater(
        repo.get('S-TKT-99'),
        _fails(DefinitionsError.notFound),
      );
      api.offline = true;
      await expectLater(repo.list(), _fails(DefinitionsError.network));
    });
  });

  group('cubits', () {
    test('la lista agrupa por modulo, ALTA primero, y filtra', () async {
      final repo = _MemoryDefinitions([
        _definition('S-TKT-01'),
        _definition('S-TKT-02', priority: DefinitionPriority.high),
        _definition('S-TKT-03', status: DefinitionStatus.accepted),
        _definition('S-ACT-01', label: 'Inventario', mobile: 'inventory'),
      ]);
      final cubit = DefinitionsCubit(repo, mobileModule: 'tickets');
      await cubit.load();

      // Desde tickets: solo las suyas y sin veredicto.
      expect(cubit.state.onlyModule, isTrue);
      expect(cubit.state.groups.single.$2.map((d) => d.code), [
        'S-TKT-02',
        'S-TKT-01',
      ]);
      cubit.setPendingOnly(false);
      expect(cubit.state.groups.single.$2, hasLength(3));
      cubit.setOnlyModule(false);
      expect(cubit.state.groups.map((g) => g.$1), [
        'Tickets (registros)',
        'Inventario',
      ]);
      cubit.setQuery('s-act');
      expect(cubit.state.groups.single.$2.single.code, 'S-ACT-01');
      expect(cubit.state.pendingCount, 3);
      await cubit.close();
    });

    test(
      'el detalle pide texto para el cambio y avisa cada respuesta',
      () async {
        final repo = _MemoryDefinitions([_definition('S-TKT-01')]);
        final cubit = DefinitionDetailCubit(repo, 'S-TKT-01');
        await cubit.load();

        expect(
          await cubit.answer(DefinitionAnswerKind.change, text: '  '),
          isFalse,
        );
        expect(cubit.state.sendError, DefinitionsError.validation);
        expect(repo.answers, isEmpty);

        expect(await cubit.answer(DefinitionAnswerKind.agree), isTrue);
        expect(cubit.state.saved, 1);
        expect(cubit.state.sendError, isNull);
        expect(
          cubit.state.detail!.definition.status,
          DefinitionStatus.accepted,
        );
        await cubit.close();
      },
    );
  });

  test('el aviso de una respuesta abre la definicion en la app', () {
    final alert = AppAlert(
      id: 'n1',
      title: 'S-DEF-01 · Comentario',
      body: 'Ana respondió',
      createdAt: DateTime.utc(2026, 11, 10),
      entityType: 'DEFINICION',
      entityId: 'S-DEF-01',
    );
    expect(alertRoute(alert, menuWith(const [])), '/definitions/S-DEF-01');
  });

  group('en la app', () {
    PackageInfo.setMockInitialValues(
      appName: 'SIGACO',
      packageName: 'mx.idare.sigaco',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );

    Future<void> launch(WidgetTester tester, _MemoryDefinitions repo) async {
      await tester.runAsync(loadAppFonts);
      useSurface(tester, TestSurface.largePhone);
      SharedPreferences.setMockInitialValues({});
      DefinitionsNotice.reset();
      final deps = AppDependencies(
        prefs: await SharedPreferences.getInstance(),
        authRepository: FakeAuthRepository(),
        credentialStore: FakeCredentialStore(supportsBiometrics: false),
        navigationRepository: FakeNavigationRepository(
          menu: menuWith(['PANEL', 'OBRAS']),
        ),
        brandingRepository: FakeBrandingRepository(const {}),
        logoStore: FakeLogoStore(),
        worksRepository: SampleWorksRepository(),
        sampleWorks: true,
        definitionsRepository: repo,
        mapRepository: SampleMapRepository(),
        roadSegmentsRepository: FakeRoadSegmentsRepository(),
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
    }

    testWidgets('desde el menu de la cuenta se contesta una definicion', (
      tester,
    ) async {
      final repo = _MemoryDefinitions([
        _definition('S-TKT-01', priority: DefinitionPriority.high),
        _definition('S-TKT-02', status: DefinitionStatus.accepted),
      ]);
      await launch(tester, repo);

      await tester.tap(find.byType(ProfileAvatar).first);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('panel-definitions')));
      await tester.pumpAndSettle();

      // Por omision, solo las que esperan respuesta.
      expect(find.byKey(const Key('definition-S-TKT-01')), findsOneWidget);
      expect(find.byKey(const Key('definition-S-TKT-02')), findsNothing);

      await tester.tap(find.byKey(const Key('definition-S-TKT-01')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('definition-detail')), findsOneWidget);
      expect(find.text('¿Pregunta S-TKT-01?'), findsOneWidget);

      await tester.tap(find.byKey(const Key('definition-change')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('definition-answer-text')),
        'Son 48 h hábiles',
      );
      await tester.tap(find.byKey(const Key('definition-answer-send')));
      await tester.pumpAndSettle();

      expect(repo.answers.single, (
        'S-TKT-01',
        DefinitionAnswerKind.change,
        'Son 48 h hábiles',
      ));
      expect(find.text('Respuesta guardada'), findsOneWidget);
      expect(find.text('Cambio solicitado'), findsWidgets);
    });

    testWidgets('quien no administra solo puede comentar', (tester) async {
      final repo = _MemoryDefinitions([
        _definition('S-TKT-01'),
      ], permissions: const DefinitionPermissions(canComment: true));
      await launch(tester, repo);
      await tester.tap(find.byType(ProfileAvatar).first);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('panel-definitions')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('definition-S-TKT-01')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('definition-agree')), findsNothing);
      expect(find.byKey(const Key('definition-change')), findsNothing);
      expect(find.byKey(const Key('definition-comment')), findsOneWidget);
      expect(find.byKey(const Key('definition-decide-hint')), findsOneWidget);
    });

    testWidgets('al abrir un modulo avisa sus definiciones sin veredicto', (
      tester,
    ) async {
      final repo = _MemoryDefinitions([
        _definition('S-MC1-01', mobile: 'works'),
        _definition('S-TKT-01'),
      ]);
      await launch(tester, repo);
      await tester.tap(
        find.descendant(
          of: find.byType(GridView),
          matching: find.text('Obras'),
        ),
      );
      // Al terminar la transicion el aviso queda solo en la pantalla del modulo.
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('definitions-notice')), findsOneWidget);
      expect(
        find.text('Hay 1 definiciones sin veredicto de este módulo'),
        findsOneWidget,
      );
      await tester.tap(find.text('Ver'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('definition-S-MC1-01')), findsOneWidget);
      expect(find.byKey(const Key('definition-S-TKT-01')), findsNothing);
    });

    testWidgets('el aviso se va solo y no tapa los botones de la pantalla', (
      tester,
    ) async {
      final repo = _MemoryDefinitions([
        _definition('S-MC1-01', mobile: 'works'),
      ]);
      await launch(tester, repo);
      await tester.tap(
        find.descendant(
          of: find.byType(GridView),
          matching: find.text('Obras'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('definitions-notice')), findsOneWidget);
      // Lleva accion («Ver»), pero no se queda: a los 6 segundos se va.
      await tester.pump(const Duration(seconds: 7));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('definitions-notice')), findsNothing);
    });
  });
}
