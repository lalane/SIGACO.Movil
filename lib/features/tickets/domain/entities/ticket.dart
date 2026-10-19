import 'package:equatable/equatable.dart';

/// En que va un ticket: abierto (nadie lo ha atendido) o atendido (hay trabajo
/// hecho). El BBP (APP-MOB-03) maneja solo tickets «abiertos o atendidos». Los
/// colores de estatus son del sistema (COL-05).
enum TicketStatus { open, attended }

/// Una anotacion de seguimiento: lo que se hizo, en que estado quedo el ticket
/// y las fotos de evidencia.
class TicketFollowUp extends Equatable {
  const TicketFollowUp({
    required this.id,
    required this.at,
    required this.status,
    required this.description,
    this.photoPaths = const [],
  });

  final String id;

  /// Cuando ocurrio, en UTC.
  final DateTime at;
  final TicketStatus status;
  final String description;

  /// Rutas locales de las fotos.
  final List<String> photoPaths;

  @override
  List<Object?> get props => [id, at, status, description, photoPaths];
}

/// Un ticket de la concesion: un dano o una necesidad en la carretera que hay
/// que atender antes de su vencimiento.
class Ticket extends Equatable {
  const Ticket({
    required this.id,
    required this.code,
    required this.title,
    required this.status,
    required this.createdAt,
    this.description,
    this.category,
    this.dueAt,
    this.authorName,
    this.authorProfile,
    this.company,
    this.concessionName,
    this.kmLabel,
    this.latitude,
    this.longitude,
    this.carriageway,
    this.photoPaths = const [],
    this.followUps = const [],
  });

  final String id;

  /// El numero que se ve y se dicta (`0035`).
  final String code;
  final String title;
  final TicketStatus status;

  /// Cuando se levanto, en UTC.
  final DateTime createdAt;
  final String? description;

  /// Tipo de ticket tal como lo entrega el catalogo.
  final String? category;

  /// Limite para atenderlo, en UTC.
  final DateTime? dueAt;
  final String? authorName;
  final String? authorProfile;
  final String? company;
  final String? concessionName;

  /// Cadenamiento tal como lo muestra el negocio (`KM 513+615`).
  final String? kmLabel;
  final double? latitude;
  final double? longitude;

  /// Cuerpo de la carretera (`A`, `B`).
  final String? carriageway;
  final List<String> photoPaths;
  final List<TicketFollowUp> followUps;

  /// Cuanto falta para el vencimiento (negativo si ya vencio).
  Duration? timeToDue(DateTime now) => dueAt?.difference(now);

  /// Texto para buscar: titulo, numero, cadenamiento y tipo.
  bool matches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return [
      title,
      code,
      kmLabel,
      category,
      description,
    ].any((v) => v != null && v.toLowerCase().contains(q));
  }

  Ticket copyWith({TicketStatus? status, List<TicketFollowUp>? followUps}) =>
      Ticket(
        id: id,
        code: code,
        title: title,
        status: status ?? this.status,
        createdAt: createdAt,
        description: description,
        category: category,
        dueAt: dueAt,
        authorName: authorName,
        authorProfile: authorProfile,
        company: company,
        concessionName: concessionName,
        kmLabel: kmLabel,
        latitude: latitude,
        longitude: longitude,
        carriageway: carriageway,
        photoPaths: photoPaths,
        followUps: followUps ?? this.followUps,
      );

  @override
  List<Object?> get props => [
    id,
    code,
    title,
    status,
    createdAt,
    description,
    category,
    dueAt,
    authorName,
    authorProfile,
    company,
    concessionName,
    kmLabel,
    latitude,
    longitude,
    carriageway,
    photoPaths,
    followUps,
  ];
}

/// Lo que la persona captura para dar seguimiento a un ticket.
class NewFollowUp extends Equatable {
  const NewFollowUp({
    required this.at,
    required this.status,
    required this.description,
    this.photoPaths = const [],
  });

  /// Fecha y hora elegidas, en UTC.
  final DateTime at;
  final TicketStatus status;
  final String description;
  final List<String> photoPaths;

  @override
  List<Object?> get props => [at, status, description, photoPaths];
}

/// Lo que la persona captura para levantar un ticket nuevo.
class NewTicket extends Equatable {
  const NewTicket({
    required this.title,
    required this.category,
    this.kmLabel,
    this.description,
    this.photoPaths = const [],
  });

  final String title;
  final String category;
  final String? kmLabel;
  final String? description;
  final List<String> photoPaths;

  @override
  List<Object?> get props => [
    title,
    category,
    kmLabel,
    description,
    photoPaths,
  ];
}
