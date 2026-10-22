import 'package:flutter_test/flutter_test.dart';
import 'package:sigaco_movil/features/alerts/data/repositories/api_alerts_repository.dart';
import 'package:sigaco_movil/features/alerts/domain/entities/app_alert.dart';
import 'package:sigaco_movil/features/alerts/domain/repositories/alerts_repository.dart';

import '../../support/fake_api.dart';

Map<String, Object?> _item(
  String id, {
  String? readAt,
  String? entityType = 'TICKET',
  String? entityId = 'T-1',
  String message = 'Algo paso',
}) => {
  'id': id,
  'concessionId': 'c1',
  'eventCode': 'TICKET_VENCIDO',
  'title': 'Ticket vencido',
  'message': message,
  'entityType': entityType,
  'entityId': entityId,
  'createdAt': '2026-10-22T15:00:00Z',
  'readAt': readAt,
};

Matcher _fails(AlertsError error) =>
    throwsA(isA<AlertsException>().having((e) => e.error, 'error', error));

void main() {
  late FakeApi api;
  late ApiAlertsRepository repo;
  const base = '/api/auth/me/notifications';

  setUp(() {
    api = FakeApi();
    repo = ApiAlertsRepository(api.client());
  });

  test('traduce la bandeja del servidor a alertas', () async {
    api.on(
      'GET $base',
      FakeReply(200, {
        'items': [
          _item('a', entityType: 'ASSET', entityId: 'g-1'),
          _item(
            'b',
            readAt: '2026-10-22T16:00:00Z',
            entityType: null,
            entityId: null,
            message: '  ',
          ),
        ],
        'total': 2,
        'page': 1,
        'pageSize': 100,
      }),
    );

    final alerts = await repo.list();

    expect(alerts, hasLength(2));
    expect(alerts[0].id, 'a');
    expect(alerts[0].title, 'Ticket vencido');
    expect(alerts[0].body, 'Algo paso');
    expect(alerts[0].read, isFalse);
    expect(alerts[0].entityType, 'ASSET');
    expect(alerts[0].entityId, 'g-1');
    expect(alerts[0].severity, AlertSeverity.info);
    expect(alerts[0].createdAt, DateTime.utc(2026, 10, 22, 15));
    // Leida, sin registro al que llevar y sin cuerpo.
    expect(alerts[1].read, isTrue);
    expect(alerts[1].entityType, isNull);
    expect(alerts[1].body, isNull);
  });

  test('pide las paginas que faltan hasta tener el total', () async {
    api.reply('GET $base', (o) {
      final page = o.queryParameters['page'] as int;
      return FakeReply(200, {
        'items': [
          for (var i = 0; i < (page == 1 ? 100 : 20); i++) _item('p$page-$i'),
        ],
        'total': 120,
        'page': page,
        'pageSize': 100,
      });
    });

    final alerts = await repo.list();

    expect(alerts, hasLength(120));
    expect(api.to('GET $base'), hasLength(2));
    expect(api.requests.first.queryParameters['pageSize'], 100);
  });

  test('sin alertas devuelve una lista vacia', () async {
    api.on('GET $base', const FakeReply(200, {'items': [], 'total': 0}));
    expect(await repo.list(), isEmpty);
  });

  test('marcar una o todas llama a las rutas del servidor', () async {
    api.on('POST $base/abc/read', const FakeReply(200, {}));
    api.on('POST $base/read-all', const FakeReply(200, {'marked': 3}));

    await repo.markRead('abc');
    await repo.markAllRead();

    expect(api.to('POST $base/abc/read'), hasLength(1));
    expect(api.to('POST $base/read-all'), hasLength(1));
  });

  test('traduce los errores del servidor', () async {
    api.on('GET $base', const FakeReply(403, {'code': 'FORBIDDEN'}));
    await expectLater(repo.list(), _fails(AlertsError.permissionDenied));

    api.on('GET $base', const FakeReply(404));
    await expectLater(repo.list(), _fails(AlertsError.notAvailable));

    api.on('GET $base', const FakeReply(500, {'title': 'x'}));
    await expectLater(repo.list(), _fails(AlertsError.server));

    api.on('GET $base', const FakeReply(200, {'items': 'mal'}));
    await expectLater(repo.list(), _fails(AlertsError.server));

    api.offline = true;
    await expectLater(repo.list(), _fails(AlertsError.network));
    await expectLater(repo.markAllRead(), _fails(AlertsError.network));
  });
}
