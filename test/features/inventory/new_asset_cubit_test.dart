import 'package:flutter_test/flutter_test.dart';
import 'package:sigaco_movil/features/inventory/domain/entities/asset_capture.dart';
import 'package:sigaco_movil/features/inventory/domain/entities/asset_template.dart';
import 'package:sigaco_movil/features/inventory/domain/repositories/asset_capture_repository.dart';
import 'package:sigaco_movil/features/inventory/presentation/bloc/new_asset_cubit.dart';

const _poste = AssetTypeOption(
  code: 'POSTE',
  labelEs: 'Poste',
  labelPt: 'Poste PT',
  geometryType: 'POINT',
);
const _defensa = AssetTypeOption(
  code: 'DEFENSA',
  labelEs: 'Defensa metálica',
  geometryType: 'LINESTRING',
  requiresKmEnd: true,
);

final _fichaPoste = AssetTemplate(
  typeCode: 'POSTE',
  number: 2,
  attributes: const [
    AttributeDefinition(
      key: 'altura_m',
      labelEs: 'Altura',
      type: AttributeType.decimal,
      unit: 'm',
      required: true,
      min: 0,
      max: 12,
    ),
    AttributeDefinition(
      key: 'luminarias',
      labelEs: 'Luminarias',
      type: AttributeType.integer,
    ),
    AttributeDefinition(
      key: 'iluminado',
      labelEs: 'Iluminado',
      type: AttributeType.boolean,
    ),
    AttributeDefinition(
      key: 'instalado',
      labelEs: 'Instalado',
      type: AttributeType.date,
    ),
    AttributeDefinition(
      key: 'revisado',
      labelEs: 'Revisado',
      type: AttributeType.dateTime,
    ),
    AttributeDefinition(
      key: 'material',
      labelEs: 'Material',
      type: AttributeType.catalog,
      catalogCode: 'MATERIAL',
    ),
    AttributeDefinition(key: 'nota', labelEs: 'Nota', type: AttributeType.text),
  ],
);

/// Tipos, fichas y ubicacion fijos; anota lo que se manda a guardar.
class _Repo implements AssetCaptureRepository {
  _Repo({this.placement = const RoadPlacement.unknown(), this.failure});

  RoadPlacement placement;
  AssetCaptureException? failure;
  NewAsset? created;
  bool queue = false;
  int catalogCalls = 0;

  @override
  Future<List<AssetTypeOption>> types() async => const [_poste, _defensa];

  @override
  Future<AssetTemplate> template(String typeCode) async => switch (typeCode) {
    'POSTE' => _fichaPoste,
    'DEFENSA' => const AssetTemplate(
      typeCode: 'DEFENSA',
      number: 1,
      attributes: [
        AttributeDefinition(
          key: 'altura_m',
          labelEs: 'Altura',
          type: AttributeType.decimal,
        ),
      ],
    ),
    _ => throw const AssetCaptureException(AssetCaptureError.noTemplate),
  };

  @override
  Future<Map<String, List<CatalogOption>>> catalogs() async {
    catalogCalls++;
    return const {
      'MATERIAL': [CatalogOption(code: 'ACERO', labelEs: 'Acero')],
    };
  }

  @override
  Future<RoadPlacement> locate(double longitude, double latitude) async =>
      placement;

  @override
  Future<CapturedAsset> create(NewAsset draft) async {
    final error = failure;
    if (error != null) throw error;
    created = draft;
    return queue
        ? CapturedAsset(id: draft.clientId, queued: true)
        : const CapturedAsset(id: 'a-1', code: 'POSTE-000001');
  }
}

class _Gps implements AssetPositionSource {
  _Gps([this.position]);

  AssetPosition? position;

  @override
  Future<AssetPosition?> current() async => position;
}

const _here = AssetPosition(
  latitude: -18.85,
  longitude: -41.98,
  accuracyMeters: 8,
);

const _onRoad = RoadPlacement(
  status: RoadPlacementStatus.onRoad,
  roadId: 'road-9',
  roadCode: 'BR-381',
  direction: 'DECRECIENTE',
  km: 150.2,
  segmentCode: '381BMG0160',
);

NewAssetCubit _cubit(_Repo repo, {AssetPosition? at = _here}) => NewAssetCubit(
  repo,
  positionSource: _Gps(at),
  clock: () => DateTime.utc(2026, 11, 8, 12),
  clientIdGenerator: () => 'cid-1',
);

void main() {
  group('ubicacion', () {
    test('el GPS ubica el punto y llena km y sentido', () async {
      final cubit = _cubit(_Repo(placement: _onRoad));
      await cubit.loadTypes();
      await cubit.readPosition();

      expect(cubit.state.types.map((t) => t.code), ['POSTE', 'DEFENSA']);
      expect(cubit.state.gps, GpsStatus.ready);
      expect(cubit.state.position, _here);
      expect(cubit.state.kmLabel, 'KM 150+200');
      expect(cubit.state.direction, 'DECRECIENTE');
    });

    test('lo que la persona corrige no se pisa al volver a leer', () async {
      final cubit = _cubit(_Repo(placement: _onRoad));
      cubit.setKm('151+000');
      cubit.setDirection('CRECIENTE');
      await cubit.readPosition();
      expect(cubit.state.kmLabel, '151+000');
      expect(cubit.state.direction, 'CRECIENTE');
    });

    test(
      'volver a leer el GPS pone al dia lo que lleno la lectura anterior',
      () async {
        final repo = _Repo(placement: _onRoad);
        final cubit = _cubit(repo);
        await cubit.readPosition();
        expect(cubit.state.kmLabel, 'KM 150+200');
        repo.placement = const RoadPlacement(
          status: RoadPlacementStatus.onRoad,
          roadId: 'road-9',
          direction: 'CRECIENTE',
          km: 151,
        );
        await cubit.readPosition();
        expect(cubit.state.kmLabel, 'KM 151+000');
        expect(cubit.state.direction, 'CRECIENTE');
      },
    );

    test('con los dos sentidos en el mismo trazo hay que elegir', () async {
      final cubit = _cubit(
        _Repo(
          placement: const RoadPlacement(
            status: RoadPlacementStatus.onRoad,
            roadId: 'road-9',
            km: 150.2,
            direction: 'CRECIENTE',
            directionAmbiguous: true,
          ),
        ),
      );
      await cubit.readPosition();
      expect(cubit.state.direction, isNull);
      expect(cubit.state.issues, contains(NewAssetIssue.direction));
      cubit.setDirection('CRECIENTE');
      expect(cubit.state.issues, isNot(contains(NewAssetIssue.direction)));
    });

    test('sin GPS hay que escribir el km', () async {
      final cubit = _cubit(_Repo(), at: null);
      await cubit.readPosition();
      await cubit.chooseType(_poste);
      expect(cubit.state.gps, GpsStatus.unavailable);
      expect(cubit.state.issues, contains(NewAssetIssue.location));
      cubit.setKm('abc');
      expect(cubit.state.issues, contains(NewAssetIssue.km));
      cubit.setKm('150+200');
      expect(cubit.state.issues, isEmpty);
    });

    test('un tipo de linea no se ubica con el punto y pide km final', () async {
      final cubit = _cubit(_Repo());
      await cubit.readPosition();
      await cubit.chooseType(_defensa);
      // Hay punto, pero el tipo se dibuja como linea: hace falta el km.
      expect(cubit.state.pointLocates, isFalse);
      expect(cubit.state.issues, contains(NewAssetIssue.location));
      cubit.setKm('150+200');
      expect(cubit.state.issues, contains(NewAssetIssue.kmEnd));
      cubit.setKmEnd('150+100');
      expect(cubit.state.issues, contains(NewAssetIssue.kmEnd));
      cubit.setKmEnd('150+400');
      expect(cubit.state.issues, isEmpty);
    });
  });

  group('formulario de la ficha', () {
    test('elegir el tipo trae su ficha y sus catalogos', () async {
      final repo = _Repo();
      final cubit = _cubit(repo);
      await cubit.load();
      await cubit.chooseType(_poste);

      expect(cubit.state.templateStatus, NewAssetLoad.ready);
      expect(cubit.state.fields.map((f) => f.key), [
        'altura_m',
        'luminarias',
        'iluminado',
        'instalado',
        'revisado',
        'material',
        'nota',
      ]);
      expect(cubit.state.catalogs['MATERIAL'], hasLength(1));
      // Los catalogos se piden una sola vez.
      await cubit.chooseType(_defensa);
      await cubit.chooseType(_poste);
      expect(repo.catalogCalls, 1);
    });

    test('obligatorios, minimos, maximos y enteros', () async {
      final cubit = _cubit(_Repo());
      await cubit.chooseType(_poste);
      expect(cubit.state.attributeIssues, {
        'altura_m': AttributeIssue.required,
      });

      cubit.setValue('altura_m', '13');
      expect(cubit.state.attributeIssues['altura_m'], AttributeIssue.aboveMax);
      cubit.setValue('altura_m', '-1');
      expect(cubit.state.attributeIssues['altura_m'], AttributeIssue.belowMin);
      cubit.setValue('altura_m', 'alto');
      expect(cubit.state.attributeIssues['altura_m'], AttributeIssue.notNumber);
      cubit.setValue('altura_m', '7,5');
      expect(cubit.state.attributeIssues, isEmpty);

      cubit.setValue('luminarias', '2.5');
      expect(
        cubit.state.attributeIssues['luminarias'],
        AttributeIssue.notInteger,
      );
      cubit.setValue('luminarias', '2');
      expect(cubit.state.attributeIssues, isEmpty);

      cubit.setValue('nota', 'x' * 501);
      expect(cubit.state.attributeIssues['nota'], AttributeIssue.tooLong);
    });

    test(
      'al cambiar de tipo se conserva lo capturado que sigue valiendo',
      () async {
        final cubit = _cubit(_Repo());
        await cubit.chooseType(_poste);
        cubit.setValue('altura_m', '7');
        cubit.setValue('luminarias', '2');
        await cubit.chooseType(_defensa);
        expect(cubit.state.values, {'altura_m': '7'});
      },
    );

    test('no guarda con campos por corregir: los muestra', () async {
      final repo = _Repo();
      final cubit = _cubit(repo);
      await cubit.save();
      expect(cubit.state.showIssues, isTrue);
      expect(cubit.state.issues, contains(NewAssetIssue.type));
      expect(repo.created, isNull);
    });
  });

  group('guardar', () {
    test('manda los campos como los recibe el servidor', () async {
      final repo = _Repo(placement: _onRoad);
      final cubit = _cubit(repo);
      await cubit.loadTypes();
      await cubit.readPosition();
      await cubit.chooseType(_poste);
      cubit
        ..setValue('altura_m', '7,5')
        ..setValue('luminarias', '2')
        ..setValue('iluminado', true)
        ..setValue('instalado', DateTime.utc(2020, 3, 9))
        ..setValue('revisado', DateTime.utc(2026, 11, 8, 14, 30))
        ..setValue('material', 'acero')
        ..setValue('nota', '  ')
        ..setDescription('Poste del puente')
        ..setPhoto(0, '/fotos/1.jpg')
        ..setPhoto(2, '/fotos/3.jpg');

      await cubit.save();

      final draft = repo.created!;
      expect(draft.clientId, 'cid-1');
      expect(draft.typeCode, 'POSTE');
      expect(draft.typeLabel, 'Poste');
      expect(draft.capturedAt, DateTime.utc(2026, 11, 8, 12));
      expect(draft.roadId, 'road-9');
      expect(draft.kmStart, closeTo(150.2, 1e-9));
      expect(draft.direction, 'DECRECIENTE');
      expect(draft.position, _here);
      expect(draft.sendPoint, isTrue);
      expect(draft.attributes, {
        'altura_m': 7.5,
        'luminarias': 2,
        'iluminado': true,
        'instalado': '2020-03-09',
        'revisado': '2026-11-08T14:30:00.000Z',
        'material': 'ACERO',
      });
      expect(draft.photoPaths, ['/fotos/1.jpg', '/fotos/3.jpg']);
      expect(cubit.state.saved, isTrue);
      expect(cubit.state.result!.code, 'POSTE-000001');
    });

    test('sin red queda en el telefono', () async {
      final repo = _Repo()..queue = true;
      final cubit = _cubit(repo);
      await cubit.readPosition();
      await cubit.chooseType(_poste);
      cubit.setValue('altura_m', '7');
      await cubit.save();
      expect(cubit.state.result!.queued, isTrue);
      expect(cubit.state.result!.id, 'cid-1');
    });

    test('si el servidor lo rechaza se puede corregir y reintentar', () async {
      final repo = _Repo(
        failure: const AssetCaptureException(
          AssetCaptureError.validation,
          message: 'Es mayor que el máximo (12).',
          fieldErrors: {
            'attributes.altura_m': ['Es mayor que el máximo (12).'],
          },
        ),
      );
      final cubit = _cubit(repo);
      await cubit.readPosition();
      await cubit.chooseType(_poste);
      cubit.setValue('altura_m', '7');
      await cubit.save();
      expect(cubit.state.saved, isFalse);
      expect(cubit.state.failure!.error, AssetCaptureError.validation);

      repo.failure = null;
      await cubit.save();
      expect(cubit.state.saved, isTrue);
      expect(cubit.state.failure, isNull);
    });
  });
}
