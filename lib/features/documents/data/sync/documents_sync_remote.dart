import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_failure.dart';
import '../../../../core/files/local_file_store.dart';
import '../../../../core/offline/operation.dart';
import '../../../../core/offline/sync_engine.dart';
import '../repositories/documents_repository_impl.dart';

/// Envia al servidor lo capturado en el telefono del gestor documental:
///  - `documento`: la carga (`/api/uploads`): abre la carga, manda los bloques
///    que faltan, la completa y espera a que el servidor la valide y publique;
///  - `documento_firma`: la firma de una version (HU-MOB-03-03), que antes de
///    enviarse comprueba que la version no cambio desde la captura.
///
/// Es reanudable: la clave de idempotencia de la operacion es el `uploadId`, y
/// abrir la carga otra vez devuelve la misma con sus `missingBlocks`, asi que un
/// corte de red solo repite lo que no llego.
class DocumentsSyncRemote implements SyncRemote {
  DocumentsSyncRemote(
    this._api,
    this._documents,
    this._store, {
    Future<int> Function(String path)? fileLength,
    Future<Uint8List> Function(String path, int start, int length)? readBlock,
    Future<void> Function(Duration)? delay,
  }) : _fileLength = fileLength ?? _diskLength,
       _readBlock = readBlock ?? _diskBlock,
       _delay = delay ?? Future<void>.delayed;

  final ApiClient _api;
  final DocumentsRepositoryImpl _documents;
  final LocalFileStore _store;
  final Future<int> Function(String path) _fileLength;
  final Future<Uint8List> Function(String path, int start, int length)
  _readBlock;
  final Future<void> Function(Duration) _delay;

  /// Cuanto se espera, en total, a que el servidor termine de validar antes de
  /// dejarlo para la siguiente pasada.
  static const _validationPolls = 8;
  static const _validationWait = Duration(seconds: 2);

  static Future<int> _diskLength(String path) => File(path).length();

  static Future<Uint8List> _diskBlock(
    String path,
    int start,
    int length,
  ) async {
    final file = await File(path).open();
    try {
      await file.setPosition(start);
      return await file.read(length);
    } finally {
      await file.close();
    }
  }

  @override
  Future<SyncOutcome> send(PendingOperation operation) {
    if (operation.kind == OperationKind.insert) {
      switch (operation.entity) {
        case 'documento':
          return _sendDocument(operation);
        case 'documento_firma':
          return _sendSignature(operation);
      }
    }
    return Future.value(
      SyncRejected(
        'La app no sabe enviar «${operation.entity}» (${operation.kind.name})',
      ),
    );
  }

  /// La firma de una version (DTF M03 §3.2): la operacion guarda el documento,
  /// la version, su hash y la version base que se veia al capturarla. Si el
  /// documento ya tiene otra version vigente o el archivo cambio, la firma no se
  /// aplica y queda en conflicto; nunca se firma en silencio otra cosa. El
  /// servidor valida ademas permiso, estado y hash, y repetir la firma de la
  /// misma persona no crea otra.
  Future<SyncOutcome> _sendSignature(PendingOperation operation) async {
    final documentId = operation.recordId;
    final versionId = operation.payload['versionId'] as String?;
    if (documentId == null || versionId == null || versionId.isEmpty) {
      return const SyncRejected('Falta el documento o la version a firmar');
    }
    try {
      // El historial no cuenta como abrir el documento (no altera «Recientes»).
      final versions = await _api.getJson(
        '/api/documents/$documentId/versions',
      );
      Map<String, dynamic>? current;
      if (versions is List) {
        for (final v in versions) {
          if (v is Map<String, dynamic> && v['isCurrent'] == true) current = v;
        }
      }
      if (current != null) {
        final number = (current['number'] as num?)?.toInt();
        final checksum = current['checksum'] as String?;
        final captured = operation.payload['checksum'] as String?;
        final baseChanged =
            operation.baseVersion != null &&
            number != null &&
            number != operation.baseVersion;
        final fileChanged =
            current['id'] == versionId &&
            captured != null &&
            captured.isNotEmpty &&
            checksum != null &&
            checksum != captured;
        if (baseChanged || fileChanged) {
          return SyncConflicted(
            serverVersion: number,
            serverPayload: {
              'name': operation.payload['name'],
              'version': number == null ? null : 'V$number',
              'versionId': current['id'],
              'checksum': checksum,
            },
            message: baseChanged
                ? 'El documento ya tiene otra version vigente (V$number).'
                : 'El archivo de la version cambio desde que se capturo la firma.',
          );
        }
      }
      final result = await _api.post(
        '/api/documents/$documentId/versions/$versionId/signature',
      );
      return SyncAccepted(
        response: {
          'signatureStatus': result?['signatureStatus'],
          'alreadySigned': result?['alreadySigned'],
        },
      );
    } on ApiFailure catch (f) {
      return _outcomeFor(f);
    } on FormatException {
      return const SyncRetryLater('Respuesta inesperada del servidor');
    }
  }

  Future<SyncOutcome> _sendDocument(PendingOperation operation) async {
    final payload = operation.payload;
    final path = payload['localPath'] as String?;
    final name = payload['name'] as String?;
    if (path == null || name == null) {
      return const SyncRejected('Falta el archivo de la captura');
    }
    final int length;
    try {
      length = await _fileLength(path);
    } on FileSystemException {
      return const SyncRejected('El archivo ya no esta en el telefono');
    }

    try {
      final folder = payload['folder'] as String?;
      final typeCode = payload['typeCode'] as String?;
      final categoryCode = payload['categoryCode'] as String?;
      final target = await _documents.resolveUploadTarget(
        typeCode: typeCode,
        categoryCode: categoryCode,
        folder: folder,
      );
      if (typeCode != null && target.typeId == null) {
        return const SyncRejected('El tipo de documento ya no existe');
      }
      if (categoryCode != null && target.categoryId == null) {
        return const SyncRejected('La categoria ya no existe');
      }
      if (folder != null && target.folderId == null) {
        return const SyncRejected('La carpeta ya no existe');
      }
      final description = (payload['description'] as String?)?.trim();

      var upload = _Upload.from(
        await _api.post(
          '/api/uploads',
          data: {
            'uploadId': operation.id,
            'fileName': name,
            'sizeBytes': length,
            'folderId': target.folderId,
            'typeId': target.typeId,
            'categoryId': target.categoryId,
            'description': description == null || description.isEmpty
                ? null
                : description,
          },
        ),
      );

      if (upload.status == 'TRANSFIRIENDO') {
        await _sendMissingBlocks(upload, path, length);
        upload = _Upload.from(
          await _api.post('/api/uploads/${operation.id}/complete'),
        );
      }
      for (
        var i = 0;
        upload.status == 'VALIDANDO' && i < _validationPolls;
        i++
      ) {
        await _delay(_validationWait);
        upload = _Upload.from(
          await _api.getJson('/api/uploads/${operation.id}'),
        );
      }
      return await _finish(upload, path);
    } on ApiFailure catch (f) {
      return _outcomeFor(f);
    } on FileSystemException {
      return const SyncRejected('No se pudo leer el archivo del telefono');
    } on FormatException {
      return const SyncRetryLater('Respuesta inesperada del servidor');
    }
  }

  Future<void> _sendMissingBlocks(
    _Upload upload,
    String path,
    int length,
  ) async {
    if (upload.blockSize <= 0) throw const FormatException('blockSize');
    for (final index in upload.missingBlocks) {
      final start = index * upload.blockSize;
      final size = min(upload.blockSize, length - start);
      if (size <= 0) continue;
      final bytes = await _readBlock(path, start, size);
      await _api.putBytes('/api/uploads/${upload.id}/blocks/$index', bytes);
    }
  }

  Future<SyncOutcome> _finish(_Upload upload, String path) async {
    switch (upload.status) {
      case 'COMPLETADO':
        // Ya esta en el servidor: la copia del telefono no hace falta.
        await _store.remove(path);
        return SyncAccepted(
          response: {
            'documentId': upload.documentId,
            'versionId': upload.versionId,
            'publishedName': upload.publishedName,
          },
        );
      case 'RECHAZADO':
        return SyncRejected(
          upload.rejectionMessage ?? 'El servidor rechazo el documento',
          code: upload.rejectionCode,
        );
      case 'CANCELADO':
        return const SyncRejected('La carga fue cancelada');
      case 'EXPIRADO':
        return const SyncRejected(
          'La carga expiro antes de terminar; vuelve a cargar el documento',
        );
      case 'FALLIDO':
        return const SyncRejected('El servidor no pudo publicar el documento');
      default:
        // Sigue validando o en un estado que aun no se conoce.
        return const SyncRetryLater(
          'El servidor sigue validando el documento',
          retryAfter: Duration(seconds: 15),
        );
    }
  }

  static SyncOutcome _outcomeFor(ApiFailure f) {
    if (f.isNetwork) {
      return const SyncRetryLater('Sin conexion con el servidor');
    }
    final status = f.status ?? 0;
    if (status == 401) return const SyncSessionLost();
    if (status >= 500 || status == 408 || status == 429) {
      return SyncRetryLater('Error pasajero del servidor ($status)');
    }
    // Faltan bloques: se repite la pasada y se mandan los que falten.
    if (f.code == 'UPLOAD_INCOMPLETE') {
      return const SyncRetryLater('Faltaban bloques por enviar');
    }
    final fieldMessage = f.fieldErrors.values
        .expand((m) => m)
        .cast<String?>()
        .firstWhere((m) => m != null && m.isNotEmpty, orElse: () => null);
    return SyncRejected(
      fieldMessage ?? f.message ?? 'El servidor rechazo la carga ($status)',
      code: f.code,
    );
  }
}

class _Upload {
  const _Upload({
    required this.id,
    required this.status,
    required this.blockSize,
    required this.missingBlocks,
    this.documentId,
    this.versionId,
    this.publishedName,
    this.rejectionCode,
    this.rejectionMessage,
  });

  factory _Upload.from(Object? json) {
    if (json is! Map<String, dynamic>) {
      throw const FormatException('Respuesta inesperada');
    }
    return _Upload(
      id: json['uploadId'] as String,
      status: json['status'] as String,
      blockSize: (json['blockSize'] as num?)?.toInt() ?? 0,
      missingBlocks: [
        for (final i in (json['missingBlocks'] as List? ?? const []))
          (i as num).toInt(),
      ],
      documentId: json['documentId'] as String?,
      versionId: json['versionId'] as String?,
      publishedName: json['publishedName'] as String?,
      rejectionCode: json['rejectionCode'] as String?,
      rejectionMessage: json['rejectionMessage'] as String?,
    );
  }

  final String id;
  final String status;
  final int blockSize;
  final List<int> missingBlocks;
  final String? documentId;
  final String? versionId;
  final String? publishedName;
  final String? rejectionCode;
  final String? rejectionMessage;
}
