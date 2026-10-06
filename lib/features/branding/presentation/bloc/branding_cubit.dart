import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/brand_rules.dart';
import '../../../../core/theme/brand_seed.dart';
import '../../domain/entities/concession_branding.dart';
import '../../domain/repositories/branding_repository.dart';

class BrandingState extends Equatable {
  const BrandingState({this.branding, this.seed});

  /// Lo que entrego el servidor (o lo guardado).
  final ConcessionBranding? branding;

  /// Colores ya validados; null si no hay marca o no cumplio las reglas (se
  /// usan entonces los de SIGACO).
  final BrandSeed? seed;

  /// Hay algo de la concesion que mostrar: colores o logo.
  bool get hasBrand =>
      seed != null || logoLightUrl != null || logoDarkUrl != null;

  String? get logoLightUrl => _safe(branding?.logoLightUrl);
  String? get logoDarkUrl => _safe(branding?.logoDarkUrl);

  /// Logo para el tipo de fondo indicado; si falta, el otro.
  String? logoFor({required bool darkBackground}) => darkBackground
      ? (logoDarkUrl ?? logoLightUrl)
      : (logoLightUrl ?? logoDarkUrl);

  /// Solo https (http unicamente en desarrollo): el logo lo elige un tercero.
  static String? _safe(String? url) {
    if (url == null) return null;
    final uri = Uri.tryParse(url);
    if (uri == null || uri.host.isEmpty) return null;
    if (uri.scheme == 'https' || (kDebugMode && uri.scheme == 'http')) {
      return url;
    }
    return null;
  }

  @override
  List<Object?> get props => [branding, seed];

  @override
  String toString() => 'BrandingState(hasSeed: ${seed != null})';
}

/// Marca de la concesion activa (FEAT de colores por concesionaria).
///
/// Solo existe con una concesion activa: al cerrar sesion o cambiar de
/// concesion se descarta antes de cargar la nueva (MAR-08 y MAR-09).
class BrandingCubit extends Cubit<BrandingState> {
  BrandingCubit(this._repo) : super(const BrandingState());

  final BrandingRepository _repo;
  int _generation = 0;

  Future<void> load(String concessionId) async {
    final generation = ++_generation;
    emit(const BrandingState());
    ConcessionBranding? branding;
    try {
      branding = await _repo.load(concessionId);
    } catch (_) {
      branding = null;
    }
    // Llego tarde: ya se cambio de concesion o se cerro sesion.
    if (generation != _generation) return;
    emit(_stateFor(branding));
  }

  void clear() {
    _generation++;
    emit(const BrandingState());
  }

  BrandingState _stateFor(ConcessionBranding? b) {
    if (b == null) return const BrandingState();
    final seed = BrandSeed.tryFromHex(
      primary: b.primary,
      secondary: b.secondary,
      headerStart: b.headerStart,
      headerEnd: b.headerEnd,
    );
    final accepted = seed == null ? null : BrandRules.sanitize(seed);
    if (kDebugMode && seed != null) {
      final issues = BrandRules.issuesOf(seed);
      if (issues.isNotEmpty) {
        debugPrint('Marca de la concesion: ${issues.map((i) => i.name)}');
      }
    }
    return BrandingState(branding: b, seed: accepted);
  }
}
