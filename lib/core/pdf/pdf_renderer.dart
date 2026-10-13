import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../offline/uuid.dart';

/// Tamano de una pagina, en puntos del PDF.
class PdfPageSize extends Equatable {
  const PdfPageSize(this.width, this.height);

  final double width;
  final double height;

  double get aspectRatio => height <= 0 ? 1 : width / height;

  @override
  List<Object?> get props => [width, height];
}

/// Un PDF abierto para dibujar sus paginas.
class PdfDocumentHandle extends Equatable {
  const PdfDocumentHandle(this.id, this.pages);

  final String id;
  final List<PdfPageSize> pages;

  @override
  List<Object?> get props => [id, pages];
}

/// Dibuja las paginas de un PDF como imagenes. Solo para ver: no entrega el
/// archivo ni lo guarda mas alla de la vista previa.
abstract interface class PdfRenderer {
  /// Abre el PDF. Lanza si no se puede leer (danado, con contrasena).
  Future<PdfDocumentHandle> open(Uint8List bytes);

  /// La pagina [index] (desde 0), de [width] pixeles de ancho, como imagen.
  Future<Uint8List> renderPage(
    PdfDocumentHandle document,
    int index, {
    required int width,
  });

  /// Libera el PDF y borra lo que se guardo para abrirlo.
  Future<void> close(PdfDocumentHandle document);
}

/// Sin visor (pruebas y plataformas sin soporte): abrir falla y la pantalla lo
/// dice como «sin vista previa».
class NoPdfRenderer implements PdfRenderer {
  const NoPdfRenderer();

  @override
  Future<PdfDocumentHandle> open(Uint8List bytes) async =>
      throw UnsupportedError('Este dispositivo no muestra PDF');

  @override
  Future<Uint8List> renderPage(
    PdfDocumentHandle document,
    int index, {
    required int width,
  }) async => throw UnsupportedError('Este dispositivo no muestra PDF');

  @override
  Future<void> close(PdfDocumentHandle document) async {}
}

/// `PdfRenderer` de Android, por un canal propio (`android/.../PdfChannel.kt`).
/// El sistema solo abre PDF desde un archivo: se escribe en la cache de la app
/// mientras dura la vista previa y se borra al cerrarla.
class PlatformPdfRenderer implements PdfRenderer {
  PlatformPdfRenderer({Future<Directory> Function()? cacheDir})
    : _cacheDir = cacheDir ?? getTemporaryDirectory;

  static const _channel = MethodChannel('sigaco/pdf');

  final Future<Directory> Function() _cacheDir;

  @override
  Future<PdfDocumentHandle> open(Uint8List bytes) async {
    final dir = Directory(p.join((await _cacheDir()).path, 'pdf_preview'));
    await dir.create(recursive: true);
    final file = File(p.join(dir.path, '${newUuid()}.pdf'));
    await file.writeAsBytes(bytes, flush: true);
    try {
      final result = await _channel.invokeMapMethod<String, Object?>('open', {
        'path': file.path,
      });
      final pages = [
        for (final size in (result?['pages'] as List? ?? const []))
          PdfPageSize(
            ((size as List)[0] as num).toDouble(),
            (size[1] as num).toDouble(),
          ),
      ];
      if (pages.isEmpty) throw const FormatException('PDF sin paginas');
      return PdfDocumentHandle(file.path, pages);
    } catch (_) {
      await _delete(file.path);
      rethrow;
    }
  }

  @override
  Future<Uint8List> renderPage(
    PdfDocumentHandle document,
    int index, {
    required int width,
  }) async {
    final bytes = await _channel.invokeMethod<Uint8List>('render', {
      'path': document.id,
      'page': index,
      'width': width,
    });
    if (bytes == null) throw const FormatException('Pagina vacia');
    return bytes;
  }

  @override
  Future<void> close(PdfDocumentHandle document) async {
    try {
      await _channel.invokeMethod<void>('close', {'path': document.id});
    } catch (_) {
      // Se borra de todos modos.
    }
    await _delete(document.id);
  }

  static Future<void> _delete(String path) async {
    try {
      await File(path).delete();
    } catch (_) {}
  }
}
