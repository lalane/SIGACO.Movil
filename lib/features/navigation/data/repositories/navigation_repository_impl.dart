import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_failure.dart';
import '../../domain/entities/navigation_entities.dart';
import '../../domain/repositories/navigation_repository.dart';

class NavigationRepositoryImpl implements NavigationRepository {
  NavigationRepositoryImpl(this._api);

  final ApiClient _api;

  @override
  Stream<void> get accessDenied => _api.accessDenied;

  @override
  Future<NavigationMenu> load() async {
    try {
      final json = await _api.get(ApiClient.accessCheckPath);
      return menuFromJson(json ?? const {});
    } on ApiFailure catch (f) {
      if (f.isNetwork) {
        throw const NavigationException(NavigationError.network);
      }
      if (f.status == 403) {
        throw NavigationException(
          f.code == 'CONTEXT_REQUIRED'
              ? NavigationError.contextRequired
              : NavigationError.permissionDenied,
        );
      }
      throw const NavigationException(NavigationError.server);
    }
  }
}

NavigationMenu menuFromJson(Map<String, dynamic> j) => NavigationMenu(
  modules: _items(j['modules']),
  permissions: [for (final p in (j['permissions'] ?? const []) as List) '$p'],
);

List<NavigationItem> _items(Object? raw) => [
  for (final e in (raw ?? const []) as List)
    NavigationItem(
      code: (e as Map<String, dynamic>)['code'] as String,
      name: (e['name'] ?? '') as String,
      permissions: [
        for (final p in (e['permissions'] ?? const []) as List) '$p',
      ],
      submodules: _items(e['submodules']),
    ),
];
