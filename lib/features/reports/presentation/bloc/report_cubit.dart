import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/indicator_report.dart';
import '../../domain/repositories/reports_repository.dart';

enum ReportStatus { idle, generating, ready, failure }

class ReportState extends Equatable {
  const ReportState({
    this.status = ReportStatus.idle,
    this.from,
    this.to,
    this.report,
    this.error,
  });

  final ReportStatus status;

  /// El periodo elegido; null = sin limite. Cambiarlo no regenera el reporte.
  final DateTime? from;
  final DateTime? to;
  final IndicatorReport? report;
  final ReportError? error;

  /// El reporte que se ve ya no es del periodo elegido.
  bool get stale =>
      report != null && (report!.from != from || report!.to != to);

  ReportState copyWith({
    ReportStatus? status,
    DateTime? from,
    bool clearFrom = false,
    DateTime? to,
    bool clearTo = false,
    IndicatorReport? report,
    ReportError? error,
    bool clearError = false,
  }) => ReportState(
    status: status ?? this.status,
    from: clearFrom ? null : (from ?? this.from),
    to: clearTo ? null : (to ?? this.to),
    report: report ?? this.report,
    error: clearError ? null : (error ?? this.error),
  );

  @override
  List<Object?> get props => [status, from, to, report, error];
}

/// El reporte de un indicador: se elige el periodo y se genera.
class ReportCubit extends Cubit<ReportState> {
  ReportCubit(this._repository, this.indicator) : super(const ReportState());

  final ReportsRepository _repository;
  final ReportIndicator indicator;

  void setFrom(DateTime? day) => emit(
    day == null ? state.copyWith(clearFrom: true) : state.copyWith(from: day),
  );

  void setTo(DateTime? day) => emit(
    day == null ? state.copyWith(clearTo: true) : state.copyWith(to: day),
  );

  Future<void> generate() async {
    final from = state.from;
    final to = state.to;
    // Un periodo al reves no tiene nada: se acomodan las fechas.
    final (start, end) = from != null && to != null && from.isAfter(to)
        ? (to, from)
        : (from, to);
    emit(state.copyWith(status: ReportStatus.generating, clearError: true));
    try {
      final report = await _repository.generate(
        indicator,
        from: start,
        to: end,
      );
      if (isClosed) return;
      emit(
        ReportState(
          status: ReportStatus.ready,
          from: start,
          to: end,
          report: report,
        ),
      );
    } on ReportException catch (e) {
      if (isClosed) return;
      emit(state.copyWith(status: ReportStatus.failure, error: e.error));
    } catch (_) {
      if (isClosed) return;
      emit(
        state.copyWith(status: ReportStatus.failure, error: ReportError.server),
      );
    }
  }
}
