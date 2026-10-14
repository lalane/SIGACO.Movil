import 'package:flutter_test/flutter_test.dart';
import 'package:sigaco_movil/core/offline/operation.dart';
import 'package:sigaco_movil/core/session/session_scope.dart';

class _Cleaner implements ScopeCleaner {
  _Cleaner({this.fail = false});

  final bool fail;
  int cleared = 0;

  @override
  Future<void> clear() async {
    cleared++;
    if (fail) throw StateError('no se pudo');
  }
}

class _Bound extends _Cleaner implements ScopeBound {
  final bound = <OfflineScope?>[];

  @override
  Future<void> bind(OfflineScope? scope) async => bound.add(scope);
}

const _scope = OfflineScope(userId: 'ana', concessionId: 'c1');

/// Lo local es de una persona y una concesion (RN-CTX-02, DEV-MOB-045).
void main() {
  test('vacia todo lo registrado', () async {
    final a = _Cleaner();
    final b = _Bound();
    final scope = SessionScope()
      ..register(a)
      ..register(b);

    await scope.clear();

    expect(a.cleared, 1);
    expect(b.cleared, 1);
  });

  test('un fallo al vaciar uno no impide vaciar los demas', () async {
    final broken = _Cleaner(fail: true);
    final ok = _Cleaner();
    final scope = SessionScope()
      ..register(broken)
      ..register(ok);

    await scope.clear();

    expect(broken.cleared, 1);
    expect(ok.cleared, 1);
  });

  test('fija el alcance solo en los caches que lo necesitan', () async {
    final plain = _Cleaner();
    final bound = _Bound();
    final scope = SessionScope()
      ..register(plain)
      ..register(bound);

    await scope.bind(_scope);
    await scope.bind(null);

    expect(bound.bound, [_scope, null]);
    expect(plain.cleared, 0);
  });

  test('un fallo al fijar el alcance no detiene a los demas', () async {
    final scope = SessionScope()
      ..register(_ThrowingBound())
      ..register(_Bound());
    final last = _Bound();
    scope.register(last);

    await scope.bind(_scope);

    expect(last.bound, [_scope]);
  });
}

class _ThrowingBound extends _Cleaner implements ScopeBound {
  @override
  Future<void> bind(OfflineScope? scope) async => throw StateError('x');
}
