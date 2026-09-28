import '../../utils/json_parsing.dart';

enum MetricaTendencia { ventas, garrafas, cumplimiento }

extension MetricaTendenciaInfo on MetricaTendencia {
  String get etiqueta {
    switch (this) {
      case MetricaTendencia.ventas:
        return 'Ventas \$';
      case MetricaTendencia.garrafas:
        return 'Garrafas entregadas';
      case MetricaTendencia.cumplimiento:
        return 'Cumplimiento %';
    }
  }
}

class TendenciaPunto {
  final DateTime desde;
  final DateTime hasta;
  final double montoTotal;
  final int volumenEntregado;
  final int programadas;
  final int realizadas;
  final double porcentajeCumplimiento;

  const TendenciaPunto({
    required this.desde,
    required this.hasta,
    required this.montoTotal,
    required this.volumenEntregado,
    required this.programadas,
    required this.realizadas,
    required this.porcentajeCumplimiento,
  });

  factory TendenciaPunto.fromSerieJson(Map<String, dynamic> j) {
    final fecha = parseDate(j['fecha']) ?? parseDate(j['fechaDesde']) ?? DateTime.now();
    final hasta = parseDate(j['fechaHasta']) ?? fecha;
    return TendenciaPunto(
      desde: fecha,
      hasta: hasta,
      montoTotal: parseDouble(j['montoTotal']) ?? 0,
      volumenEntregado: parseInt(j['volumenEntregado']) ?? 0,
      programadas: parseInt(j['visitasProgramadas']) ?? 0,
      realizadas: parseInt(j['visitasRealizadas']) ?? 0,
      porcentajeCumplimiento: parseDouble(j['porcentajeCumplimiento']) ?? 0,
    );
  }

  bool get esDiaUnico =>
      desde.year == hasta.year && desde.month == hasta.month && desde.day == hasta.day;

  double valor(MetricaTendencia m) {
    switch (m) {
      case MetricaTendencia.ventas:
        return montoTotal;
      case MetricaTendencia.garrafas:
        return volumenEntregado.toDouble();
      case MetricaTendencia.cumplimiento:
        return porcentajeCumplimiento;
    }
  }
}
