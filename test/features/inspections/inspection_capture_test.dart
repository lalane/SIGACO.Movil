import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sigaco_movil/core/offline/offline_database.dart';
import 'package:sigaco_movil/core/offline/operation.dart';
import 'package:sigaco_movil/core/offline/operation_queue.dart';
import 'package:sigaco_movil/core/offline/sync_engine.dart';
import 'package:sigaco_movil/features/inspections/data/repositories/api_inspection_capture_repository.dart';
import 'package:sigaco_movil/features/inspections/data/repositories/offline_inspection_capture_repository.dart';
import 'package:sigaco_movil/features/inspections/data/sync/inspections_sync_remote.dart';
import 'package:sigaco_movil/features/inspections/domain/entities/inspection.dart';
import 'package:sigaco_movil/features/inspections/domain/entities/inspection_capture.dart';
import 'package:sigaco_movil/features/inspections/domain/repositories/inspection_capture_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../support/fake_api.dart';

const _scope = OfflineScope(userId: 'ana', concessionId: 'c1');
const _id = '3f2b8a52-0000-4000-8000-000000000020';

/// La plantilla de drenaje superficial (como la siembra el servidor): estado,
/// extension obligatoria si se repara y una foto obligatoria.
const _template = {
  'sections': [
    {
      'key': 'identificacion',
      'label': 'Identificación',
      'fields': [
        {
          'key': 'codigo',
          'label': 'Código',
          'type': 'TEXTO',
          'source': 'ACTIVO',
          'assetProperty': 'code',
        },
      ],
    },
    {
      'key': 'estado',
      'label': 'Estado',
      'fields': [
        {
          'key': 'estado_conservacion',
          'label': 'Estado',
          'type': 'OPCION',
          'required': true,
          'options': [
            {'value': 'BOM', 'label': 'Bueno', 'condition': 'BUENO'},
            {'value': 'PRECARIO', 'label': 'Precario', 'condition': 'MALO'},
          ],
        },
        {'key': 'reparar', 'label': 'Reparar', 'type': 'SI_NO'},
        {
          'key': 'extension',
          'label': 'Extensión',
          'type': 'NUMERO',
          'min': 0,
          'max': 100,
          'requiredIf': {'field': 'reparar', 'equals': true},
        },
      ],
    },
    {
      'key': 'fotos',
      'label': 'Fotos',
      'fields': [
        {
          'key': 'foto_1',
          'label': 'Foto 1',
          'type': 'EVIDENCIA',
          'required': true,
        },
      ],
    },
  ],
  'condition': {
    'mode': 'CAMPO',
    'fields': ['estado.estado_conservacion'],
  },
};

Map<String, Object?> _capture({
  String status = 'EN_PROCESO',
  Map<String, Object?> answers = const {},
  List<Object?> evidences = const [],
}) => {
  'inspection': {
    'id': _id,
    'folio': 'IN-2026-000020',
    'inspectionTypeId': 't1',
    'inspectionTypeLabel': 'Monitoreo de drenaje superficial',
    'status': status,
    'assetId': 'a1',
    'assetCode': 'DA 381 MG 147+325 L 1',
    'kmStart': 147.325,
    'rowVersion': 4,
  },
  'template': _template,
  'templateVersionNumber': 1,
  'answers': {
    'identificacion': {'codigo': 'DA 381 MG 147+325 L 1'},
    ...answers,
  },
  'evidences': evidences,
  'findings': const [],
  'missing': const [
    {
      'path': 'answers.estado.estado_conservacion',
      'message': 'Es obligatorio para finalizar.',
    },
  ],
  'actions': {'save': true, 'finalize': true},
  'requiresReview': true,
  'locationToleranceMeters': 50,
};

void main() {
  sqfliteFfiInit();

  group('plantilla en el telefono', () {
    final template = TemplateDefinition.fromJson(_template);

    test('la condicion sale del campo de opciones', () {
      final r = TemplateEvaluator.evaluate(template, {
        'estado': {'estado_conservacion': 'PRECARIO'},
      });
      expect((r.state, r.native), ('MALO', 'Precario'));
    });

    test(
      'la extension solo es obligatoria si se repara, y la foto siempre',
      () {
        List<String> paths(Map<String, dynamic> answers, int photos) => [
          for (final i in TemplateEvaluator.validate(
            template,
            answers,
            finalize: true,
            photos: (_) => photos,
          ))
            i.path,
        ];
        expect(
          paths({
            'estado': {'estado_conservacion': 'BOM', 'reparar': true},
          }, 0),
          ['answers.estado.extension', 'answers.fotos.foto_1'],
        );
        expect(
          paths({
            'estado': {'estado_conservacion': 'BOM', 'reparar': false},
          }, 1),
          isEmpty,
        );
        // El dato del activo no se pide: lo pone el servidor.
        expect(paths({}, 1), ['answers.estado.estado_conservacion']);
      },
    );

    test('un borrador admite vacios pero no un numero fuera de rango', () {
      final issues = TemplateEvaluator.validate(
        template,
        {
          'estado': {'extension': 150},
        },
        finalize: false,
        photos: (_) => 0,
      );
      expect(issues.single.path, 'answers.estado.extension');
    });

    test('la peor de dos partes y el conteo de anomalias', () {
      final culvert = TemplateDefinition.fromJson({
        'sections': [
          for (final side in ['montante', 'jusante'])
            {
              'key': side,
              'label': side,
              'fields': [
                {
                  'key': 'estado',
                  'label': 'Estado',
                  'type': 'OPCION',
                  'options': [
                    {'value': 'BOM', 'label': 'Bom', 'condition': 'BUENO'},
                    {
                      'value': 'REGULAR',
                      'label': 'Regular',
                      'condition': 'REGULAR',
                    },
                  ],
                },
              ],
            },
        ],
        'condition': {
          'mode': 'PEOR',
          'fields': ['montante.estado', 'jusante.estado'],
        },
      });
      expect(
        TemplateEvaluator.evaluate(culvert, {
          'montante': {'estado': 'BOM'},
          'jusante': {'estado': 'REGULAR'},
        }).state,
        'REGULAR',
      );

      final building = TemplateDefinition.fromJson({
        'sections': [
          {
            'key': 'componentes',
            'label': 'Componentes',
            'fields': [
              for (final k in ['a', 'b', 'c', 'd'])
                {
                  'key': k,
                  'label': k,
                  'type': 'OPCION',
                  'options': [
                    {'value': 'NENHUMA', 'label': 'Nenhuma'},
                    {'value': 'PEQUENA', 'label': 'Pequena'},
                    {'value': 'ALTA', 'label': 'Alta'},
                  ],
                },
            ],
          },
        ],
        'condition': {
          'mode': 'CONTEO',
          'fields': ['componentes.*'],
          'rules': [
            {'value': 'ALTA', 'atLeast': 1, 'result': 'MALO', 'native': 'Ruim'},
            {
              'value': 'PEQUENA',
              'atLeast': 4,
              'result': 'REGULAR',
              'native': 'Regular',
            },
          ],
          'defaultResult': 'BUENO',
          'defaultNative': 'Bom',
        },
      });
      Map<String, dynamic> grades(List<String> g) => {
        'componentes': {'a': g[0], 'b': g[1], 'c': g[2], 'd': g[3]},
      };
      expect(
        TemplateEvaluator.evaluate(
          building,
          grades(['PEQUENA', 'PEQUENA', 'PEQUENA', 'NENHUMA']),
        ).native,
        'Bom',
      );
      expect(
        TemplateEvaluator.evaluate(
          building,
          grades(['PEQUENA', 'PEQUENA', 'PEQUENA', 'PEQUENA']),
        ).native,
        'Regular',
      );
      expect(
        TemplateEvaluator.evaluate(
          building,
          grades(['ALTA', 'NENHUMA', 'NENHUMA', 'NENHUMA']),
        ).state,
        'MALO',
      );
    });
  });

  group('captura contra el servidor', () {
    test(
      'la vista trae plantilla, respuestas, lo que falta y las acciones',
      () {
        final view = ApiInspectionCaptureRepository.fromJson(_capture());
        expect(view.folio, 'IN-2026-000020');
        expect(view.template.activeSections.map((s) => s.key), [
          'identificacion',
          'estado',
          'fotos',
        ]);
        expect(view.answers['identificacion'], {
          'codigo': 'DA 381 MG 147+325 L 1',
        });
        expect(view.missing.single.path, 'answers.estado.estado_conservacion');
        expect(
          (view.editable, view.actions.finalize, view.status),
          (true, true, InspectionStatus.inProgress),
        );
      },
    );

    test('los campos que faltan al finalizar llegan con su ruta', () async {
      final api = FakeApi()
        ..on(
          'POST /api/inspections/$_id/finalize',
          const FakeReply(400, {
            'errors': {
              'locationJustification': [
                'Estás a 800 m del activo (tolerancia 50 m): explica por qué.',
              ],
            },
          }),
        );
      final repo = ApiInspectionCaptureRepository(api.client());
      final view = ApiInspectionCaptureRepository.fromJson(_capture());
      await expectLater(
        repo.finalize(view, executedAt: DateTime.utc(2026, 11, 10)),
        throwsA(
          isA<InspectionIncompleteException>().having(
            (e) => e.location?.message,
            'ubicacion',
            contains('800 m'),
          ),
        ),
      );
    });
  });

  group('sin conexion', () {
    late FakeApi api;
    late OfflineDatabase db;
    late OperationQueue queue;
    late OfflineInspectionCaptureRepository repo;
    late InspectionCaptureView view;

    setUp(() async {
      api = FakeApi()
        ..on('GET /api/inspections/$_id/capture', FakeReply(200, _capture()));
      db = await OfflineDatabase.open(
        factory: databaseFactoryFfi,
        path: inMemoryDatabasePath,
      );
      queue = OperationQueue(db);
      repo = OfflineInspectionCaptureRepository(
        ApiInspectionCaptureRepository(api.client()),
        queue,
        clock: () => DateTime.utc(2026, 11, 10, 9),
      );
      await repo.bind(_scope);
      view = await repo.capture(_id);
      api.offline = true;
    });

    tearDown(() async {
      await queue.dispose();
      await db.close();
    });

    test(
      'el borrador queda en la cola con la version de partida, uno solo por inspeccion',
      () async {
        view = await repo.save(view, {
          'estado': {'estado_conservacion': 'BOM'},
        });
        expect((view.pendingSync, view.computedCondition), (true, 'BUENO'));
        view = await repo.save(view, {
          'estado': {'estado_conservacion': 'PRECARIO'},
        });
        final ops = await queue.list(_scope);
        expect(ops.single.entity, 'INSPECTION');
        expect(
          (ops.single.kind, ops.single.recordId, ops.single.baseVersion),
          (OperationKind.update, _id, 4),
        );
        expect(ops.single.payload['answers'], {
          'estado': {'estado_conservacion': 'PRECARIO'},
        });
        expect(view.computedCondition, 'MALO');
      },
    );

    test('la foto se guarda con la captura y cuenta para finalizar', () async {
      final photo = File(
        '${Directory.systemTemp.createTempSync('in_').path}/f.jpg',
      )..writeAsBytesSync([1, 2, 3]);
      view = await repo.save(view, {
        'estado': {'estado_conservacion': 'BOM'},
      });
      expect(view.missing.map((m) => m.path), ['answers.fotos.foto_1']);
      view = await repo.addPhoto(
        view,
        photo.path,
        fieldKey: 'fotos.foto_1',
        position: const FindingPosition(
          latitude: -19.85,
          longitude: -43.95,
          accuracyMeters: 5,
        ),
        capturedAt: DateTime.utc(2026, 11, 10, 9),
      );
      expect(view.missing, isEmpty);
      expect(view.evidences.single.pending, isTrue);

      // Finalizar sin red queda en la cola, con la hora del telefono.
      view = await repo.finalize(
        view,
        executedAt: DateTime.utc(2026, 11, 10, 9, 5),
      );
      final op = (await queue.list(_scope)).single;
      expect(
        (op.payload['finalize'] as Map)['executedAt'],
        '2026-11-10T09:05:00.000Z',
      );
      expect(
        (op.payload[OfflineInspectionCaptureRepository.photosKey] as List)
            .length,
        1,
      );
      expect(view.serverStatus, 'ATENDIDA');
    });

    test(
      'no se finaliza con obligatorios vacios, ni siquiera sin red',
      () async {
        await expectLater(
          repo.finalize(view, executedAt: DateTime.utc(2026, 11, 10)),
          throwsA(isA<InspectionIncompleteException>()),
        );
        expect(await queue.list(_scope), isEmpty);
      },
    );

    test('un hallazgo sin red espera su ticket hasta sincronizarse', () async {
      view = await repo.addFinding(
        view,
        description: 'Bajada obstruida',
        capturedAt: DateTime.utc(2026, 11, 10),
      );
      final op = (await queue.list(_scope)).single;
      expect(
        (op.entity, op.kind, op.recordId),
        ('INSPECTION_FINDING', OperationKind.insert, _id),
      );
      expect(op.payload['severity'], 'MEDIA');
      expect(view.findings.single.pending, isTrue);
    });
  });

  group('envio de la captura', () {
    test(
      'primero suben las fotos y despues la captura; un cambio en el servidor es conflicto',
      () async {
        final api = FakeApi()
          ..on(
            'POST /api/inspections/$_id/evidence',
            const FakeReply(201, {
              'attachment': {'id': 'e1'},
            }),
          )
          ..on(
            'POST /api/sync/operations',
            const FakeReply(200, {
              'operations': [
                {'status': 'CONFLICTO'},
              ],
            }),
          );
        final remote = InspectionsSyncRemote(
          api.client(),
          () async => 'android-1',
          ApiInspectionCaptureRepository(api.client()),
        );
        final photo = File(
          '${Directory.systemTemp.createTempSync('in_').path}/f.jpg',
        )..writeAsBytesSync([1, 2, 3]);
        final now = DateTime.utc(2026, 11, 10);
        final outcome = await remote.send(
          PendingOperation(
            id: 'op-1',
            scope: _scope,
            entity: 'INSPECTION',
            kind: OperationKind.update,
            recordId: _id,
            baseVersion: 4,
            payload: {
              'answers': {
                'estado': {'estado_conservacion': 'BOM'},
              },
              OfflineInspectionCaptureRepository.photosKey: [
                {
                  'path': photo.path,
                  'fieldKey': 'fotos.foto_1',
                  'clientUuid': 'c-1',
                  'capturedAt': now.toIso8601String(),
                },
              ],
            },
            status: OperationStatus.pending,
            createdAt: now,
            capturedAt: now,
            updatedAt: now,
          ),
        );
        expect(outcome, isA<SyncConflicted>());
        expect(api.requests.map((r) => '${r.method} ${r.path}'), [
          'POST /api/inspections/$_id/evidence',
          'POST /api/sync/operations',
        ]);
        final body = api.requests.last.data as Map;
        final sent = (body['operations'] as List).single as Map;
        expect(
          (
            sent['operation'],
            sent['baseVersion'],
            (sent['payload'] as Map).containsKey('_photos'),
          ),
          ('UPDATE', 4, false),
        );
      },
    );

    test('la misma foto del mismo hallazgo siempre manda la misma clave', () {
      expect(
        ApiInspectionCaptureRepository.stableUuid('f1|a.jpg'),
        ApiInspectionCaptureRepository.stableUuid('f1|a.jpg'),
      );
      expect(
        ApiInspectionCaptureRepository.stableUuid('f1|a.jpg'),
        isNot(ApiInspectionCaptureRepository.stableUuid('f1|b.jpg')),
      );
      expect(
        RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        ).hasMatch(ApiInspectionCaptureRepository.stableUuid('x')),
        isTrue,
      );
    });
  });
}
