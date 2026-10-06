import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/auth_entities.dart';
import '../../domain/repositories/auth_repository.dart';

enum AccountStatus { loading, ready, failure }

class AccountState extends Equatable {
  const AccountState({this.status = AccountStatus.loading, this.profile});

  final AccountStatus status;
  final MyProfile? profile;

  @override
  List<Object?> get props => [status, profile];
}

/// Consulta del perfil propio (FEAT-M01-03, HU-M01-03-01).
class AccountCubit extends Cubit<AccountState> {
  AccountCubit(this._repo) : super(const AccountState());

  final AuthRepository _repo;

  Future<void> load() async {
    emit(const AccountState());
    try {
      emit(
        AccountState(
          status: AccountStatus.ready,
          profile: await _repo.getProfile(),
        ),
      );
    } on AuthException {
      emit(const AccountState(status: AccountStatus.failure));
    }
  }
}
