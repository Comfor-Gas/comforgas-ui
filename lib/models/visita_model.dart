import 'visita_estado.dart';
import '../utils/json_parsing.dart';

/// Visita de un chofer a una sucursal, dentro de una ruta planificada.
///
/// Modelo compartido entre la Web (Admin, que crea/gestiona visitas vía
/// `POST /api/admin/visitas`) y la app Móvil (Chofer, que consulta su
/// agenda vía `GET /api/visitas/{idUsuario}/{fecha}`).
///
/// OJO con `fecha`: el backend tiene dos respuestas distintas para "una
/// visita" según el endpoint:
///  - `VisitaResponse` (admin, CRUD completo) SÍ incluye `fecha`.
///  - `VisitaFechaResponse` (agenda del chofer) NO la incluye, porque ya
///    viene implícita en el path param de la consulta.
/// Por eso `fecha` es nullable acá. `VisitaRepository.getVisitasPorUsuarioYFecha`
/// completa `fecha` automáticamente con el valor consultado, así el
/// modelo queda siempre completo del lado del cliente.
///
/// Las evidencias fotográficas NO viajan dentro de este JSON — son un
/// recurso aparte (`GET /api/evidenciasfotograficas?idVisita={id}`).
class VisitaModel {
  final int? idVisita;

  /// UUID del chofer (coincide con el id del usuario autenticado).
  final String idUsuario;
  final String? nombreUsuario;

  final int idSucursal;
  final int idRuta;

  /// Snapshot inmutable de la sucursal al momento de crear la visita.
  final Map<String, dynamic> sucursalSnapshot;

  /// Snapshot inmutable de la ruta al momento de crear la visita.
  final Map<String, dynamic> rutaSnapshot;

  final int ordenVisita;
  final VisitaEstado estadoVisita;

  final DateTime? fecha;
  final String? observaciones;

  final DateTime? timestampInicio;
  final DateTime? timestampFin;

  final double? latitudInicio;
  final double? longitudInicio;
  final bool geolocalizacionValida;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  const VisitaModel({
    this.idVisita,
    required this.idUsuario,
    this.nombreUsuario,
    required this.idSucursal,
    required this.idRuta,
    required this.sucursalSnapshot,
    required this.rutaSnapshot,
    required this.ordenVisita,
    this.estadoVisita = VisitaEstado.pendiente,
    this.fecha,
    this.observaciones,
    this.timestampInicio,
    this.timestampFin,
    this.latitudInicio,
    this.longitudInicio,
    this.geolocalizacionValida = false,
    this.createdAt,
    this.updatedAt,
  });

  /// Sirve tanto para `VisitaResponse` (admin) como `VisitaFechaResponse`
  /// (agenda chofer) — esta última simplemente no trae `fecha`.
  factory VisitaModel.fromJson(Map<String, dynamic> json) {
    return VisitaModel(
      idVisita: parseInt(json['idVisita']),
      idUsuario: (json['idUsuario'] ?? '').toString(),
      nombreUsuario: json['nombreUsuario'] as String?,
      idSucursal: parseInt(json['idSucursal']) ?? 0,
      idRuta: parseInt(json['idRuta']) ?? 0,
      sucursalSnapshot: json['sucursalSnapshot'] is Map<String, dynamic>
          ? json['sucursalSnapshot'] as Map<String, dynamic>
          : const {},
      rutaSnapshot: json['rutaSnapshot'] is Map<String, dynamic>
          ? json['rutaSnapshot'] as Map<String, dynamic>
          : const {},
      ordenVisita: parseInt(json['ordenVisita']) ?? 0,
      estadoVisita: VisitaEstadoMapper.fromValue(json['estadoVisita']),
      fecha: parseDate(json['fecha']),
      observaciones: json['observaciones'] as String?,
      timestampInicio: parseDate(json['timestampInicio']),
      timestampFin: parseDate(json['timestampFin']),
      latitudInicio: parseDouble(json['latitudInicio']),
      longitudInicio: parseDouble(json['longitudInicio']),
      geolocalizacionValida: json['geolocalizacionValida'] == true,
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
    );
  }

  /// Body para `POST /api/admin/visitas` (forma de `VisitaRequest`).
  /// No incluye `idVisita`/`nombreUsuario`/`createdAt`/`updatedAt`: esos
  /// los asigna el backend, no se envían.
  Map<String, dynamic> toJson() {
    return {
      'idUsuario': idUsuario,
      'idSucursal': idSucursal,
      'idRuta': idRuta,
      'sucursalSnapshot': sucursalSnapshot,
      'rutaSnapshot': rutaSnapshot,
      'ordenVisita': ordenVisita,
      'estadoVisita': VisitaEstadoMapper.toValue(estadoVisita),
      if (fecha != null) 'fecha': formatDateOnly(fecha!),
      if (observaciones != null) 'observaciones': observaciones,
      if (timestampInicio != null)
        'timestampInicio': timestampInicio!.toIso8601String(),
      if (timestampFin != null)
        'timestampFin': timestampFin!.toIso8601String(),
      if (latitudInicio != null) 'latitudInicio': latitudInicio,
      if (longitudInicio != null) 'longitudInicio': longitudInicio,
      'geolocalizacionValida': geolocalizacionValida,
    };
  }

  VisitaModel copyWith({
    int? idVisita,
    String? idUsuario,
    String? nombreUsuario,
    int? idSucursal,
    int? idRuta,
    Map<String, dynamic>? sucursalSnapshot,
    Map<String, dynamic>? rutaSnapshot,
    int? ordenVisita,
    VisitaEstado? estadoVisita,
    DateTime? fecha,
    String? observaciones,
    DateTime? timestampInicio,
    DateTime? timestampFin,
    double? latitudInicio,
    double? longitudInicio,
    bool? geolocalizacionValida,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VisitaModel(
      idVisita: idVisita ?? this.idVisita,
      idUsuario: idUsuario ?? this.idUsuario,
      nombreUsuario: nombreUsuario ?? this.nombreUsuario,
      idSucursal: idSucursal ?? this.idSucursal,
      idRuta: idRuta ?? this.idRuta,
      sucursalSnapshot: sucursalSnapshot ?? this.sucursalSnapshot,
      rutaSnapshot: rutaSnapshot ?? this.rutaSnapshot,
      ordenVisita: ordenVisita ?? this.ordenVisita,
      estadoVisita: estadoVisita ?? this.estadoVisita,
      fecha: fecha ?? this.fecha,
      observaciones: observaciones ?? this.observaciones,
      timestampInicio: timestampInicio ?? this.timestampInicio,
      timestampFin: timestampFin ?? this.timestampFin,
      latitudInicio: latitudInicio ?? this.latitudInicio,
      longitudInicio: longitudInicio ?? this.longitudInicio,
      geolocalizacionValida:
          geolocalizacionValida ?? this.geolocalizacionValida,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
