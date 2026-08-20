import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:geolocator/geolocator.dart';

class LocationServiceException implements Exception {
  final String message;
  LocationServiceException(this.message);

  @override
  String toString() => message;
}


class LocationCheckIn {
  final double latitud;
  final double longitud;
  final double precisionMetros;
  final bool esPrecisa;
  final DateTime timestamp;

  const LocationCheckIn({
    required this.latitud,
    required this.longitud,
    required this.precisionMetros,
    required this.esPrecisa,
    required this.timestamp,
  });
}


class LocationService {
  LocationService._();

  static final LocationService instance = LocationService._();


  static const double _umbralPrecisionMetros = 60;
  static const double radioCheckInMetros = 150;
  static const double _radioTierraMetros = 6371000.0;

  StreamSubscription<Position>? _backgroundSubscription;
  Position? lastKnownPosition;

  bool get siguiendoEnSegundoPlano => _backgroundSubscription != null;

  Future<void> _asegurarPermisos() async {
    final servicioActivo = await Geolocator.isLocationServiceEnabled();
    if (!servicioActivo) {
      throw LocationServiceException(
        'Activa la ubicacion (GPS) del dispositivo para iniciar la visita.',
      );
    }

    var permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
      if (permiso == LocationPermission.denied) {
        throw LocationServiceException(
          'Necesitamos el permiso de ubicacion para registrar el check-in de la visita.',
        );
      }
    }

    if (permiso == LocationPermission.deniedForever) {
      throw LocationServiceException(
        'El permiso de ubicacion esta bloqueado. Habilitalo desde los ajustes del sistema para continuar.',
      );
    }
  }


  Future<LocationCheckIn> obtenerUbicacionActual() async {
    await _asegurarPermisos();

    late final Position position;
    try {
      position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
    } catch (_) {
      throw LocationServiceException(
        'No se pudo obtener tu ubicacion. Verifica que el GPS este activado e intenta de nuevo.',
      );
    }

    lastKnownPosition = position;

    return LocationCheckIn(
      latitud: position.latitude,
      longitud: position.longitude,
      precisionMetros: position.accuracy,
      esPrecisa: position.accuracy <= _umbralPrecisionMetros,
      timestamp: position.timestamp,
    );
  }


  double distanciaMetros(double lat1, double lon1, double lat2, double lon2) {
    final dLat = _aRadianes(lat2 - lat1);
    final dLon = _aRadianes(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_aRadianes(lat1)) *
            math.cos(_aRadianes(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return _radioTierraMetros * c;
  }

  bool estaCercaDe(
    LocationCheckIn checkIn,
    double latObjetivo,
    double lonObjetivo,
  ) {
    final distancia = distanciaMetros(
      checkIn.latitud,
      checkIn.longitud,
      latObjetivo,
      lonObjetivo,
    );
    final tolerancia = checkIn.precisionMetros.isFinite && checkIn.precisionMetros > 0
        ? checkIn.precisionMetros
        : 0;
    return distancia <= radioCheckInMetros + tolerancia;
  }

  double _aRadianes(double grados) => grados * math.pi / 180.0;

  Future<void> iniciarSeguimientoEnSegundoPlano({
    required void Function(Position position) onPosition,
    String tituloNotificacion = 'Comfor Gas - Visita en curso',
    String textoNotificacion = 'Registrando tu ubicacion mientras dure la visita.',
  }) async {
    await _asegurarPermisos();

    final permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.whileInUse) {
      await Geolocator.requestPermission();
    }

    await detenerSeguimientoEnSegundoPlano();

    final settings = _construirConfiguracionPorPlataforma(
      titulo: tituloNotificacion,
      texto: textoNotificacion,
    );

    _backgroundSubscription = Geolocator.getPositionStream(locationSettings: settings).listen(
      (position) {
        lastKnownPosition = position;
        onPosition(position);
      },
      onError: (_) {
      },
      cancelOnError: false,
    );
  }

  Future<void> detenerSeguimientoEnSegundoPlano() async {
    await _backgroundSubscription?.cancel();
    _backgroundSubscription = null;
  }

  LocationSettings _construirConfiguracionPorPlataforma({
    required String titulo,
    required String texto,
  }) {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 15,
        intervalDuration: const Duration(seconds: 10),
        foregroundNotificationConfig: ForegroundNotificationConfig(
          notificationTitle: titulo,
          notificationText: texto,
          enableWakeLock: true,
        ),
      );
    }

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.high,
        activityType: ActivityType.other,
        distanceFilter: 15,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
        allowBackgroundLocationUpdates: true,
      );
    }

    return const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 15);
  }

  void dispose() {
    _backgroundSubscription?.cancel();
    _backgroundSubscription = null;
  }
}
