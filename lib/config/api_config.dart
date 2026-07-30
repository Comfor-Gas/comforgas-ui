class ApiConfig {
  /// Base del backend Spring Boot.
  ///
  /// - `10.0.2.2` es el alias del `localhost` de la máquina host desde el
  ///   emulador de Android.
  /// - El puerto por defecto de Spring Boot es `8080`.
  ///
  /// Para dispositivo físico reemplazar por la IP de la PC en la red local
  /// (ej. `http://192.168.0.10:8080`).
  static const String baseUrl = 'http://10.0.2.2:8080';

  // Los controllers del backend están bajo el prefijo `/api`.
  static const String loginPath = '/api/auth/login';
  static const String refreshPath = '/api/auth/refresh';
}
