class NetworkException implements Exception {
  final String message;

  NetworkException([
    this.message = 'No se pudo conectar con el servidor. Revisa tu conexión.',
  ]);

  @override
  String toString() => message;
}
