import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  ConnectivityService._();

  static final ConnectivityService instance = ConnectivityService._();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  Future<bool> tieneConexion() async {
    final resultados = await Connectivity().checkConnectivity();
    return _algunaConexion(resultados);
  }

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
