import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sigaco_movil/features/inventory/data/repositories/api_inventory_repository.dart';
import 'package:sigaco_movil/features/inventory/data/repositories/in_memory_inventory.dart';
import 'package:sigaco_movil/features/inventory/domain/entities/asset_capture.dart';
import 'package:sigaco_movil/features/inventory/domain/entities/asset_template.dart';
import 'package:sigaco_movil/features/inventory/domain/entities/inventory_asset.dart';
import 'package:sigaco_movil/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:sigaco_movil/features/inventory/presentation/bloc/asset_qr_cubit.dart';
import 'package:sigaco_movil/features/inventory/presentation/bloc/inventory_cubit.dart';
import 'package:sigaco_movil/features/inventory/presentation/bloc/inventory_detail_cubit.dart';

import '../../support/fake_api.dart';

Map<String, Object?> _asset({
  String status = 'ACTIVO',
  Object? inMaintenance,
  Object? openTickets,
  String? layer,
}) => {
  'id': 'a-1',
  'code': 'OAE-000094',
  'description': null,
  'assetTypeCode': 'OAE',
  'assetTypeLabel': 'Obra de arte especial',
  'subsystemCode': 'SGOAE',
  'roadCode': 'BR-381',
  'status': status,
  'source': 'WEBGIS',
  'externalLayerCode': ?layer,
  'externalId': layer == null ? null : 1,
  'inMaintenance': ?inMaintenance,
  'openTicketCount': ?openTickets,
  'statusReason': null,
  'brand': 'Acme',
  'serialNumber': 'S-1',
  'usefulLifeMonths': 240,
  'templateNumber': 3,
  'attributes': {'longitud_m': 35.5, 'material': 'CONCRETO'},
  'kmStart': 146.9,
  'geometry': {
    'type': 'Point',
    'coordinates': [-41.98, -18.85],
  },
};

const _template = {
  'assetTypeCode': 'OAE',
  'number': 3,
  'status': 'VIGENTE',
  'attributes': [
    {
      'key': 'longitud_m',
      'labelEs': 'Longitud',
      'dataType': 'DECIMAL',
      'unit': 'm',
      'origin': 'LAYER',
      'sortOrder': 1,
    },
    {
      'key': 'material',
      'labelEs': 'Material',
      'dataType': 'CATALOG',
      'catalogCode': 'MATERIAL',
      'sortOrder': 2,
    },
  ],
};

/// Un servidor del contrato de Activos: ficha sin plantilla (se pide aparte) y
/// con catalogos.
class _Repo
    with InMemoryInventory
    implements AssetTemplateSource, AssetCatalogSource {
  _Repo(this.asset);

  final InventoryAsset asset;
  int templateCalls = 0;

  @override
  Future<List<InventoryAsset>> allAssets() async => [asset];

  @override
  Future<InventoryAsset> get(String id) async => asset;

  @override
  Future<Uint8List?> mainPhoto(InventoryAsset asset) async => null;

  @override
  Future<AssetTemplate?> template(String typeCode) async {
    templateCalls++;
    return const AssetTemplate(
      typeCode: 'OAE',
      number: 3,
      attributes: [
        AttributeDefinition(
          key: 'material',
          labelEs: 'Material',
          type: AttributeType.catalog,
          catalogCode: 'MATERIAL',
        ),
      ],
    );
  }

  @override
  Future<Map<String, List<CatalogOption>>> catalogs() async => const {
    'MATERIAL': [
      CatalogOption(
        code: 'CONCRETO',
        labelEs: 'Concreto',
        labelPt: 'Concreto PT',
      ),
    ],
  };
}

class _Pending implements PendingAssetsSource {
  @override
  Future<List<InventoryAsset>> pendingAssets() async => const [
    InventoryAsset(
      id: 'cid-1',
      name: 'Poste',
      category: 'Poste',
      condition: AssetCondition.unknown,
      lifecycle: AssetLifecycle.pendingValidation,
      pendingSync: true,
    ),
  ];
}

void main() {
  group('ficha del servidor', () {
    test('trae estado, mantenimiento, ficha y datos del WebGIS', () {
      final a = ApiInventoryRepository.fromDetailResponse({
        'asset': _asset(inMaintenance: true, openTickets: 2, layer: 'oae2026'),
        'children': [],
        'attachmentCount': 4,
        'template': _template,
        'externalAttributes': {
          'identific': 'OAE 381 MG 146+900',
          'extensao': 35.5,
        },
      });

      expect(a.lifecycle, AssetLifecycle.active);
      expect(a.inMaintenance, isTrue);
      expect(a.openTicketCount, 2);
      expect(a.typeCode, 'OAE');
      expect(a.subsystemCode, 'SGOAE');
      expect(a.roadCode, 'BR-381');
      expect(a.source, 'WEBGIS');
      expect(a.externalLayerCode, 'oae2026');
      expect(a.externalId, '1');
      expect(a.fromWebGis, isTrue);
      expect(a.brand, 'Acme');
      expect(a.usefulLifeMonths, 240);
      expect(a.templateNumber, 3);
      expect(a.attachmentCount, 4);
      expect(a.attributes['longitud_m'], 35.5);
      expect(a.template!.attributes.map((f) => f.key), [
        'longitud_m',
        'material',
      ]);
      expect(a.template!.field('longitud_m')!.origin, AttributeOrigin.layer);
      expect(a.externalAttributes!['identific'], 'OAE 381 MG 146+900');
    });

    test('un servidor anterior al contrato sigue funcionando', () {
      final a = ApiInventoryRepository.fromDetailResponse({
        'asset': _asset(status: 'EN_MANTENIMIENTO'),
        'children': [],
        'attachmentCount': 0,
      });
      // EN_MANTENIMIENTO ya no es estado: es un activo con ticket abierto.
      expect(a.lifecycle, AssetLifecycle.active);
      expect(a.inMaintenance, isTrue);
      expect(a.template, isNull);
      expect(a.externalAttributes, isNull);
      expect(a.fromWebGis, isFalse);
    });

    test(
      'el renglon de la lista marca lo pendiente y lo que esta en mantenimiento',
      () {
        final a = ApiInventoryRepository.fromListItem({
          'id': 'a-2',
          'code': 'POSTE-000002',
          'assetTypeCode': 'POSTE',
          'assetTypeLabel': 'Poste',
          'status': 'PENDIENTE_VALIDACION',
          'source': 'MOVIL',
          'inMaintenance': true,
        });
        expect(a.lifecycle, AssetLifecycle.pendingValidation);
        expect(a.inMaintenance, isTrue);
        expect(a.source, 'MOVIL');
      },
    );
  });

  group('repositorio', () {
    late FakeApi api;
    late Directory dir;
    late ApiInventoryRepository repo;

    setUp(() {
      api = FakeApi();
      dir = Directory.systemTemp.createTempSync('asset_photos_');
      repo = ApiInventoryRepository(api.client(), cacheDir: () async => dir);
      addTearDown(() {
        try {
          dir.deleteSync(recursive: true);
        } on FileSystemException {
          // Lo recoge el sistema.
        }
      });
    });

    test('el QR abre la ficha del activo', () async {
      api.on(
        'GET /api/assets/by-qr/8f14e45f-ceea-467a-9f3e-1c2b3d4e5f60',
        FakeReply(200, {'asset': _asset(), 'children': []}),
      );
      final a = await repo.byQr(' 8f14e45f-ceea-467a-9f3e-1c2b3d4e5f60 ');
      expect(a.id, 'a-1');
    });

    test('un QR de otra concesion no se encuentra', () async {
      await expectLater(
        repo.byQr('8f14e45f-ceea-467a-9f3e-1c2b3d4e5f60'),
        throwsA(
          isA<InventoryException>().having(
            (e) => e.error,
            'error',
            InventoryError.notFound,
          ),
        ),
      );
    });

    test(
      'baja las fotos (sin la principal) y las guarda para verlas sin red',
      () async {
        api.on(
          'GET /api/assets/a-1/attachments',
          const FakeReply(200, [
            {'id': 'f-1', 'kind': 'FOTO', 'contentType': 'image/jpeg'},
            {'id': 'f-2', 'kind': 'FOTO', 'contentType': 'image/png'},
            {
              'id': 'd-1',
              'kind': 'DOCUMENTO',
              'contentType': 'application/pdf',
            },
          ]),
        );
        api.on(
          'GET /api/assets/a-1/attachments/f-2/content',
          FakeReply.bytes(200, Uint8List.fromList([1, 2, 3])),
        );
        const asset = InventoryAsset(
          id: 'a-1',
          name: 'x',
          category: 'x',
          condition: AssetCondition.unknown,
          mainPhotoId: 'f-1',
        );

        final paths = await repo.photos(asset);

        expect(paths, hasLength(1));
        expect(File(paths.single).readAsBytesSync(), [1, 2, 3]);
        // La segunda vez no se vuelve a bajar.
        final downloads = api.to('GET /api/assets/a-1/attachments/f-2/content');
        expect(downloads, hasLength(1));
        await repo.photos(asset);
        expect(
          api.to('GET /api/assets/a-1/attachments/f-2/content'),
          hasLength(1),
        );
      },
    );

    test('la foto principal guardada se ve sin red', () async {
      api.on(
        'GET /api/assets/a-1/attachments/f-1/content',
        FakeReply.bytes(200, Uint8List.fromList([9, 9])),
      );
      const asset = InventoryAsset(
        id: 'a-1',
        name: 'x',
        category: 'x',
        condition: AssetCondition.unknown,
        mainPhotoId: 'f-1',
      );
      expect(await repo.mainPhoto(asset), [9, 9]);
      api.offline = true;
      expect(await repo.mainPhoto(asset), [9, 9]);
    });
  });

  group('cubits', () {
    test(
      'la ficha pide la plantilla del tipo si no viene y los catalogos',
      () async {
        final repo = _Repo(
          ApiInventoryRepository.fromDetailResponse({'asset': _asset()}),
        );
        final cubit = InventoryDetailCubit(repo, 'a-1');
        await cubit.load();

        expect(repo.templateCalls, 1);
        expect(cubit.state.asset!.template!.number, 3);
        expect(
          cubit.state.catalogLabel('MATERIAL', 'concreto', 'pt'),
          'Concreto PT',
        );
      },
    );

    test('con la plantilla en la ficha no la vuelve a pedir', () async {
      final repo = _Repo(
        ApiInventoryRepository.fromDetailResponse({
          'asset': _asset(),
          'template': _template,
        }),
      );
      final cubit = InventoryDetailCubit(repo, 'a-1');
      await cubit.load();
      expect(repo.templateCalls, 0);
    });

    test('la lista muestra arriba lo que sigue en el telefono', () async {
      final repo = _Repo(
        ApiInventoryRepository.fromDetailResponse({'asset': _asset()}),
      );
      final cubit = InventoryCubit(repo, pending: _Pending());
      await cubit.load();
      expect(cubit.state.visible.map((a) => a.id), ['cid-1', 'a-1']);
      expect(cubit.state.visible.first.pendingSync, isTrue);
      // Lo que espera en el telefono no es del servidor: no cuenta en su total.
      expect(cubit.state.total, 1);
      expect(cubit.state.assets.map((a) => a.id), ['a-1']);
    });
  });

  group('lector de QR', () {
    test('saca el token de un enlace o del texto', () {
      expect(
        AssetQrCubit.tokenOf(
          'https://sigaco.app/qr/8F14E45F-CEEA-467A-9F3E-1C2B3D4E5F60',
        ),
        '8f14e45f-ceea-467a-9f3e-1c2b3d4e5f60',
      );
      expect(AssetQrCubit.tokenOf('hola'), isNull);
      // El enlace que imprime la web: el GUID despues de /qr/, aunque antes
      // venga otro (p. ej. una concesion en la ruta).
      expect(
        AssetQrCubit.tokenOf(
          'https://sigaco-front-dev.azurewebsites.net/c/11111111-1111-4111-8111-111111111111/inventario/qr/8f14e45f-ceea-467a-9f3e-1c2b3d4e5f60',
        ),
        '8f14e45f-ceea-467a-9f3e-1c2b3d4e5f60',
      );
    });

    test('encuentra el activo, o dice por que no', () async {
      final repo = _QrRepo();
      final cubit = AssetQrCubit(repo);

      await cubit.resolve('no es un codigo');
      expect(cubit.state.status, AssetQrStatus.invalid);

      await cubit.resolve('00000000-0000-4000-8000-000000000000');
      expect(cubit.state.status, AssetQrStatus.notFound);

      cubit.reset();
      await cubit.resolve('8f14e45f-ceea-467a-9f3e-1c2b3d4e5f60');
      expect(cubit.state.status, AssetQrStatus.found);
      expect(cubit.state.assetId, 'a-1');

      // Ya encontrado, lo que siga leyendo la camara no cambia nada.
      await cubit.resolve('00000000-0000-4000-8000-000000000000');
      expect(cubit.state.assetId, 'a-1');
    });

    test('sin red se puede volver a intentar', () async {
      final cubit = AssetQrCubit(_QrRepo(offline: true));
      await cubit.resolve('8f14e45f-ceea-467a-9f3e-1c2b3d4e5f60');
      expect(cubit.state.status, AssetQrStatus.failure);
      expect(cubit.state.error, InventoryError.network);
    });
  });
}

class _QrRepo with InMemoryInventory implements AssetQrSource {
  _QrRepo({this.offline = false});

  final bool offline;

  @override
  Future<InventoryAsset> byQr(String token) async {
    if (offline) throw const InventoryException(InventoryError.network);
    if (token != '8f14e45f-ceea-467a-9f3e-1c2b3d4e5f60') {
      throw const InventoryException(InventoryError.notFound);
    }
    return const InventoryAsset(
      id: 'a-1',
      name: 'x',
      category: 'x',
      condition: AssetCondition.unknown,
    );
  }

  @override
  Future<InventoryAsset> get(String id) => byQr(id);

  @override
  Future<List<InventoryAsset>> allAssets() async => const [];

  @override
  Future<Uint8List?> mainPhoto(InventoryAsset asset) async => null;
}
