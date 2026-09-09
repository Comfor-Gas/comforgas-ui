import 'dart:async' show unawaited;
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../repositories/ubicacion_repository.dart';
import 'location_service.dart';

class UbicacionTrackingService {
  UbicacionTrackingService._();

  static final UbicacionTrackingService instance = UbicacionTrackingService._();

  static const Duration _intervaloEnvio = Duration(seconds: 30);

  final _locationService = LocationService.instance;

  UbicacionRepository? _repo;
  bool _activo = false;
  DateTime? _ultimoEnvio;
  int? _idVisitaActual;

  bool get activo => _activo;

  Future<void> iniciar(http.Client apiClient) async {
    _repo = UbicacionRepository(apiClient);
    if (_activo) return;
    try {
      await _locationService.iniciarSeguimientoEnSegundoPlano(
        onPosition: _onPosition,
        tituloNotificacion: 'Comfor Gas',
        textoNotificacion: 'Compartiendo tu ubicación con la central.',
      );
      _activo = true;
      debugPrint('[TRACK] seguimiento iniciado');
    } catch (e) {
      _activo = false;
      debugPrint('[TRACK] no se pudo iniciar el seguimiento: $e');
    }
  }

  void setVisitaActual(int? idVisita) {
    _idVisitaActual = idVisita;
  }

  Future<void> detener() async {
    _activo = false;
    _repo = null;
    _ultimoEnvio = null;
    _idVisitaActual = null;
    await _locationService.detenerSeguimientoEnSegundoPlano();
  }

  void _onPosition(Position position) {
    debugPrint('[TRACK] fix ${position.latitude}, ${position.longitude}');
    final repo = _repo;
    if (repo == null) return;
    final ahora = DateTime.now();
    final ultimo = _ultimoEnvio;
    if (ultimo != null && ahora.difference(ultimo) < _intervaloEnvio) {
      debugPrint('[TRACK] descartado por throttle (${_intervaloEnvio.inSeconds}s)');
      return;
    }
    _ultimoEnvio = ahora;
    debugPrint('[TRACK] enviando ${position.latitude}, ${position.longitude} idVisita=$_idVisitaActual');
    unawaited(repo.enviar(
      latitud: position.latitude,
      longitud: position.longitude,
      precisionMetros: position.accuracy,
      timestamp: position.timestamp,
      idVisita: _idVisitaActual,
    ));
  }
}
