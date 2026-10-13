import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sigaco_movil/core/pdf/pdf_renderer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory cache;
  late PlatformPdfRenderer renderer;
  final calls = <MethodCall>[];
  Object? Function(MethodCall call)? handler;

  setUp(() async {
    cache = await Directory.systemTemp.createTemp('pdf_test');
    renderer = PlatformPdfRenderer(cacheDir: () async => cache);
    calls.clear();
    handler = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('sigaco/pdf'), (
          call,
        ) async {
          calls.add(call);
          return handler?.call(call);
        });
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('sigaco/pdf'), null);
    await cache.delete(recursive: true);
  });

  List<File> files() => Directory(
    '${cache.path}/pdf_preview',
  ).listSync().whereType<File>().toList();

  test(
    'abre el PDF desde un archivo propio y devuelve el tamano de cada pagina',
    () async {
      handler = (call) => {
        'pages': [
          [595.0, 842.0],
          [842, 595],
        ],
      };

      final doc = await renderer.open(Uint8List.fromList([37, 80, 68, 70]));

      expect(calls.single.method, 'open');
      expect(calls.single.arguments['path'], doc.id);
      expect(File(doc.id).readAsBytesSync(), [37, 80, 68, 70]);
      expect(doc.pages, [
        const PdfPageSize(595, 842),
        const PdfPageSize(842, 595),
      ]);
      expect(doc.pages.last.aspectRatio, closeTo(1.41, 0.01));
    },
  );

  test('pide una pagina con el ancho dado', () async {
    handler = (call) => call.method == 'open'
        ? {
            'pages': [
              [100.0, 100.0],
            ],
          }
        : Uint8List.fromList([1, 2, 3]);
    final doc = await renderer.open(Uint8List(1));

    final bytes = await renderer.renderPage(doc, 0, width: 800);

    expect(bytes, [1, 2, 3]);
    expect(calls.last.method, 'render');
    expect(calls.last.arguments, {'path': doc.id, 'page': 0, 'width': 800});
  });

  test('al cerrar borra el archivo', () async {
    handler = (call) => {
      'pages': [
        [100.0, 100.0],
      ],
    };
    final doc = await renderer.open(Uint8List(1));
    expect(files(), hasLength(1));

    await renderer.close(doc);

    expect(calls.last.method, 'close');
    expect(files(), isEmpty);
  });

  test('si no se puede abrir, no deja el archivo y falla', () async {
    handler = (call) => throw PlatformException(code: 'PDF_ERROR');

    await expectLater(
      renderer.open(Uint8List(1)),
      throwsA(isA<PlatformException>()),
    );
    expect(files(), isEmpty);
  });

  test('un PDF sin paginas se trata como danado', () async {
    handler = (call) => {'pages': <Object>[]};

    await expectLater(
      renderer.open(Uint8List(1)),
      throwsA(isA<FormatException>()),
    );
    expect(files(), isEmpty);
  });
}
