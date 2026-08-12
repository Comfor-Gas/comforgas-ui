import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

/// Envuelve `connectivity_plus` para saber si hay conectividad y para
/// detectar el momento exacto en que el dispositivo pasa de sin-red a
/// con-red, que es cuando conviene disparar la sincronización de la cola
/// offline.
///
/// Importante: esto detecta conectividad de red (WiFi/datos activos), no
/// necesariamente que el backend sea alcanzable. Por eso el intento de
/// sincronización real igual debe manejar sus propios timeouts/errores.
class ConnectivityService {
  ConnectivityService._();

  static final ConnectivityService instance = ConnectivityService._();

  StreamSubscription<List<ConnectivityResult>>? _subscription;

  Future<bool> tieneConexion() async {
    final resultados = await Connectivity().checkConnectivity();
    return _algunaConexion(resultados);
  }

  /// Se suscribe a los cambios de conectividad y llama a [onConectado]
  /// cada vez que el dispositivo pasa de sin-red a con-red. Solo debe
  /// haber un listener activo a la vez: llamar de nuevo reemplaza al
  /// anterior.
  void escucharReconexion(void Function() onConectado) {
    _subscription?.cancel();
    bool ultimoEstadoConectado = true;
    _subscription = Connectivity().onConnectivityChanged.listen((resultados) {
      final conectado = _algunaConexion(resultados);
      if (conectado && !ultimoEstadoConectado) {
        onConectado();
      }
      ultimoEstadoConectado = conectado;
    });
  }

  bool _algunaConexion(List<ConnectivityResult> resultados) {
    return resultados.any((r) => r != ConnectivityResult.none);
  }

  void detener() {
    _subscription?.cancel();
    _subscription = null;
  }
}
