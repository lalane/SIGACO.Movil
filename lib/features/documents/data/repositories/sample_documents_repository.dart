import '../../domain/entities/document.dart';
import '../../domain/entities/document_catalogs.dart';
import '../../domain/entities/document_query.dart';
import '../../domain/repositories/documents_repository.dart';

/// Documentos de ejemplo en memoria, con las reglas de consulta del servidor
/// (HU-MOB-03-01) para poder ver y probar las pantallas antes de que exista el
/// backend. No se usa en la app salvo con `--dart-define=SAMPLE_DOCUMENTS=true`.
class SampleDocumentsRepository implements DocumentsRepository {
  SampleDocumentsRepository({
    DateTime Function()? clock,
    this.me = 'amartinez',
    this.latency = Duration.zero,
    List<DocumentDetail>? documents,
    Map<String, DateTime>? activity,
  }) : _clock = clock ?? DateTime.now {
    final now = _clock().toUtc();
    _documents = {
      for (final d in documents ?? _sampleDocuments(now)) d.summary.id: d,
    };
    _activity = activity ?? _sampleActivity(now);
  }

  final DateTime Function() _clock;

  /// Usuario de la sesion: dueño de «Mis documentos».
  final String me;
  final Duration latency;

  late final Map<String, DocumentDetail> _documents;

  /// Ultima actividad propia por documento (abrir, cargar, modificar...).
  late final Map<String, DateTime> _activity;

  /// Si no es null, la siguiente llamada falla con este error (para pruebas y
  /// para ver los estados de error en la app de ejemplo).
  DocumentsError? failNextWith;

  Future<void> _wait() async {
    if (latency > Duration.zero) await Future<void>.delayed(latency);
    final error = failNextWith;
    if (error != null) {
      failNextWith = null;
      throw DocumentsException(error);
    }
  }

  @override
  Future<List<DocumentSummary>> list(DocumentQuery query) async {
    await _wait();
    var rows = [for (final d in _documents.values) d];

    switch (query.view) {
      case DocumentView.all:
        break;
      case DocumentView.mine:
        rows = [
          for (final d in rows)
            if (d.summary.ownerUsername == me) d,
        ];
      case DocumentView.favorites:
        rows = [
          for (final d in rows)
            if (d.summary.isFavorite) d,
        ];
      case DocumentView.recent:
        final limit = _clock().toUtc().subtract(const Duration(days: 30));
        rows = [
          for (final d in rows)
            if (_activity[d.summary.id]?.isAfter(limit) ?? false) d,
        ];
        rows.sort(
          (a, b) =>
              _activity[b.summary.id]!.compareTo(_activity[a.summary.id]!),
        );
        if (rows.length > 50) rows = rows.sublist(0, 50);
    }

    final needle = query.search.trim().toLowerCase();
    final f = query.filters;
    rows = [
      for (final d in rows)
        if (_matches(d, needle, f)) d,
    ];

    if (query.view != DocumentView.recent) {
      rows.sort((a, b) => b.summary.modifiedAt.compareTo(a.summary.modifiedAt));
    }
    return [for (final d in rows) d.summary];
  }

  bool _matches(DocumentDetail d, String needle, DocumentFilters f) {
    final s = d.summary;
    if (needle.isNotEmpty &&
        !s.name.toLowerCase().contains(needle) &&
        !s.ownerUsername.toLowerCase().contains(needle) &&
        !(s.categoryLabel ?? '').toLowerCase().contains(needle)) {
      return false;
    }
    if (f.typeCode != null && s.typeCode != f.typeCode) return false;
    if (f.categoryCode != null && s.categoryCode != f.categoryCode) {
      return false;
    }
    if (f.folder != null && d.folder != f.folder) return false;
    if (f.modifiedBy != null && d.modifiedBy != f.modifiedBy) return false;
    if (f.from != null && s.modifiedAt.isBefore(f.from!)) return false;
    if (f.to != null) {
      // «Hasta» incluye el dia completo.
      final end = DateTime.utc(f.to!.year, f.to!.month, f.to!.day + 1);
      if (!s.modifiedAt.isBefore(end)) return false;
    }
    return true;
  }

  @override
  Future<DocumentDetail> detail(String id) async {
    await _wait();
    final d = _documents[id];
    if (d == null) throw const DocumentsException(DocumentsError.notFound);
    // Abrir la ficha cuenta como actividad propia (D-03-47).
    _activity[id] = _clock().toUtc();
    return d;
  }

  @override
  Future<void> setFavorite(String id, {required bool favorite}) async {
    await _wait();
    final d = _documents[id];
    if (d == null) throw const DocumentsException(DocumentsError.notFound);
    _documents[id] = d.withFavorite(favorite);
  }

  @override
  Future<DocumentCatalogs> catalogs() async {
    await _wait();
    final folders = {
      for (final d in _documents.values)
        if (d.folder != null) d.folder!,
    }.toList()..sort();
    final users = {for (final d in _documents.values) d.modifiedBy}.toList()
      ..sort();
    return DocumentCatalogs(
      types: sampleTypes,
      categories: sampleCategories,
      folders: folders,
      users: users,
    );
  }
}

/// Catalogo inicial de tipos documentales (DTF M03 §5.1).
const sampleTypes = [
  CatalogEntry('TD01', 'Plano o dibujo técnico'),
  CatalogEntry('TD02', 'Informe'),
  CatalogEntry('TD03', 'Procedimiento'),
  CatalogEntry('TD04', 'Manual'),
  CatalogEntry('TD05', 'Contrato'),
  CatalogEntry('TD06', 'Permiso o licencia'),
  CatalogEntry('TD07', 'Certificado'),
  CatalogEntry('TD08', 'Acta o minuta'),
  CatalogEntry('TD09', 'Correspondencia'),
  CatalogEntry('TD10', 'Registro o evidencia'),
  CatalogEntry('TD11', 'Especificación o ficha técnica'),
  CatalogEntry('TD12', 'Otro'),
];

/// Catalogo inicial de categorias (DTF M03 §5.1).
const sampleCategories = [
  CatalogEntry('CAT01', 'Ingeniería y proyectos'),
  CatalogEntry('CAT02', 'Operación vial'),
  CatalogEntry('CAT03', 'Mantenimiento'),
  CatalogEntry('CAT04', 'Seguridad vial'),
  CatalogEntry('CAT05', 'Medio ambiente'),
  CatalogEntry('CAT06', 'Calidad'),
  CatalogEntry('CAT07', 'Legal y regulatorio'),
  CatalogEntry('CAT08', 'Administración y finanzas'),
  CatalogEntry('CAT09', 'Tecnología y sistemas'),
  CatalogEntry('CAT10', 'General'),
];

String _typeLabel(String code) =>
    sampleTypes.firstWhere((t) => t.code == code).label;

String? _categoryLabel(String? code) => code == null
    ? null
    : sampleCategories.firstWhere((c) => c.code == code).label;

DocumentDetail _doc(
  DateTime now,
  String id,
  String name, {
  required String type,
  String? category,
  required String owner,
  required int daysAgo,
  DocumentSignature signature = DocumentSignature.unsigned,
  bool favorite = false,
  String? folder,
  int version = 1,
  int size = 480000,
  String? modifiedBy,
  String description = '',
  bool preview = true,
}) {
  final dot = name.lastIndexOf('.');
  return DocumentDetail(
    summary: DocumentSummary(
      id: id,
      name: name,
      typeCode: type,
      typeLabel: _typeLabel(type),
      categoryCode: category,
      categoryLabel: _categoryLabel(category),
      ownerUsername: owner,
      modifiedAt: now.subtract(Duration(days: daysAgo, hours: 2)),
      signature: signature,
      isFavorite: favorite,
      format: dot < 0 ? '' : name.substring(dot + 1).toLowerCase(),
    ),
    version: version,
    sizeBytes: size,
    modifiedBy: modifiedBy ?? owner,
    description: description,
    folder: folder,
    previewAvailable: preview,
  );
}

List<DocumentDetail> _sampleDocuments(DateTime now) => [
  _doc(
    now,
    'd-001',
    'Informe de inspección km 120-140.pdf',
    type: 'TD02',
    category: 'CAT03',
    owner: 'amartinez',
    daysAgo: 1,
    signature: DocumentSignature.validated,
    favorite: true,
    folder: 'Mantenimiento/Inspecciones',
    version: 3,
    size: 2400000,
    description: 'Resultados de la inspección de pavimento del tramo.',
  ),
  _doc(
    now,
    'd-002',
    'Plano de señalización tramo norte.dwg',
    type: 'TD01',
    category: 'CAT01',
    owner: 'rrodriguez',
    daysAgo: 3,
    folder: 'Ingeniería',
    size: 18200000,
    preview: false,
    description: 'Planta general de la señalización vertical.',
  ),
  _doc(
    now,
    'd-003',
    'Procedimiento de atención de accidentes.docx',
    type: 'TD03',
    category: 'CAT04',
    owner: 'dlalane',
    daysAgo: 8,
    signature: DocumentSignature.pending,
    favorite: true,
    version: 2,
    size: 310000,
  ),
  _doc(
    now,
    'd-004',
    'Foto puente km 87.jpg',
    type: 'TD10',
    category: 'CAT03',
    owner: 'amartinez',
    daysAgo: 0,
    folder: 'Mantenimiento/Evidencias',
    size: 3100000,
    description: 'Daño en junta de dilatación.',
  ),
  _doc(
    now,
    'd-005',
    'Contrato de mantenimiento 2026.pdf',
    type: 'TD05',
    category: 'CAT08',
    owner: 'gnova',
    daysAgo: 20,
    signature: DocumentSignature.validated,
    version: 2,
    size: 1250000,
    folder: 'Legal',
  ),
  _doc(
    now,
    'd-006',
    'Licencia ambiental tramo sur.pdf',
    type: 'TD06',
    category: 'CAT05',
    owner: 'gnova',
    daysAgo: 45,
    size: 880000,
    folder: 'Legal',
  ),
  _doc(
    now,
    'd-007',
    'Acta de reunión de seguimiento.pdf',
    type: 'TD08',
    owner: 'amartinez',
    daysAgo: 12,
    signature: DocumentSignature.pending,
    size: 150000,
    description: 'Sin categoría asignada.',
  ),
  _doc(
    now,
    'd-008',
    'Manual de operación de casetas.pdf',
    type: 'TD04',
    category: 'CAT02',
    owner: 'dlalane',
    daysAgo: 60,
    favorite: true,
    size: 5600000,
    folder: 'Operación',
  ),
  _doc(
    now,
    'd-009',
    'Ficha técnica de defensas metálicas.pdf',
    type: 'TD11',
    category: 'CAT04',
    owner: 'rrodriguez',
    daysAgo: 5,
    size: 420000,
    folder: 'Ingeniería',
    modifiedBy: 'amartinez',
  ),
  _doc(
    now,
    'd-010',
    'Oficio a la autoridad reguladora.docx',
    type: 'TD09',
    category: 'CAT07',
    owner: 'amartinez',
    daysAgo: 25,
    size: 98000,
    folder: 'Legal',
  ),
  _doc(
    now,
    'd-011',
    'Certificado de calibración de equipos.pdf',
    type: 'TD07',
    category: 'CAT06',
    owner: 'gnova',
    daysAgo: 90,
    signature: DocumentSignature.validated,
    size: 260000,
    folder: 'Calidad',
  ),
  _doc(
    now,
    'd-012',
    'Registro fotográfico de obra.png',
    type: 'TD10',
    category: 'CAT01',
    owner: 'amartinez',
    daysAgo: 2,
    size: 4800000,
    folder: 'Mantenimiento/Evidencias',
  ),
  _doc(
    now,
    'd-013',
    'Informe mensual de operación.xlsx',
    type: 'TD02',
    category: 'CAT02',
    owner: 'dlalane',
    daysAgo: 15,
    size: 760000,
    folder: 'Operación',
    version: 4,
  ),
  _doc(
    now,
    'd-014',
    'Otro: croquis de acceso.pdf',
    type: 'TD12',
    owner: 'rrodriguez',
    daysAgo: 30,
    size: 210000,
    description: 'Croquis del acceso provisional a la obra.',
  ),
];

Map<String, DateTime> _sampleActivity(DateTime now) => {
  'd-004': now.subtract(const Duration(hours: 1)),
  'd-001': now.subtract(const Duration(days: 1)),
  'd-012': now.subtract(const Duration(days: 2)),
  'd-003': now.subtract(const Duration(days: 6)),
  'd-007': now.subtract(const Duration(days: 12)),
  'd-005': now.subtract(const Duration(days: 28)),
  'd-006': now.subtract(const Duration(days: 40)),
};
