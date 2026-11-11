import 'package:equatable/equatable.dart';

// Lo que hace el Supervisor con un ticket (DTF M11 v0.3, HU-11-24): asignarlo a
// una empresa y un equipo, cerrarlo, regresarlo a Abierto, reabrirlo o
// cancelarlo. Que se puede en cada ticket lo dice el servidor (`actions`).

/// Una persona activa de un equipo asignable.
class TicketTeamMember extends Equatable {
  const TicketTeamMember({
    required this.userId,
    required this.fullName,
    this.profileCode,
  });

  final String userId;
  final String fullName;
  final String? profileCode;

  @override
  List<Object?> get props => [userId, fullName, profileCode];
}

/// Un equipo activo, con al menos una persona activa en la concesion
/// (RB-11-09).
class TicketAssignableTeam extends Equatable {
  const TicketAssignableTeam({
    required this.id,
    required this.name,
    this.members = const [],
  });

  final String id;
  final String name;
  final List<TicketTeamMember> members;

  @override
  List<Object?> get props => [id, name, members];
}

/// Una empresa activa de la concesionaria con sus equipos asignables.
class TicketAssignableCompany extends Equatable {
  const TicketAssignableCompany({
    required this.id,
    required this.name,
    this.isExternal = false,
    this.teams = const [],
  });

  final String id;
  final String name;

  /// Empresa externa (contratista).
  final bool isExternal;
  final List<TicketAssignableTeam> teams;

  @override
  List<Object?> get props => [id, name, isExternal, teams];
}

/// Asignar (SIN_VALIDAR a ABIERTO) o reasignar: empresa y equipo obligatorios;
/// la persona de referencia es opcional y el motivo es obligatorio al
/// reasignar (RB-11-10).
class TicketAssignment extends Equatable {
  const TicketAssignment({
    required this.companyId,
    required this.teamId,
    this.responsibleUserId,
    this.reason,
  });

  final String companyId;
  final String teamId;
  final String? responsibleUserId;
  final String? reason;

  @override
  List<Object?> get props => [companyId, teamId, responsibleUserId, reason];
}

/// La condicion del activo que deja el Supervisor al cerrar (P-11-27).
enum TicketAssetCondition {
  unchanged('SIN_CAMBIO'),
  good('BUENO'),
  fair('REGULAR'),
  poor('MALO'),
  veryPoor('PESIMO');

  const TicketAssetCondition(this.code);

  final String code;
}

/// Validar y cerrar un ticket ATENDIDO: observacion opcional (D-11-25) y la
/// condicion del activo (por omision, sin cambio).
class TicketClosing extends Equatable {
  const TicketClosing({
    this.notes,
    this.condition = TicketAssetCondition.unchanged,
  });

  final String? notes;
  final TicketAssetCondition condition;

  @override
  List<Object?> get props => [notes, condition];
}

/// Por que se cancela un ticket (S-TKT-10).
enum TicketCancelReason {
  duplicate('DUPLICADO'),
  improper('IMPROCEDENTE'),
  other('OTRO');

  const TicketCancelReason(this.code);

  final String code;
}

/// Cancelar: un duplicado lleva el folio del original (de la misma concesion);
/// «otro» lleva el texto del motivo.
class TicketCancellation extends Equatable {
  const TicketCancellation({
    required this.reason,
    this.duplicateOfFolio,
    this.notes,
  });

  final TicketCancelReason reason;
  final String? duplicateOfFolio;
  final String? notes;

  @override
  List<Object?> get props => [reason, duplicateOfFolio, notes];
}
