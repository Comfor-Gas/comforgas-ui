class ChoferExterno {
  final String idChoferExterno;
  final String nombre;
  final String? documento;
  final bool asignado;

  const ChoferExterno({
    required this.idChoferExterno,
    required this.nombre,
    this.documento,
    this.asignado = false,
  });

  String get claveNombre => normalizarNombreChofer(nombre);

  factory ChoferExterno.fromJson(Map<String, dynamic> json) {
    final documento = json['documento']?.toString().trim();
    final nombre = (json['nombre'] ?? json['fullName'] ?? '').toString().trim();
    final id = (json['idChoferExterno'] ?? json['id'] ?? documento ?? nombre).toString();
    return ChoferExterno(
      idChoferExterno: id,
      nombre: nombre,
      documento: documento == null || documento.isEmpty ? null : documento,
      asignado: json['asignado'] == true,
    );
  }
}

String normalizarNombreChofer(String nombre) =>
    nombre.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
