import '../utils/json_parsing.dart';

class MetasDiaChofer {
  final DateTime? fecha;
  final int visitasProgramadas;
  final int visitasCerradas;
  final int visitasCompletadas;
  final int visitasNoAsistio;
  final int visitasPendientes;
  final double efectividadVenta;
  final double efectividadRecupero;
  final int envasesEntregados;
  final int envasesRecuperados;
  final int envasesPrestamo;
  final double montoTotalVentas;
  final double metaEfectividadVenta;
  final double metaEfectividadRecupero;

  const MetasDiaChofer({
    required this.fecha,
    required this.visitasProgramadas,
    required this.visitasCerradas,
    required this.visitasCompletadas,
    required this.visitasNoAsistio,
    required this.visitasPendientes,
    required this.efectividadVenta,
    required this.efectividadRecupero,
    required this.envasesEntregados,
    required this.envasesRecuperados,
    required this.envasesPrestamo,
    required this.montoTotalVentas,
    required this.metaEfectividadVenta,
    required this.metaEfectividadRecupero,
  });

  factory MetasDiaChofer.fromJson(Map<String, dynamic> j) {
    final metas = j['metas'] is Map<String, dynamic> ? j['metas'] as Map<String, dynamic> : const {};
    return MetasDiaChofer(
      fecha: parseDate(j['fecha']),
      visitasProgramadas: parseInt(j['visitasProgramadas']) ?? 0,
      visitasCerradas: parseInt(j['visitasCerradas']) ?? 0,
      visitasCompletadas: parseInt(j['visitasCompletadas']) ?? 0,
      visitasNoAsistio: parseInt(j['visitasNoAsistio']) ?? 0,
      visitasPendientes: parseInt(j['visitasPendientes']) ?? 0,
      efectividadVenta: parseDouble(j['efectividadVenta']) ?? 0,
      efectividadRecupero: parseDouble(j['efectividadRecuperoEnvases']) ?? 0,
      envasesEntregados: parseInt(j['envasesEntregados']) ?? 0,
      envasesRecuperados: parseInt(j['envasesRecuperados']) ?? 0,
      envasesPrestamo: parseInt(j['envasesPrestamo']) ?? 0,
      montoTotalVentas: parseDouble(j['montoTotalVentas']) ?? 0,
      metaEfectividadVenta: parseDouble(metas['metaEfectividadVenta']) ?? 85,
      metaEfectividadRecupero: parseDouble(metas['metaEfectividadRecupero']) ?? 95,
    );
  }

  double get progresoVisitas =>
      visitasProgramadas == 0 ? 0 : (visitasCerradas / visitasProgramadas).clamp(0.0, 1.0).toDouble();

  bool get sinAgenda => visitasProgramadas == 0;
}
