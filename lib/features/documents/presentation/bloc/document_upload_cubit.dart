import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/files/file_source.dart';
import '../../../../core/files/local_file_store.dart';
import '../../../../core/files/picked_file.dart';
import '../../../../core/offline/operation.dart';
import '../../../../core/offline/sync_cubit.dart';
import '../../domain/entities/document_catalogs.dart';
import '../../domain/entities/document_upload.dart';
import '../../domain/repositories/documents_repository.dart';

enum UploadStatus { editing, saving, done }

class DocumentUploadState extends Equatable {
  const DocumentUploadState({
    this.items = const [],
    this.metadata = const UploadMetadata(),
    this.catalogs = const DocumentCatalogs(),
    this.status = UploadStatus.editing,
    this.showErrors = false,
    this.saved = 0,
    this.saveFailed = false,
  });

  final List<UploadItem> items;
  final UploadMetadata metadata;
  final DocumentCatalogs catalogs;
  final UploadStatus status;

  /// Se muestran los errores de lo capturado (despues del primer intento de guardar).
  final bool showErrors;

  /// Cuantos documentos quedaron guardados en el telefono.
  final int saved;

  /// Al menos un archivo no se pudo guardar en el telefono; sigue en el formulario.
  final bool saveFailed;

  /// Problemas de cada archivo, en el orden de [items].
  List<List<UploadIssue>> get itemIssues => [
    for (final i in items) DocumentUploadRules.itemIssues(i),
  ];

  List<UploadIssue> get metadataIssues =>
      DocumentUploadRules.metadataIssues(metadata);

  bool get hasIssues =>
      items.isEmpty ||
      itemIssues.any((l) => l.isNotEmpty) ||
      metadataIssues.isNotEmpty;

  DocumentUploadState copyWith({
    List<UploadItem>? items,
    UploadMetadata? metadata,
    DocumentCatalogs? catalogs,
    UploadStatus? status,
    bool? showErrors,
    int? saved,
    bool? saveFailed,
  }) => DocumentUploadState(
    items: items ?? this.items,
    metadata: metadata ?? this.metadata,
    catalogs: catalogs ?? this.catalogs,
    status: status ?? this.status,
    showErrors: showErrors ?? this.showErrors,
    saved: saved ?? this.saved,
    saveFailed: saveFailed ?? this.saveFailed,
  );

  @override
  List<Object?> get props => [
    items,
    metadata,
    catalogs,
    status,
    showErrors,
    saved,
    saveFailed,
  ];
}

/// Carga de uno o varios documentos (DEV-MOB-072, 073, 082 y 083).
///
/// Nada se sube directo: cada archivo se copia al telefono y entra a la cola
/// con su propia clave de idempotencia; el sincronizador lo envia cuando hay red.
/// El documento no existe en el servidor hasta que este lo acepte
/// (HU-MOB-03-02, reglas 6 y 7), asi que esta pantalla nunca dice «cargado», solo
/// «guardado en el dispositivo».
class DocumentUploadCubit extends Cubit<DocumentUploadState> {
  DocumentUploadCubit({
    required this.repository,
    required this.sync,
    required this.files,
    required this.store,
  }) : super(const DocumentUploadState());

  final DocumentsRepository repository;
  final SyncCubit sync;
  final FileSource files;
  final LocalFileStore store;

  /// Los catalogos ofrecen los tipos y categorias; sin red, el formulario no se
  /// puede completar (el tipo es obligatorio) y se avisa al guardar.
  Future<void> loadCatalogs() async {
    try {
      final catalogs = await repository.catalogs();
      if (!isClosed) emit(state.copyWith(catalogs: catalogs));
    } catch (_) {}
  }

  Future<void> pickFiles() async => _add(await files.pickFiles());

  Future<void> takePhoto() async {
    final shot = await files.takePhoto();
    if (shot != null) _add([shot]);
  }

  void _add(List<SelectedFile> picked) {
    if (isClosed || picked.isEmpty) return;
    final known = {for (final i in state.items) i.path};
    emit(
      state.copyWith(
        items: [
          ...state.items,
          for (final f in picked)
            if (!known.contains(f.path))
              UploadItem.fromFile(
                path: f.path,
                fileName: f.name,
                sizeBytes: f.sizeBytes,
              ),
        ],
      ),
    );
  }

  void removeAt(int index) {
    if (index < 0 || index >= state.items.length) return;
    emit(
      state.copyWith(
        items: [
          for (var i = 0; i < state.items.length; i++)
            if (i != index) state.items[i],
        ],
      ),
    );
  }

  void rename(int index, String baseName) {
    if (index < 0 || index >= state.items.length) return;
    emit(
      state.copyWith(
        items: [
          for (var i = 0; i < state.items.length; i++)
            i == index ? state.items[i].withBaseName(baseName) : state.items[i],
        ],
      ),
    );
  }

  void setType(String? code) => emit(
    state.copyWith(
      metadata: UploadMetadata(
        typeCode: code,
        categoryCode: state.metadata.categoryCode,
        description: state.metadata.description,
        folder: state.metadata.folder,
      ),
    ),
  );

  void setCategory(String? code) => emit(
    state.copyWith(
      metadata: UploadMetadata(
        typeCode: state.metadata.typeCode,
        categoryCode: code,
        description: state.metadata.description,
        folder: state.metadata.folder,
      ),
    ),
  );

  void setDescription(String text) => emit(
    state.copyWith(
      metadata: UploadMetadata(
        typeCode: state.metadata.typeCode,
        categoryCode: state.metadata.categoryCode,
        description: text,
        folder: state.metadata.folder,
      ),
    ),
  );

  void setFolder(String? folder) => emit(
    state.copyWith(
      metadata: UploadMetadata(
        typeCode: state.metadata.typeCode,
        categoryCode: state.metadata.categoryCode,
        description: state.metadata.description,
        folder: folder,
      ),
    ),
  );

  /// Guarda en el telefono y encola. Si algo de lo capturado no es valido no
  /// guarda nada y muestra los errores, conservando lo escrito (MQ-MOB-17).
  /// Un archivo que no se pudo guardar se queda en el formulario; los demas
  /// quedan guardados.
  Future<void> submit() async {
    if (state.status == UploadStatus.saving) return;
    if (state.hasIssues) {
      emit(state.copyWith(showErrors: true));
      return;
    }
    emit(
      state.copyWith(
        status: UploadStatus.saving,
        showErrors: false,
        saveFailed: false,
      ),
    );
    final remaining = <UploadItem>[];
    var saved = state.saved;
    final meta = state.metadata;
    for (final item in state.items) {
      String? kept;
      try {
        kept = await store.keep(item.path, name: item.name);
        final operation = await sync.enqueue(
          entity: 'documento',
          kind: OperationKind.insert,
          payload: {
            'name': item.name,
            'typeCode': meta.typeCode,
            'categoryCode': meta.categoryCode,
            'description': meta.description.trim(),
            'folder': meta.folder,
            'format': item.format,
            'sizeBytes': item.sizeBytes,
            'localPath': kept,
          },
          capturedAt: DateTime.now().toUtc(),
        );
        if (operation == null) throw StateError('sin cola');
        saved++;
      } catch (_) {
        // No quedo en la cola: no debe quedar el archivo huerfano.
        if (kept != null) await store.remove(kept);
        remaining.add(item);
      }
      if (isClosed) return;
    }
    emit(
      state.copyWith(
        items: remaining,
        status: remaining.isEmpty ? UploadStatus.done : UploadStatus.editing,
        saved: saved,
        saveFailed: remaining.isNotEmpty,
        showErrors: remaining.isNotEmpty,
      ),
    );
  }
}
