import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/ids/client_id.dart';
import '../../domain/repositories/maintenance_repository.dart';

/// Lo que se puede reclamar de un avance antes de guardarlo.
enum ProgressIssue { percent, volume }

class MaintenanceProgressState extends Equatable {
  const MaintenanceProgressState({
    this.percent = '',
    this.volume = '',
    this.notes = '',
    this.saving = false,
    this.saved = false,
    this.showIssues = false,
    this.error,
  });

  final String percent;
  final String volume;
  final String notes;
  final bool saving;
  final bool saved;

  /// Se activa al intentar guardar: antes no se regana a nadie por un campo
  /// vacio.
  final bool showIssues;

  /// Por que no se guardo; null mientras no haya fallado.
  final MaintenanceError? error;

  List<ProgressIssue> get issues => [
    if (parsePercent(percent) == null) ProgressIssue.percent,
    if (volume.trim().isNotEmpty && parseAmount(volume) == null)
      ProgressIssue.volume,
  ];

  MaintenanceProgressState copyWith({
    String? percent,
    String? volume,
    String? notes,
    bool? saving,
    bool? saved,
    bool? showIssues,
    MaintenanceError? error,
    bool clearError = false,
  }) => MaintenanceProgressState(
    percent: percent ?? this.percent,
    volume: volume ?? this.volume,
    notes: notes ?? this.notes,
    saving: saving ?? this.saving,
    saved: saved ?? this.saved,
    showIssues: showIssues ?? this.showIssues,
    error: clearError ? null : (error ?? this.error),
  );

  @override
  List<Object?> get props => [
    percent,
    volume,
    notes,
    saving,
    saved,
    showIssues,
    error,
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

/// El formulario para registrar el avance de un mantenimiento.
class MaintenanceProgressCubit extends Cubit<MaintenanceProgressState> {
  MaintenanceProgressCubit(
    this._repository,
    this.orderId, {
    double? currentProgress,
    String Function()? clientIdGenerator,
  }) : super(
         MaintenanceProgressState(
           percent: currentProgress == null
               ? ''
               : '${(currentProgress * 100).round()}',
         ),
       ) {
    _clientId = (clientIdGenerator ?? newClientId)();
  }

  final MaintenanceRepository _repository;
  final String orderId;

  /// Un reintento tras un corte no suma el avance dos veces.
  late final String _clientId;

  void setPercent(String text) =>
      emit(state.copyWith(percent: text, clearError: true));

  void setVolume(String text) =>
      emit(state.copyWith(volume: text, clearError: true));

  void setNotes(String text) => emit(state.copyWith(notes: text));

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
        percent: parsePercent(state.percent)!,
        executedVolume: parseAmount(state.volume),
        notes: state.notes,
        clientId: _clientId,
      );
      if (isClosed) return;
      emit(state.copyWith(saving: false, saved: true));
    } on MaintenanceException catch (e) {
      if (isClosed) return;
      emit(state.copyWith(saving: false, error: e.error));
    } catch (_) {
      if (isClosed) return;
      emit(state.copyWith(saving: false, error: MaintenanceError.server));
    }
  }
}
