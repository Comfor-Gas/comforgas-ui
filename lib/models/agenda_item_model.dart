import 'visita_estado.dart';
import 'visita_model.dart';
import '../utils/json_parsing.dart';

class AgendaItemModel {
  final int idAgendaItem;
  final String origen;
  final int? idClienteExt;
  final int idSucursal;
  final int idRuta;
  final int orden;
  final DateTime? fecha;
  final Map<String, dynamic> sucursalSnapshot;
  final String? nombre;
  final String? domicilio;
  final String? barrio;
  final String? ciudad;
  final String? telefono;
  final int? precio10;
  final int? precio15;
  final int? precio30;
  final int? precio45;
  final bool? comodato10;
  final bool? comodato11;
  final bool? comodato12;
  final DateTime? ultimaBajada;
  final String? horaInicio;
  final String? horaFin;
  final String? vendedor;
  final String? acompanante;
  final int? idVisita;
  final VisitaEstado? estadoEjecucion;

  const AgendaItemModel({
    required this.idAgendaItem,
    required this.origen,
    this.idClienteExt,
    required this.idSucursal,
    required this.idRuta,
    required this.orden,
    this.fecha,
    required this.sucursalSnapshot,
    this.nombre,
    this.domicilio,
    this.barrio,
    this.ciudad,
    this.telefono,
    this.precio10,
    this.precio15,
    this.precio30,
    this.precio45,
    this.comodato10,
    this.comodato11,
    this.comodato12,
    this.ultimaBajada,
    this.horaInicio,
    this.horaFin,
    this.vendedor,
    this.acompanante,
    this.idVisita,
    this.estadoEjecucion,
  });

  factory AgendaItemModel.fromJson(Map<String, dynamic> json) {
    return AgendaItemModel(
      idAgendaItem: parseInt(json['idAgendaItem']) ?? 0,
      origen: (json['origen'] ?? 'PLANIFICADO').toString(),
      idClienteExt: parseInt(json['idClienteExt']),
      idSucursal: parseInt(json['idSucursal']) ?? 0,
      idRuta: parseInt(json['idRuta']) ?? 0,
      orden: parseInt(json['orden']) ?? 0,
      fecha: parseDate(json['fecha']),
      sucursalSnapshot: json['sucursalSnapshot'] is Map<String, dynamic>
          ? json['sucursalSnapshot'] as Map<String, dynamic>
          : const {},
      nombre: json['nombre'] as String?,
      domicilio: json['domicilio'] as String?,
      barrio: json['barrio'] as String?,
      ciudad: json['ciudad'] as String?,
      telefono: json['telefono'] as String?,
      precio10: parseInt(json['precio10']),
      precio15: parseInt(json['precio15']),
      precio30: parseInt(json['precio30']),
      precio45: parseInt(json['precio45']),
      comodato10: json['comodato10'] as bool?,
      comodato11: json['comodato11'] as bool?,
      comodato12: json['comodato12'] as bool?,
      ultimaBajada: parseDate(json['ultimaBajada'] ?? json['ultimaCompra']),
      horaInicio: json['horaInicio'] as String?,
      horaFin: json['horaFin'] as String?,
      vendedor: json['vendedor'] as String?,
      acompanante: json['acompanante'] as String?,
      idVisita: parseInt(json['idVisita']),
      estadoEjecucion: json['estadoEjecucion'] == null
          ? null
          : VisitaEstadoMapper.fromValue(json['estadoEjecucion']),
    );
  }

  AgendaItemModel copyWith({DateTime? fecha}) {
    return AgendaItemModel(
      idAgendaItem: idAgendaItem,
      origen: origen,
      idClienteExt: idClienteExt,
      idSucursal: idSucursal,
      idRuta: idRuta,
      orden: orden,
      fecha: fecha ?? this.fecha,
      sucursalSnapshot: sucursalSnapshot,
      nombre: nombre,
      domicilio: domicilio,
      barrio: barrio,
      ciudad: ciudad,
      telefono: telefono,
      precio10: precio10,
      precio15: precio15,
      precio30: precio30,
      precio45: precio45,
      comodato10: comodato10,
      comodato11: comodato11,
      comodato12: comodato12,
      ultimaBajada: ultimaBajada,
      horaInicio: horaInicio,
      horaFin: horaFin,
      vendedor: vendedor,
      acompanante: acompanante,
      idVisita: idVisita,
      estadoEjecucion: estadoEjecucion,
    );
  }

  /// Estado a efectos de la UI: si el chofer todavía no hizo check-in
  /// (`estadoEjecucion == null`), se trata como PENDIENTE.
  VisitaEstado get estadoEfectivo => estadoEjecucion ?? VisitaEstado.pendiente;

  /// Convierte este ítem de agenda al `VisitaModel` que ya consumen las
  /// pantallas del chofer. `idUsuario` se pasa aparte porque
  /// `AgendaItemResponse` no lo incluye (siempre es el chofer autenticado).
  VisitaModel toVisitaModel(String idUsuario) {
    final snapshot = <String, dynamic>{
      ...sucursalSnapshot,
      if (idClienteExt != null) 'clienteId': idClienteExt,
      if (nombre != null && nombre!.trim().isNotEmpty) 'nombre': nombre,
      if (domicilio != null && domicilio!.trim().isNotEmpty) 'direccion': domicilio,
      if (barrio != null && barrio!.trim().isNotEmpty) 'barrio': barrio,
      if (ciudad != null && ciudad!.trim().isNotEmpty) 'ciudad': ciudad,
      if (telefono != null && telefono!.trim().isNotEmpty) 'telefono': telefono,
      if (comodato10 != null) 'comodato10': comodato10,
      if (comodato11 != null) 'comodato11': comodato11,
      if (comodato12 != null) 'comodato12': comodato12,
      if (ultimaBajada != null) 'ultimaBajada': ultimaBajada!.toIso8601String(),
    };

    return VisitaModel(
      idVisita: idVisita,
      idAgendaItem: idAgendaItem,
      idUsuario: idUsuario,
      idSucursal: idSucursal,
      idRuta: idRuta,
      sucursalSnapshot: snapshot,
      rutaSnapshot: {
        if (vendedor != null) 'vendedor': vendedor,
        if (acompanante != null) 'acompanante': acompanante,
      },
      ordenVisita: orden,
      estadoVisita: estadoEfectivo,
      fecha: fecha,
      horaInicioPlanificada: horaInicio,
      horaFinPlanificada: horaFin,
    );
  }
}
