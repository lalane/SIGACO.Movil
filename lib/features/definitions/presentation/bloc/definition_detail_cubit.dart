import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/pending_definition.dart';
import '../../domain/repositories/definitions_repository.dart';

enum DefinitionDetailStatus { loading, ready, failure }

class DefinitionDetailState extends Equatable {
  const DefinitionDetailState({
    this.status = DefinitionDetailStatus.loading,
    this.detail,
    this.error,
    this.sending = false,
    this.sendError,
    this.sendMessage,
    this.saved = 0,
  });

  final DefinitionDetailStatus status;
  final DefinitionDetail? detail;
  final DefinitionsError? error;
  final bool sending;

  /// Por que no se guardo la ultima respuesta (y el texto del servidor).
  final DefinitionsError? sendError;
  final String? sendMessage;

  /// Sube con cada respuesta guardada: la pantalla avisa una vez por cada una.
  final int saved;

  DefinitionDetailState copyWith({
    DefinitionDetailStatus? status,
    DefinitionDetail? detail,
    DefinitionsError? error,
    bool? sending,
    DefinitionsError? sendError,
    String? sendMessage,
    bool clearSendError = false,
    int? saved,
  }) => DefinitionDetailState(
    status: status ?? this.status,
    detail: detail ?? this.detail,
    error: error ?? this.error,
    sending: sending ?? this.sending,
    sendError: clearSendError ? null : (sendError ?? this.sendError),
    sendMessage: clearSendError ? null : (sendMessage ?? this.sendMessage),
    saved: saved ?? this.saved,
  );

  @override
  List<Object?> get props => [
    status,
    detail,
    error,
    sending,
    sendError,
    sendMessage,
    saved,
  ];
}

/// Una definicion con su historial y la respuesta («De acuerdo», «No: asi
/// es...» o comentario). Que botones se ven lo dice el servidor.
class DefinitionDetailCubit extends Cubit<DefinitionDetailState> {
  DefinitionDetailCubit(this._repository, this.code)
    : super(const DefinitionDetailState());

  final DefinitionsRepository _repository;
  final String code;

  Future<void> load() async {
    emit(const DefinitionDetailState());
    try {
      final detail = await _repository.get(code);
      emit(
        state.copyWith(status: DefinitionDetailStatus.ready, detail: detail),
      );
    } on DefinitionsException catch (e) {
      emit(
        state.copyWith(status: DefinitionDetailStatus.failure, error: e.error),
      );
    }
  }

  /// Devuelve si se guardo.
  Future<bool> answer(DefinitionAnswerKind kind, {String? text}) async {
    if (state.sending) return false;
    if (kind.needsText && (text == null || text.trim().isEmpty)) {
      // Se limpia antes: el mismo aviso se repite si vuelve a faltar el texto.
      emit(state.copyWith(clearSendError: true));
      emit(state.copyWith(sendError: DefinitionsError.validation));
      return false;
    }
    emit(state.copyWith(sending: true, clearSendError: true));
    try {
      final detail = await _repository.answer(code, kind, text: text);
      emit(
        state.copyWith(
          sending: false,
          detail: detail,
          status: DefinitionDetailStatus.ready,
          saved: state.saved + 1,
        ),
      );
      return true;
    } on DefinitionsException catch (e) {
      emit(
        state.copyWith(
          sending: false,
          sendError: e.error,
          sendMessage: e.message,
        ),
      );
      return false;
    }
  }
}
