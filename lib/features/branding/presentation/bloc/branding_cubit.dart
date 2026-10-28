import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/brand_rules.dart';
import '../../../../core/theme/brand_seed.dart';
import '../../../../core/time/concession_zone.dart';
import '../../domain/entities/concession_branding.dart';
import '../../domain/repositories/branding_repository.dart';

class BrandingState extends Equatable {
  const BrandingState({this.branding, this.seed, this.zone});

  /// Lo que entrego el servidor (o lo guardado).
  final ConcessionBranding? branding;

  /// Colores ya validados; null si no hay marca o no cumplio las reglas (se
  /// usan entonces los de SIGACO).
  final BrandSeed? seed;

  /// Zona horaria de la concesion; null si no la trae o no es valida.
  final ConcessionZone? zone;

  /// Hay algo de la concesion que mostrar: colores o logo.
  bool get hasBrand =>
      seed != null || logoLightUrl != null || logoDarkUrl != null;

  String? get logoLightUrl => _safe(branding?.logoLightUrl);
  String? get logoDarkUrl => _safe(branding?.logoDarkUrl);
  String? get logoReducedUrl => _safe(branding?.logoReducedUrl);

  /// Logo para el tipo de fondo indicado; si falta, el otro. Con
  /// [preferReduced] se prefiere la variante reducida (cabecera de la app,
  /// DTF Configuracion US-07) y, si no existe, el logo del fondo.
  String? logoFor({required bool darkBackground, bool preferReduced = false}) {
    if (preferReduced && logoReducedUrl != null) return logoReducedUrl;
    return darkBackground
        ? (logoDarkUrl ?? logoLightUrl)
        : (logoLightUrl ?? logoDarkUrl);
  }

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
///
/// Mientras la sesion sigue abierta se vuelve a consultar la version de la
/// marca (`refresh`): al volver a la app y al recuperar la conexion (US-18,
/// DEV-MOB-088). Un cambio hecho en el portal llega sin cerrar sesion.
class BrandingCubit extends Cubit<BrandingState> {
  BrandingCubit(
    this._repo, {
    this.minRefreshGap = const Duration(minutes: 1),
    DateTime Function()? clock,
  }) : _now = clock ?? DateTime.now,
       super(const BrandingState());

  final BrandingRepository _repo;

  /// Tiempo minimo entre dos consultas al volver a la app (no se consulta cada
  /// vez que el telefono pasa un instante a segundo plano).
  final Duration minRefreshGap;
  final DateTime Function() _now;

  int _generation = 0;
  String? _concessionId;
  DateTime? _checkedAt;
  bool _refreshing = false;

  Future<void> load(String concessionId) async {
    final generation = ++_generation;
    _concessionId = concessionId;
    _checkedAt = null;
    emit(const BrandingState());
    ConcessionBranding? branding;
    try {
      branding = await _repo.load(concessionId);
    } catch (_) {
      branding = null;
    }
    // Llego tarde: ya se cambio de concesion o se cerro sesion.
    if (generation != _generation) return;
    _checkedAt = _now();
    emit(_stateFor(branding));
  }

  /// Vuelve a consultar la marca de la concesion activa sin vaciar la que se
  /// ve. Solo cambia la pantalla si el servidor entrego otra cosa. Sin
  /// conexion o con un error se conserva lo que ya habia.
  ///
  /// [gap] es el tiempo minimo desde la ultima consulta; con `Duration.zero`
  /// (al recuperar la conexion) se consulta siempre.
  Future<void> refresh({Duration? gap}) async {
    final id = _concessionId;
    if (id == null || _refreshing) return;
    final checked = _checkedAt;
    if (checked != null &&
        _now().difference(checked) < (gap ?? minRefreshGap)) {
      return;
    }
    final generation = _generation;
    _refreshing = true;
    try {
      final branding = await _repo.load(id);
      if (generation != _generation) return;
      _checkedAt = _now();
      final next = _stateFor(branding);
      if (next != state) emit(next);
    } catch (_) {
      // Se conserva la marca que ya se ve.
    } finally {
      _refreshing = false;
    }
  }

  void clear() {
    _generation++;
    _concessionId = null;
    _checkedAt = null;
    emit(const BrandingState());
  }

  BrandingState _stateFor(ConcessionBranding? b) {
    if (b == null) return const BrandingState();
    final seed = BrandSeed.tryFromHex(
      primary: b.primary,
      secondary: b.secondary,
      headerStart: b.headerStart,
      headerEnd: b.headerEnd,
      accent: b.accent,
      navActive: b.secondaryAccent,
      onPrimary: b.primaryText,
    );
    final accepted = seed == null ? null : BrandRules.sanitize(seed);
    if (kDebugMode && seed != null) {
      final issues = BrandRules.issuesOf(seed);
      if (issues.isNotEmpty) {
        debugPrint('Marca de la concesion: ${issues.map((i) => i.name)}');
      }
    }
    return BrandingState(
      branding: b,
      seed: accepted,
      zone: ConcessionZone.tryParse(b.timezone),
    );
  }
}
