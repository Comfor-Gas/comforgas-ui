import 'visita_estado.dart';
import '../utils/json_parsing.dart';


class VisitaModel {
  final int? idVisita;
  final int? idAgendaItem;
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
  final String? horaFinPlanificada;
  final bool geolocalizacionValida;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const VisitaModel({
    this.idVisita,
    this.idAgendaItem,
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
    this.horaFinPlanificada,
    this.geolocalizacionValida = false,
    this.createdAt,
    this.updatedAt,
  });

  static Map<String, dynamic> _buildRutaSnapshot(Map<String, dynamic> json) {
    final base = json['rutaSnapshot'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(json['rutaSnapshot'] as Map<String, dynamic>)
        : <String, dynamic>{};
    final vendedor = json['vendedor'];
    final acompanante = json['acompanante'];
    final movil = json['movil'];
    if (vendedor is String && vendedor.trim().isNotEmpty) {
      base.putIfAbsent('vendedor', () => vendedor);
    }
    if (acompanante is String && acompanante.trim().isNotEmpty) {
      base.putIfAbsent('acompanante', () => acompanante);
    }
    if (movil != null) {
      base.putIfAbsent('movil', () => movil);
    }
    return base;
  }

  factory VisitaModel.fromJson(Map<String, dynamic> json) {
    return VisitaModel(
      idVisita: parseInt(json['idVisita']),
      idAgendaItem: parseInt(json['idAgendaItem']),
      idUsuario: (json['idUsuario'] ?? '').toString(),
      nombreUsuario: json['nombreUsuario'] as String?,
      idSucursal: parseInt(json['idSucursal']) ?? 0,
      idRuta: parseInt(json['idRuta']) ?? 0,
      sucursalSnapshot: json['sucursalSnapshot'] is Map<String, dynamic>
          ? json['sucursalSnapshot'] as Map<String, dynamic>
          : const {},
      rutaSnapshot: _buildRutaSnapshot(json),
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
      horaInicioPlanificada:
          (json['horaInicio'] ?? json['horaInicioPlanificada']) as String?,
      horaFinPlanificada: (json['horaFin'] ?? json['horaFinPlanificada']) as String?,
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
    int? idAgendaItem,
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
    String? horaFinPlanificada,
    bool? geolocalizacionValida,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VisitaModel(
      idVisita: idVisita ?? this.idVisita,
      idAgendaItem: idAgendaItem ?? this.idAgendaItem,
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
      horaFinPlanificada: horaFinPlanificada ?? this.horaFinPlanificada,
      geolocalizacionValida:
          geolocalizacionValida ?? this.geolocalizacionValida,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  double? get sucursalLatitud => parseDouble(sucursalSnapshot['latitud']);
  double? get sucursalLongitud => parseDouble(sucursalSnapshot['longitud']);
}
