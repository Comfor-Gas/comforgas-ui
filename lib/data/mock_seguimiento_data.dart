import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../models/visita_alerta.dart';
import '../theme/app_colors.dart';

enum SeguimientoEstado { pendiente, enCurso, visitado, asignado, cancelada }
extension SeguimientoEstadoData on SeguimientoEstado {
  String get label {
    switch (this) {
      case SeguimientoEstado.pendiente:
        return 'PENDIENTE';
      case SeguimientoEstado.enCurso:
        return 'EN CURSO';
      case SeguimientoEstado.visitado:
        return 'VISITADO';
      case SeguimientoEstado.asignado:
        return 'ASIGNADO';
      case SeguimientoEstado.cancelada:
        return 'CANCELADA';
    }
  }

  Color get color {
    switch (this) {
      case SeguimientoEstado.pendiente:
        return AppColors.badgeBlue;
      case SeguimientoEstado.enCurso:
        return AppColors.badgeAmber;
      case SeguimientoEstado.visitado:
        return AppColors.badgeGreen;
      case SeguimientoEstado.asignado:
        return AppColors.steelBlue;
      case SeguimientoEstado.cancelada:
        return AppColors.badgeRed;
    }
  }

  IconData get icon {
    switch (this) {
      case SeguimientoEstado.pendiente:
        return Icons.hourglass_empty;
      case SeguimientoEstado.enCurso:
        return Icons.local_shipping_outlined;
      case SeguimientoEstado.visitado:
        return Icons.check_circle_outline;
      case SeguimientoEstado.asignado:
        return Icons.assignment_turned_in_outlined;
      case SeguimientoEstado.cancelada:
        return Icons.cancel_outlined;
    }
  }
}

class VisitaSeguimientoMock {
  final String id;
  final String choferId;
  final String choferNombre;
  final String cliente;
  final String sucursal;
  final int numeroSucursal;
  final DateTime fecha;
  final String horaProgramada;
  final String? horaCheckIn;
  final SeguimientoEstado estado;
  final VisitaAlertaTipo alerta;
  final LatLng posicion;
  final int ordenRuta;

  const VisitaSeguimientoMock({
    required this.id,
    required this.choferId,
    required this.choferNombre,
    required this.cliente,
    required this.sucursal,
    required this.numeroSucursal,
    required this.fecha,
    required this.horaProgramada,
    this.horaCheckIn,
    required this.estado,
    this.alerta = VisitaAlertaTipo.ninguna,
    required this.posicion,
    required this.ordenRuta,
  });

  bool get tieneAlerta => alerta != VisitaAlertaTipo.ninguna;
}

class ChoferRutaMock {
  final String choferId;
  final String choferNombre;
  final Color color;
  final LatLng posicionActual;

  const ChoferRutaMock({
    required this.choferId,
    required this.choferNombre,
    required this.color,
    required this.posicionActual,
  });
}


const LatLng formosaCenter = LatLng(-26.1849, -58.1731);

const List<ChoferRutaMock> mockRutasChofer = [
  ChoferRutaMock(
    choferId: 'c1',
    choferNombre: 'Carlos Gómez',
    color: Color(0xFF2F80ED),
    posicionActual: LatLng(-26.1799, -58.1798),
  ),
  ChoferRutaMock(
    choferId: 'c2',
    choferNombre: 'Luis Pérez',
    color: Color(0xFFE05348),
    posicionActual: LatLng(-26.1920, -58.1665),
  ),
  ChoferRutaMock(
    choferId: 'c3',
    choferNombre: 'Marta Ibáñez',
    color: Color(0xFFE0A030),
    posicionActual: LatLng(-26.1885, -58.1885),
  ),
  ChoferRutaMock(
    choferId: 'c4',
    choferNombre: 'Jorge Ramírez',
    color: Color(0xFF8E9AA8),
    posicionActual: LatLng(-26.1760, -58.1610),
  ),
];

final DateTime _hoy = DateTime.now();

final List<VisitaSeguimientoMock> mockVisitasSeguimiento = [
  VisitaSeguimientoMock(
    id: 'v1',
    choferId: 'c1',
    choferNombre: 'Carlos Gómez',
    cliente: 'Almacén Don Julio',
    sucursal: 'Sucursal Centro',
    numeroSucursal: 456,
    fecha: _hoy,
    horaProgramada: '09:30 AM',
    horaCheckIn: '09:30 AM',
    estado: SeguimientoEstado.visitado,
    posicion: const LatLng(-26.1799, -58.1798),
    ordenRuta: 1,
  ),
  VisitaSeguimientoMock(
    id: 'v2',
    choferId: 'c1',
    choferNombre: 'Carlos Gómez',
    cliente: 'Distribuidora San Marcos',
    sucursal: 'Sucursal Norte',
    numeroSucursal: 457,
    fecha: _hoy,
    horaProgramada: '10:15 AM',
    estado: SeguimientoEstado.enCurso,
    alerta: VisitaAlertaTipo.gpsDesvio,
    posicion: const LatLng(-26.1735, -58.1830),
    ordenRuta: 2,
  ),
  VisitaSeguimientoMock(
    id: 'v3',
    choferId: 'c1',
    choferNombre: 'Carlos Gómez',
    cliente: 'Kiosco La Esquina',
    sucursal: 'Sucursal Centro',
    numeroSucursal: 456,
    fecha: _hoy,
    horaProgramada: '11:00 AM',
    estado: SeguimientoEstado.pendiente,
    posicion: const LatLng(-26.1680, -58.1870),
    ordenRuta: 3,
  ),

  VisitaSeguimientoMock(
    id: 'v4',
    choferId: 'c2',
    choferNombre: 'Luis Pérez',
    cliente: 'Supermercado Central',
    sucursal: 'Sucursal Este',
    numeroSucursal: 478,
    fecha: _hoy,
    horaProgramada: '10:30 AM',
    estado: SeguimientoEstado.pendiente,
    alerta: VisitaAlertaTipo.fueraDeHorario,
    posicion: const LatLng(-26.1920, -58.1665),
    ordenRuta: 1,
  ),
  VisitaSeguimientoMock(
    id: 'v5',
    choferId: 'c2',
    choferNombre: 'Luis Pérez',
    cliente: 'Panadería Ronozo',
    sucursal: 'Sucursal Este',
    numeroSucursal: 478,
    fecha: _hoy,
    horaProgramada: '11:15 AM',
    estado: SeguimientoEstado.pendiente,
    alerta: VisitaAlertaTipo.clienteSalteado,
    posicion: const LatLng(-26.1965, -58.1590),
    ordenRuta: 2,
  ),

  VisitaSeguimientoMock(
    id: 'v6',
    choferId: 'c3',
    choferNombre: 'Marta Ibáñez',
    cliente: 'Nombre y Do',
    sucursal: 'Sucursal Oeste',
    numeroSucursal: 478,
    fecha: _hoy,
    horaProgramada: '09:30 AM',
    horaCheckIn: '09:34 AM',
    estado: SeguimientoEstado.visitado,
    posicion: const LatLng(-26.1885, -58.1885),
    ordenRuta: 1,
  ),
  VisitaSeguimientoMock(
    id: 'v7',
    choferId: 'c3',
    choferNombre: 'Marta Ibáñez',
    cliente: 'Almacén 9 de Julio',
    sucursal: 'Sucursal Oeste',
    numeroSucursal: 479,
    fecha: _hoy,
    horaProgramada: '10:45 AM',
    estado: SeguimientoEstado.enCurso,
    posicion: const LatLng(-26.1945, -58.1955),
    ordenRuta: 2,
  ),

  VisitaSeguimientoMock(
    id: 'v8',
    choferId: 'c4',
    choferNombre: 'Jorge Ramírez',
    cliente: 'Distribuidora Ramonoz',
    sucursal: 'Sucursal Centro',
    numeroSucursal: 456,
    fecha: _hoy,
    horaProgramada: '09:30 AM',
    estado: SeguimientoEstado.asignado,
    posicion: const LatLng(-26.1760, -58.1610),
    ordenRuta: 1,
  ),
];

List<LatLng> recorridoDeChofer(String choferId) {
  final visitas = mockVisitasSeguimiento
      .where((v) => v.choferId == choferId)
      .toList()
    ..sort((a, b) => a.ordenRuta.compareTo(b.ordenRuta));
  return visitas.map((v) => v.posicion).toList();
}
