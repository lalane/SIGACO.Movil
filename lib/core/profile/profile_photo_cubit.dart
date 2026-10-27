import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'profile_photo.dart';

class ProfilePhotoState extends Equatable {
  const ProfilePhotoState({
    this.path,
    this.saving = false,
    this.failed = false,
  });

  /// La foto de la persona en sesion; null si no tiene.
  final String? path;
  final bool saving;

  /// El ultimo cambio no se pudo guardar.
  final bool failed;

  @override
  List<Object?> get props => [path, saving, failed];
}

enum ProfilePhotoSource { camera, gallery }

/// La foto de perfil de la persona en sesion: se carga al entrar, se cambia
/// desde la cuenta y se muestra en la cuenta y en el inicio.
class ProfilePhotoCubit extends Cubit<ProfilePhotoState> {
  ProfilePhotoCubit({
    this._store = const NoProfilePhotoStore(),
    this._picker = const NoProfilePhotoPicker(),
  }) : super(const ProfilePhotoState());

  final ProfilePhotoStore _store;
  final ProfilePhotoPicker _picker;
  String? _userId;

  /// Entra una persona: se muestra su foto, si la tiene.
  Future<void> load(String userId) async {
    // Ya es la de esta persona: no se vuelve a pedir en cada cambio de sesion.
    if (_userId == userId) return;
    _userId = userId;
    emit(const ProfilePhotoState());
    try {
      final path = await _store.read(userId);
      if (isClosed || _userId != userId) return;
      emit(ProfilePhotoState(path: path));
    } catch (_) {
      // Sin foto se ven las iniciales.
    }
  }

  /// Sale la persona: la foto no pasa a la siguiente sesion.
  void clear() {
    _userId = null;
    emit(const ProfilePhotoState());
  }

  /// Cambia la foto con la camara o la galeria. Cancelar no cambia nada.
  Future<void> change(ProfilePhotoSource source) async {
    final userId = _userId;
    if (userId == null || state.saving) return;
    emit(ProfilePhotoState(path: state.path, saving: true));
    try {
      final picked = source == ProfilePhotoSource.camera
          ? await _picker.fromCamera()
          : await _picker.fromGallery();
      if (picked == null) {
        emit(ProfilePhotoState(path: state.path));
        return;
      }
      final saved = await _store.save(userId, picked);
      if (isClosed || _userId != userId) return;
      emit(ProfilePhotoState(path: saved));
    } catch (_) {
      if (isClosed) return;
      emit(ProfilePhotoState(path: state.path, failed: true));
    }
  }

  /// Quita la foto: vuelven las iniciales.
  Future<void> remove() async {
    final userId = _userId;
    if (userId == null || state.saving) return;
    try {
      await _store.remove(userId);
      if (isClosed || _userId != userId) return;
      emit(const ProfilePhotoState());
    } catch (_) {
      if (isClosed) return;
      emit(ProfilePhotoState(path: state.path, failed: true));
    }
  }
}
