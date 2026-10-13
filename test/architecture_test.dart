// Hace cumplir las reglas de arquitectura (ver README.md). Si una de estas
// pruebas falla, el cambio rompe el aislamiento entre modulos o capas.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

final _import = RegExp(
  r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''',
  multiLine: true,
);

/// Archivos de lib/ (sin codigo generado) con la ruta de cada import resuelta
/// a una ruta relativa a lib/, o a `dart:...` / `package:...` si es externo.
Map<String, List<String>> _graph() {
  final result = <String, List<String>>{};
  final libUri = Directory('lib').absolute.uri;
  for (final f in Directory(
    'lib',
  ).listSync(recursive: true).whereType<File>()) {
    if (!f.path.endsWith('.dart') || f.path.contains('l10n')) continue;
    final rel = f.absolute.uri.path.substring(libUri.path.length);
    final imports = <String>[];
    for (final m in _import.allMatches(f.readAsStringSync())) {
      final target = m.group(1)!;
      if (target.startsWith('dart:')) {
        imports.add(target);
      } else if (target.startsWith('package:sigaco_movil/')) {
        imports.add(target.substring('package:sigaco_movil/'.length));
      } else if (target.startsWith('package:')) {
        imports.add(target);
      } else {
        final resolved = f.absolute.uri.resolve(target).path;
        imports.add(resolved.substring(libUri.path.length));
      }
    }
    result[rel] = imports;
  }
  return result;
}

String? _feature(String path) {
  final m = RegExp(r'^features/([^/]+)/').firstMatch(path);
  return m?.group(1);
}

String? _layer(String path) {
  final m = RegExp(
    r'^features/[^/]+/(domain|data|presentation)/',
  ).firstMatch(path);
  return m?.group(1);
}

void main() {
  final graph = _graph();

  List<String> violations(bool Function(String file, String imp) broken) => [
    for (final e in graph.entries)
      for (final imp in e.value)
        if (broken(e.key, imp)) '${e.key} -> $imp',
  ];

  test('un modulo no importa a otro modulo', () {
    final v = violations((file, imp) {
      final a = _feature(file);
      final b = _feature(imp);
      return a != null && b != null && a != b;
    });
    expect(
      v,
      isEmpty,
      reason: 'Los modulos solo comparten codigo via core/:\n${v.join('\n')}',
    );
  });

  test('core/ no depende de features/ ni de app/', () {
    final v = violations(
      (file, imp) =>
          file.startsWith('core/') &&
          (imp.startsWith('features/') || imp.startsWith('app/')),
    );
    expect(v, isEmpty, reason: v.join('\n'));
  });

  test('domain es Dart puro: sin Flutter, HTTP, data ni presentation', () {
    final v = violations((file, imp) {
      if (_layer(file) != 'domain') return false;
      if (imp.startsWith('dart:')) return false;
      if (imp.startsWith('package:equatable/')) return false;
      // Constantes de permisos: Dart puro compartido por varios modulos.
      if (imp.startsWith('core/permissions/')) return false;
      if (imp.startsWith('package:')) return true;
      return _layer(imp) != 'domain' || _feature(imp) != _feature(file);
    });
    expect(v, isEmpty, reason: v.join('\n'));
  });

  test('data no depende de presentation', () {
    final v = violations(
      (file, imp) => _layer(file) == 'data' && _layer(imp) == 'presentation',
    );
    expect(v, isEmpty, reason: v.join('\n'));
  });

  test('presentation no importa data: se compone en app/', () {
    final v = violations(
      (file, imp) => _layer(file) == 'presentation' && _layer(imp) == 'data',
    );
    expect(v, isEmpty, reason: v.join('\n'));
  });
}
