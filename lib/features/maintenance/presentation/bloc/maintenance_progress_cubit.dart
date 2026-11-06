import 'dart:math' as math;

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/ids/client_id.dart';
import '../../domain/repositories/maintenance_repository.dart';

/// Lo que se puede reclamar de un seguimiento antes de guardarlo.
enum ProgressIssue {
  /// Ni volumen ni porcentaje.
  missing,

  /// El volumen no es un numero mayor que 0.
  volume,

  /// El volumen supera lo que falta por ejecutar.
  volumeOverRemaining,

  /// El porcentaje no esta entre 0 y 100.
  percent,

  /// El porcentaje acumulado es menor que el que ya lleva.
  percentBelowCurrent,
}

/// Cuantas fotos admite un seguimiento (maqueta de la app: tres huecos).
const maxProgressPhotos = 3;

class MaintenanceProgressState extends Equatable {
  const MaintenanceProgressState({
    this.volume = '',
    this.percent = '',
    this.notes = '',
    this.photos = const [null, null, null],
    this.totalVolume,
    this.executedVolume,
    this.saving = false,
    this.saved = false,
    this.showIssues = false,
    this.error,
    this.errorMessage,
  });

  /// Volumen ejecutado EN ESTE seguimiento.
  final String volume;

  /// Avance acumulado en %; solo cuenta si no hay volumen.
  final String percent;
  final String notes;
  final List<String?> photos;

  /// Lo programado y lo ya ejecutado de la orden, si se conocen.
  final double? totalVolume;
  final double? executedVolume;
  final bool saving;
  final bool saved;

  /// Se activa al intentar guardar: antes no se regana a nadie por un campo
  /// vacio.
  final bool showIssues;

  /// Por que no se guardo; null mientras no haya fallado.
  final MaintenanceError? error;

  /// El motivo que dio el servidor.
  final String? errorMessage;

  bool get _knowsTotal => (totalVolume ?? 0) > 0;

  /// El avance acumulado actual, de 0 a 100; null si no se conoce.
  double? get currentPercent => _knowsTotal
      ? (100 * (executedVolume ?? 0) / totalVolume!).clamp(0, 100).toDouble()
      : null;

  /// Lo que falta por ejecutar; null si no se conoce el total.
  double? get remaining => _knowsTotal
      ? math.max(0, totalVolume! - (executedVolume ?? 0)).toDouble()
      : null;

  bool get usesVolume => volume.trim().isNotEmpty;

  /// El avance acumulado en que quedara la orden con lo escrito; null si no se
  /// puede calcular.
  double? get resultingPercent {
    if (usesVolume) {
      final v = parseAmount(volume);
      if (v == null || !_knowsTotal) return null;
      return (100 * ((executedVolume ?? 0) + v) / totalVolume!)
          .clamp(0, 100)
          .toDouble();
    }
    return parsePercent(percent);
  }

  List<String> get photoPaths => [for (final p in photos) ?p];

  List<ProgressIssue> get issues {
    if (usesVolume) {
      final v = parseAmount(volume);
      if (v == null || v <= 0) return const [ProgressIssue.volume];
      final left = remaining;
      // Un margen de redondeo: el servidor guarda tres decimales.
      if (left != null && v > left + 0.0005) {
        return const [ProgressIssue.volumeOverRemaining];
      }
      return const [];
    }
    if (percent.trim().isEmpty) return const [ProgressIssue.missing];
    final p = parsePercent(percent);
    if (p == null) return const [ProgressIssue.percent];
    final now = currentPercent;
    if (now != null && p + 0.0005 < now) {
      return const [ProgressIssue.percentBelowCurrent];
    }
    return const [];
  }

  MaintenanceProgressState copyWith({
    String? volume,
    String? percent,
    String? notes,
    List<String?>? photos,
    bool? saving,
    bool? saved,
    bool? showIssues,
    MaintenanceError? error,
    String? errorMessage,
    bool clearError = false,
  }) => MaintenanceProgressState(
    volume: volume ?? this.volume,
    percent: percent ?? this.percent,
    notes: notes ?? this.notes,
    photos: photos ?? this.photos,
    totalVolume: totalVolume,
    executedVolume: executedVolume,
    saving: saving ?? this.saving,
    saved: saved ?? this.saved,
    showIssues: showIssues ?? this.showIssues,
    error: clearError ? null : (error ?? this.error),
    errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
  );

  @override
  List<Object?> get props => [
    volume,
    percent,
    notes,
    photos,
    totalVolume,
    executedVolume,
    saving,
    saved,
    showIssues,
    error,
    errorMessage,
  ];
}

/// Un numero escrito con punto o coma decimal; null si no lo es o es negativo.
double? parseAmount(String text) {
  final v = double.tryParse(text.trim().replaceAll(',', '.'));
  if (v == null || v.isNaN || v.isInfinite || v < 0) return null;
  return v;
}

/// El avance escrito, de 0 a 100; null si no es valido.
double? parsePercent(String text) {
  final v = parseAmount(text);
  return v == null || v > 100 ? null : v;
}

/// El formulario para registrar un seguimiento de un mantenimiento: lo
/// ejecutado hoy (o, si no se conoce, el avance acumulado), notas y fotos.
class MaintenanceProgressCubit extends Cubit<MaintenanceProgressState> {
  MaintenanceProgressCubit(
    this._repository,
    this.orderId, {
    double? totalVolume,
    double? executedVolume,
    String Function()? clientIdGenerator,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now,
       super(
         MaintenanceProgressState(
           totalVolume: totalVolume,
           executedVolume: executedVolume,
         ),
       ) {
    _clientId = (clientIdGenerator ?? newClientId)();
  }

  final MaintenanceRepository _repository;
  final String orderId;
  final DateTime Function() _clock;

  /// Un reintento tras un corte no suma el avance dos veces.
  late final String _clientId;

  void setVolume(String text) =>
      emit(state.copyWith(volume: text, clearError: true));

  void setPercent(String text) =>
      emit(state.copyWith(percent: text, clearError: true));

  void setNotes(String text) => emit(state.copyWith(notes: text));

  void setPhoto(int slot, String? path) {
    final photos = [...state.photos];
    photos[slot] = path;
    emit(state.copyWith(photos: photos));
  }

  Future<void> save() async {
    if (state.saving) return;
    if (state.issues.isNotEmpty) {
      emit(state.copyWith(showIssues: true));
      return;
    }
    emit(state.copyWith(saving: true, showIssues: true, clearError: true));
    try {
      await _repository.addProgress(
        orderId,
        executedVolume: state.usesVolume ? parseAmount(state.volume) : null,
        percent: state.usesVolume ? null : parsePercent(state.percent),
        notes: state.notes,
        photoPaths: state.photoPaths,
        at: _clock(),
        clientId: _clientId,
      );
      if (isClosed) return;
      emit(state.copyWith(saving: false, saved: true));
    } on MaintenanceException catch (e) {
      if (isClosed) return;
      // El avance ya quedo: se cierra el formulario y se avisa de las fotos.
      if (e.error == MaintenanceError.photosNotSaved) {
        emit(
          state.copyWith(
            saving: false,
            saved: true,
            error: e.error,
            errorMessage: e.message,
          ),
        );
        return;
      }
      emit(
        state.copyWith(saving: false, error: e.error, errorMessage: e.message),
      );
    } catch (_) {
      if (isClosed) return;
      emit(state.copyWith(saving: false, error: MaintenanceError.server));
    }
  }
}
