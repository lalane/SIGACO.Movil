import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sigaco_movil/features/navigation/data/repositories/navigation_repository_impl.dart';
import 'package:sigaco_movil/features/navigation/domain/entities/mobile_module.dart';
import 'package:sigaco_movil/features/navigation/domain/entities/navigation_entities.dart';
import 'package:sigaco_movil/features/navigation/presentation/bloc/navigation_bloc.dart';

import '../../support/fakes.dart';

void main() {
  group('modulos moviles segun el menu del backend', () {
    test('un menu vacio no muestra ninguno', () {
      expect(MobileModule.availableIn(const NavigationMenu()), isEmpty);
    });

    test('cada modulo del catalogo habilita su tarjeta', () {
      final menu = menuWith([
        'PANEL',
        'TICKETS',
        'MANTENIMIENTO',
        'INVENTARIO',
        'REPORTES',
        'ALERTAS_OPERATIVAS',
      ]);
      expect(
        MobileModule.availableIn(menu),
        containsAll([
          MobileModule.dashboard,
          MobileModule.tickets,
          MobileModule.maintenance,
          MobileModule.inventory,
          MobileModule.reports,
          MobileModule.alerts,
          MobileModule.map,
        ]),
      );
      expect(
        MobileModule.availableIn(menu),
        isNot(contains(MobileModule.accidents)),
      );
    });

    test('accidentes sale del submodulo ANTT.ACCIDENTES', () {
      const menu = NavigationMenu(
        modules: [
          NavigationItem(
            code: 'ANTT',
            name: 'ANTT',
            submodules: [
              NavigationItem(code: 'ANTT.ACCIDENTES', name: 'Accidentes'),
            ],
          ),
        ],
      );
      expect(MobileModule.availableIn(menu), [MobileModule.accidents]);
    });

    test('Configuracion > Usuarios nunca se convierte en tarjeta movil', () {
      final menu = menuWith(['USUARIOS']);
      expect(MobileModule.availableIn(menu), isEmpty);
    });
  });

  group('contrato JSON de /api/context/navigation', () {
    test('interpreta modulos, submodulos y permisos', () {
      final menu = menuFromJson({
        'concession': {'id': 'c1', 'code': 'C1', 'name': 'N'},
        'modules': [
          {
            'code': 'MANTENIMIENTO',
            'level': 'MODULE',
            'name': 'Mantenimiento',
            'routeResource': null,
            'permissions': ['MANTENIMIENTO:R'],
            'submodules': [
              {
                'code': 'MANTENIMIENTO.NUEVO_TICKET',
                'level': 'SUBMODULE',
                'name': 'Nuevo ticket',
                'permissions': ['MANTENIMIENTO.NUEVO_TICKET:C'],
                'submodules': <dynamic>[],
              },
            ],
          },
        ],
        'permissions': ['MANTENIMIENTO:R', 'MANTENIMIENTO.NUEVO_TICKET:C'],
      });
      expect(menu.has('MANTENIMIENTO'), isTrue);
      expect(menu.has('MANTENIMIENTO.NUEVO_TICKET'), isTrue);
      expect(menu.has('USUARIOS'), isFalse);
      expect(menu.permissions, hasLength(2));
    });
  });

  group('NavigationBloc', () {
    blocTest<NavigationBloc, NavigationState>(
      'carga el menu',
      build: () => NavigationBloc(FakeNavigationRepository()),
      act: (b) => b.add(const NavigationRequested()),
      wait: const Duration(milliseconds: 10),
      verify: (b) {
        expect(b.state.status, NavigationStatus.ready);
        expect(b.state.menu.has('PANEL'), isTrue);
      },
    );

    blocTest<NavigationBloc, NavigationState>(
      'informa el error y permite reintentar',
      build: () => NavigationBloc(
        FakeNavigationRepository(failure: NavigationError.network),
      ),
      act: (b) => b.add(const NavigationRequested()),
      wait: const Duration(milliseconds: 10),
      verify: (b) {
        expect(b.state.status, NavigationStatus.failure);
        expect(b.state.error, NavigationError.network);
      },
    );

    blocTest<NavigationBloc, NavigationState>(
      'al limpiar no queda nada del ambiente anterior',
      build: () => NavigationBloc(FakeNavigationRepository()),
      act: (b) async {
        b.add(const NavigationRequested());
        await Future<void>.delayed(const Duration(milliseconds: 10));
        b.add(const NavigationCleared());
      },
      wait: const Duration(milliseconds: 10),
      verify: (b) {
        expect(b.state.status, NavigationStatus.idle);
        expect(b.state.menu.modules, isEmpty);
      },
    );
  });
}
