import '../utils/json_parsing.dart';

const int kCupoBaseCamion = 200;

enum EstadoCamion { enRuta, enEspera, enDeposito }

EstadoCamion? estadoCamionDesdeBackend(String? valor) {
  switch (valor?.toUpperCase()) {
    case 'EN_RUTA':
      return EstadoCamion.enRuta;
    case 'EN_ESPERA':
      return EstadoCamion.enEspera;
    case 'EN_DEPOSITO':
      return EstadoCamion.enDeposito;
    default:
      return null;
  }
}

class RepartidorInfo {
  final String id;
  final String nombre;
  final String email;

  const RepartidorInfo({
    required this.id,
    required this.nombre,
    required this.email,
  });

  factory RepartidorInfo.fromJson(Map<String, dynamic> json) {
    return RepartidorInfo(
      id: (json['id'] ?? '').toString(),
      nombre: (json['nombre'] ?? json['fullName'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
    );
  }
}

class DepositoCamion {
  final int id;
  final String nombre;
  final String? patente;
  final int? numeroMovil;
  final String? descripcion;
  final bool activo;
  final RepartidorInfo? repartidor;
  final int llenos;
  final int vacios;
  final int vaciasDelDia;
  final bool stockCargado;
  final int? cupoBaseBackend;
  final EstadoCamion? estadoBackend;

  const DepositoCamion({
    required this.id,
    required this.nombre,
    this.patente,
    this.numeroMovil,
    this.descripcion,
    this.activo = true,
    this.repartidor,
    this.llenos = 0,
    this.vacios = 0,
    this.vaciasDelDia = 0,
    this.stockCargado = false,
    this.cupoBaseBackend,
    this.estadoBackend,
  });

  int get cupoBase =>
      (cupoBaseBackend != null && cupoBaseBackend! > 0) ? cupoBaseBackend! : kCupoBaseCamion;

  int get faltante {
    final f = cupoBase - llenos;
    return f < 0 ? 0 : f;
  }

  double get progreso {
    if (cupoBase <= 0) return 0;
    final p = llenos / cupoBase;
    if (p < 0) return 0;
    if (p > 1) return 1;
    return p;
  }

  bool get tieneChofer => repartidor != null;

  String get choferNombre =>
      repartidor?.nombre.isNotEmpty == true ? repartidor!.nombre : 'Sin asignar';

  String get patenteVisible =>
      patente?.isNotEmpty == true ? patente! : 'Sin patente';

  EstadoCamion get estado {
    if (estadoBackend != null) return estadoBackend!;
    if (!tieneChofer) return EstadoCamion.enDeposito;
    if (stockCargado && llenos <= 0) return EstadoCamion.enEspera;
    return EstadoCamion.enRuta;
  }

  DepositoCamion copyWith({
    String? nombre,
    String? patente,
    int? numeroMovil,
    String? descripcion,
    bool? activo,
    RepartidorInfo? repartidor,
    bool limpiarRepartidor = false,
    int? llenos,
    int? vacios,
    int? vaciasDelDia,
    bool? stockCargado,
    int? cupoBaseBackend,
    EstadoCamion? estadoBackend,
  }) {
    return DepositoCamion(
      id: id,
      nombre: nombre ?? this.nombre,
      patente: patente ?? this.patente,
      numeroMovil: numeroMovil ?? this.numeroMovil,
      descripcion: descripcion ?? this.descripcion,
      activo: activo ?? this.activo,
      repartidor: limpiarRepartidor ? null : (repartidor ?? this.repartidor),
      llenos: llenos ?? this.llenos,
      vacios: vacios ?? this.vacios,
      vaciasDelDia: vaciasDelDia ?? this.vaciasDelDia,
      stockCargado: stockCargado ?? this.stockCargado,
      cupoBaseBackend: cupoBaseBackend ?? this.cupoBaseBackend,
      estadoBackend: estadoBackend ?? this.estadoBackend,
    );
  }

  factory DepositoCamion.fromJson(Map<String, dynamic> json) {
    final rep = json['repartidor'];
    return DepositoCamion(
      id: parseInt(json['id']) ?? 0,
      nombre: (json['nombre'] ?? '').toString(),
      patente: json['vehiculoPatente']?.toString(),
      numeroMovil: parseInt(json['numeroMovil']),
      descripcion: json['descripcion']?.toString(),
      activo: json['activo'] == true,
      repartidor: rep is Map<String, dynamic> ? RepartidorInfo.fromJson(rep) : null,
      cupoBaseBackend: parseInt(json['cupoBase']),
      estadoBackend: estadoCamionDesdeBackend(json['estadoOperativo']?.toString()),
    );
  }

  factory DepositoCamion.fromResumenJson(Map<String, dynamic> json) {
    final rep = json['repartidor'];
    return DepositoCamion(
      id: parseInt(json['id']) ?? 0,
      nombre: (json['nombre'] ?? '').toString(),
      patente: json['vehiculoPatente']?.toString(),
      numeroMovil: parseInt(json['numeroMovil']),
      activo: json['activo'] == true,
      repartidor: rep is Map<String, dynamic> ? RepartidorInfo.fromJson(rep) : null,
      llenos: parseInt(json['llenos']) ?? 0,
      vacios: parseInt(json['vacios']) ?? 0,
      vaciasDelDia: parseInt(json['vaciasDelDia']) ?? 0,
      stockCargado: true,
      cupoBaseBackend: parseInt(json['cupoBase']),
      estadoBackend: estadoCamionDesdeBackend(json['estadoOperativo']?.toString()),
    );
  }
}
