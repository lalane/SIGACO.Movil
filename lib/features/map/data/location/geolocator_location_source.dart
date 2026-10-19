import 'dart:async';

import 'package:geolocator/geolocator.dart';

import '../../domain/entities/geo_point.dart';
import '../../domain/entities/user_location.dart';
import '../../domain/repositories/location_source.dart';

/// La ubicacion del telefono con el plugin `geolocator` (Android: Fused
/// Location). No se usa en pruebas: ahi se pasa un [LocationSource] falso.
class GeolocatorLocationSource implements LocationSource {
  const GeolocatorLocationSource({
    this.timeLimit = const Duration(seconds: 15),
  });

  /// Cuanto se espera una posicion antes de rendirse.
  final Duration timeLimit;

  @override
  Future<UserLocation> current() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationException(LocationFailure.serviceDisabled);
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    switch (permission) {
      case LocationPermission.denied:
        throw const LocationException(LocationFailure.permissionDenied);
      case LocationPermission.deniedForever:
        throw const LocationException(LocationFailure.permissionDeniedForever);
      case LocationPermission.whileInUse:
      case LocationPermission.always:
      case LocationPermission.unableToDetermine:
        break;
    }
    try {
      final p = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: timeLimit,
        ),
      );
      return UserLocation(
        position: GeoPoint(p.latitude, p.longitude),
        accuracyMeters: p.accuracy,
        capturedAt: p.timestamp.toUtc(),
        origin: p.isMocked ? LocationOrigin.mocked : LocationOrigin.gps,
      );
    } on TimeoutException {
      throw const LocationException(LocationFailure.unavailable);
    } on LocationServiceDisabledException {
      throw const LocationException(LocationFailure.serviceDisabled);
    } on PermissionDeniedException {
      throw const LocationException(LocationFailure.permissionDenied);
    } catch (_) {
      throw const LocationException(LocationFailure.unavailable);
    }
  }

  @override
  Future<void> openSettings(LocationFailure reason) async {
    if (reason == LocationFailure.serviceDisabled) {
      await Geolocator.openLocationSettings();
    } else {
      await Geolocator.openAppSettings();
    }
  }
}
