import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/inventory_repository.dart';

enum AssetQrStatus {
  /// Esperando un codigo.
  scanning,

  /// Buscando el activo del codigo.
  resolving,

  /// Se encontro: [AssetQrState.assetId].
  found,

  /// El codigo no es de un activo de SIGACO.
  invalid,

  /// No hay un activo con ese QR en la concesion activa.
  notFound,

  /// Sin red, sin permiso o error del servidor: se puede volver a intentar.
  failure,
}

class AssetQrState extends Equatable {
  const AssetQrState({
    this.status = AssetQrStatus.scanning,
    this.assetId,
    this.error,
    this.token,
  });

  final AssetQrStatus status;
  final String? assetId;
  final InventoryError? error;

  /// El ultimo token leido.
  final String? token;

  @override
  List<Object?> get props => [status, assetId, error, token];
}

/// El lector de QR del activo: el QR trae un token (GUID) y con el se abre la
/// ficha (`/api/assets/by-qr/{token}`).
class AssetQrCubit extends Cubit<AssetQrState> {
  AssetQrCubit(this._repository) : super(const AssetQrState());

  final InventoryRepository _repository;

  static final _guid = RegExp(
    r'[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}',
  );

  /// El token de lo leido: el GUID solo (QR viejos) o dentro de un enlace
  /// (`{web}/inventario/qr/{token}`); si el enlace trae `/qr/`, el GUID que va
  /// despues, aunque antes haya otro. Null si no trae.
  static String? tokenOf(String raw) {
    final text = raw.trim();
    final qr = text.toLowerCase().lastIndexOf('/qr/');
    final match =
        (qr >= 0 ? _guid.firstMatch(text.substring(qr)) : null) ??
        _guid.firstMatch(text);
    return match?.group(0)?.toLowerCase();
  }

  Future<void> resolve(String raw) async {
    // Mientras se busca uno, el lector puede seguir leyendo el mismo codigo.
    if (state.status == AssetQrStatus.resolving ||
        state.status == AssetQrStatus.found) {
      return;
    }
    final token = tokenOf(raw);
    if (token == null) {
      emit(const AssetQrState(status: AssetQrStatus.invalid));
      return;
    }
    final source = _repository;
    if (source is! AssetQrSource) {
      emit(
        AssetQrState(
          status: AssetQrStatus.failure,
          error: InventoryError.notAvailable,
          token: token,
        ),
      );
      return;
    }
    emit(AssetQrState(status: AssetQrStatus.resolving, token: token));
    try {
      final asset = await (source as AssetQrSource).byQr(token);
      if (isClosed) return;
      emit(
        AssetQrState(
          status: AssetQrStatus.found,
          assetId: asset.id,
          token: token,
        ),
      );
    } on InventoryException catch (e) {
      if (isClosed) return;
      emit(
        AssetQrState(
          status: e.error == InventoryError.notFound
              ? AssetQrStatus.notFound
              : AssetQrStatus.failure,
          error: e.error,
          token: token,
        ),
      );
    } catch (_) {
      if (isClosed) return;
      emit(
        AssetQrState(
          status: AssetQrStatus.failure,
          error: InventoryError.server,
          token: token,
        ),
      );
    }
  }

  /// Vuelve a leer.
  void reset() => emit(const AssetQrState());
}
