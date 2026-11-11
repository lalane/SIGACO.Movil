import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_failure.dart';
import '../../domain/entities/pending_definition.dart';
import '../../domain/repositories/definitions_repository.dart';

/// Las definiciones pendientes contra el backend (`/api/definitions`, tanda 4).
/// El servidor dice que puede hacer cada quien (`permissions`).
class ApiDefinitionsRepository implements DefinitionsRepository {
  ApiDefinitionsRepository(this._api);

  final ApiClient _api;

  @override
  Future<DefinitionPage> list({String? mobileModule}) => _guard(() async {
    final json = _asMap(
      await _api.getJson(
        '/api/definitions',
        query: {'mobileModule': mobileModule},
      ),
    );
    final items = json['items'];
    if (items is! List) throw const FormatException('sin items');
    return DefinitionPage(
      items: [for (final i in items) definitionFromDto(_asMap(i))],
      permissions: permissionsFromDto(json['permissions']),
    );
  });

  @override
  Future<DefinitionDetail> get(String code) => _guard(
    () async => detailFromDto(
      _asMap(
        await _api.getJson('/api/definitions/${Uri.encodeComponent(code)}'),
      ),
    ),
  );

  @override
  Future<DefinitionDetail> answer(
    String code,
    DefinitionAnswerKind kind, {
    String? text,
  }) => _guard(() async {
    final trimmed = text?.trim();
    final json = await _api.post(
      '/api/definitions/${Uri.encodeComponent(code)}/answer',
      data: {
        'kind': kind.code,
        'text': trimmed == null || trimmed.isEmpty ? null : trimmed,
      },
    );
    if (json == null) throw const FormatException('sin respuesta');
    return detailFromDto(json);
  });

  static DefinitionDetail detailFromDto(Map<String, dynamic> m) {
    final history = m['history'];
    return DefinitionDetail(
      definition: definitionFromDto(_asMap(m['definition'])),
      history: [
        if (history is List)
          for (final h in history) answerFromDto(_asMap(h)),
      ],
      permissions: permissionsFromDto(m['permissions']),
    );
  }

  static PendingDefinition definitionFromDto(Map<String, dynamic> m) {
    final last = m['lastAnswer'];
    return PendingDefinition(
      code: _text(m['code']) ?? '',
      module: _text(m['module']) ?? '',
      moduleLabel: _text(m['moduleLabel']) ?? _text(m['module']) ?? '',
      indicator: _text(m['indicator']),
      title: _text(m['title']) ?? '',
      question: _text(m['question']) ?? '',
      assumption: _text(m['assumption']) ?? '',
      ifVetoed: _text(m['ifVetoed']) ?? '',
      source: _text(m['source']) ?? '',
      priority: DefinitionPriority.fromCode(_text(m['priority'])),
      status: DefinitionStatus.fromCode(_text(m['status'])),
      mobileModule: _text(m['mobileModule']),
      answerCount: (m['answerCount'] as num?)?.toInt() ?? 0,
      lastAnswer: last is Map<String, dynamic> ? answerFromDto(last) : null,
    );
  }

  static DefinitionAnswer answerFromDto(Map<String, dynamic> m) {
    final previous = _text(m['previousStatus']);
    return DefinitionAnswer(
      kind: _text(m['kind']) ?? '',
      text: _text(m['text']),
      previousStatus: previous == null
          ? null
          : DefinitionStatus.fromCode(previous),
      newStatus: DefinitionStatus.fromCode(_text(m['newStatus'])),
      userName: _text(m['userName']),
      profileName: _text(m['profileName']),
      fromApp: _text(m['client']) == 'MOBILE',
      createdAt:
          DateTime.tryParse(_text(m['createdAt']) ?? '')?.toUtc() ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }

  static DefinitionPermissions permissionsFromDto(Object? v) {
    if (v is! Map<String, dynamic>) return const DefinitionPermissions();
    return DefinitionPermissions(
      canComment: v['canComment'] == true,
      canDecide: v['canDecide'] == true,
      canReopen: v['canReopen'] == true,
    );
  }

  static String? _text(Object? v) {
    if (v is! String) return null;
    final t = v.trim();
    return t.isEmpty ? null : t;
  }

  static Map<String, dynamic> _asMap(Object? v) {
    if (v is Map<String, dynamic>) return v;
    throw const FormatException('respuesta inesperada');
  }

  Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on ApiFailure catch (e) {
      throw DefinitionsException(
        e.isNetwork
            ? DefinitionsError.network
            : switch (e.status) {
                400 => DefinitionsError.validation,
                403 => DefinitionsError.permissionDenied,
                404 => DefinitionsError.notFound,
                422 when e.code == 'DEFINITION_RETIRED' =>
                  DefinitionsError.retired,
                _ => DefinitionsError.server,
              },
        e.message,
      );
    } on DefinitionsException {
      rethrow;
    } catch (_) {
      throw const DefinitionsException(DefinitionsError.server);
    }
  }
}
