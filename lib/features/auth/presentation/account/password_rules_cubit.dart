import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/auth_entities.dart';
import '../../domain/repositories/auth_repository.dart';

/// Las reglas de contrasena vigentes, para mostrarlas antes de que la persona
/// escriba la nueva (MOB DEV-MOB-042). Null mientras no se conocen o si el
/// servidor no las dio: la pantalla funciona igual y el servidor valida.
class PasswordRulesCubit extends Cubit<PasswordRules?> {
  PasswordRulesCubit(this._repository) : super(null);

  final AuthRepository _repository;

  Future<void> load() async {
    PasswordRules? rules;
    try {
      rules = await _repository.passwordRules();
    } catch (_) {
      rules = null;
    }
    if (!isClosed) emit(rules);
  }
}
