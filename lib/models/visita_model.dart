import 'visita_estado.dart';
import '../utils/json_parsing.dart';


class VisitaModel {
  final int? idVisita;
  final String idUsuario;
  final String? nombreUsuario;
  final int idSucursal;
  final int idRuta;
  final Map<String, dynamic> sucursalSnapshot;
  final Map<String, dynamic> rutaSnapshot;
  final int ordenVisita;
  final VisitaEstado estadoVisita;
  final DateTime? fecha;
  final String? observaciones;
  final DateTime? timestampInicio;
  final DateTime? timestampFin;
  final double? latitudInicio;
  final double? longitudInicio;
  final double? latitudFin;
  final double? longitudFin;
  final String? horaInicioPlanificada;
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
    this.latitudFin,
    this.longitudFin,
    this.horaInicioPlanificada,
    this.geolocalizacionValida = false,
    this.createdAt,
    this.updatedAt,
  });

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
      latitudFin: parseDouble(json['latitudFin']),
      longitudFin: parseDouble(json['longitudFin']),
      horaInicioPlanificada: json['horaInicioPlanificada'] as String?,
      geolocalizacionValida: json['geolocalizacionValida'] == true,
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
    );
  }

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
    double? latitudFin,
    double? longitudFin,
    String? horaInicioPlanificada,
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
      latitudFin: latitudFin ?? this.latitudFin,
      longitudFin: longitudFin ?? this.longitudFin,
      horaInicioPlanificada: horaInicioPlanificada ?? this.horaInicioPlanificada,
      geolocalizacionValida:
          geolocalizacionValida ?? this.geolocalizacionValida,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  double? get sucursalLatitud => parseDouble(sucursalSnapshot['latitud']);
  double? get sucursalLongitud => parseDouble(sucursalSnapshot['longitud']);
}
