import 'package:flutter_test/flutter_test.dart';
import 'package:sigaco_movil/core/permissions/permission_keys.dart';
import 'package:sigaco_movil/features/navigation/domain/entities/mobile_module.dart';
import 'package:sigaco_movil/features/navigation/domain/entities/navigation_entities.dart';

NavigationMenu _menu(List<String> modules, List<String> permissions) =>
    NavigationMenu(
      modules: [for (final m in modules) NavigationItem(code: m, name: m)],
      permissions: permissions,
    );

/// El acceso al mapa lo decide "SIG: Ver mapa" y no el permiso de inventario
/// (DTF M10, HU-MOB-10-01); mientras el catalogo no publique el modulo SIG se
/// usa el de inventario.
void main() {
  group('mapa movil', () {
    test('con el modulo SIG manda su permiso Ver mapa', () {
      final menu = _menu(['PANEL', 'SIG'], [PermissionKeys.sigView]);
      expect(MobileModule.map.isAvailableIn(menu), isTrue);
    });

    test('con el modulo SIG, el permiso de inventario ya no basta', () {
      final menu = _menu(
        ['PANEL', 'SIG', 'INVENTARIO'],
        [PermissionKeys.inventoryView],
      );
      expect(MobileModule.map.isAvailableIn(menu), isFalse);
    });

    test('ver el mapa no exige ver el inventario', () {
      final menu = _menu(['SIG'], [PermissionKeys.sigView]);
      expect(MobileModule.map.isAvailableIn(menu), isTrue);
      expect(MobileModule.inventory.isAvailableIn(menu), isFalse);
    });

    test('sin el modulo SIG se usa el inventario, como hasta ahora', () {
      final menu = _menu(
        ['PANEL', 'INVENTARIO'],
        [PermissionKeys.inventoryView],
      );
      expect(MobileModule.map.isAvailableIn(menu), isTrue);
    });

    test('sin SIG y sin permiso de inventario no hay mapa', () {
      expect(
        MobileModule.map.isAvailableIn(_menu(['PANEL', 'INVENTARIO'], [])),
        isFalse,
      );
      expect(MobileModule.map.isAvailableIn(_menu(['PANEL'], [])), isFalse);
    });

    test('la lista de modulos del menu respeta la misma regla', () {
      final sig = _menu(['SIG', 'INVENTARIO'], [PermissionKeys.sigView]);
      expect(MobileModule.availableIn(sig), contains(MobileModule.map));
      final denied = _menu(
        ['SIG', 'INVENTARIO'],
        [PermissionKeys.inventoryView],
      );
      expect(
        MobileModule.availableIn(denied),
        isNot(contains(MobileModule.map)),
      );
    });
  });
}
