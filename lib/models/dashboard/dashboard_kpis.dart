import '../../utils/json_parsing.dart';

Map<String, dynamic> _mapa(dynamic v) => v is Map<String, dynamic> ? v : const {};

List<Map<String, dynamic>> _lista(dynamic v) =>
    v is List ? v.whereType<Map<String, dynamic>>().toList() : const [];

double _dec(dynamic v) => parseDouble(v) ?? 0;

int _int(dynamic v) => parseInt(v) ?? 0;

class KpiAgenda {
  final int programadas;
  final int realizadas;
  final int noAsistio;
  final int canceladas;
  final int pendientes;
  final double porcentajeCumplimiento;

  const KpiAgenda({
    this.programadas = 0,
    this.realizadas = 0,
    this.noAsistio = 0,
    this.canceladas = 0,
    this.pendientes = 0,
    this.porcentajeCumplimiento = 0,
  });

  factory KpiAgenda.fromJson(Map<String, dynamic> j) => KpiAgenda(
        programadas: _int(j['visitasProgramadas']),
        realizadas: _int(j['visitasRealizadas']),
        noAsistio: _int(j['visitasNoAsistio']),
        canceladas: _int(j['visitasCanceladas']),
        pendientes: _int(j['visitasPendientes']),
        porcentajeCumplimiento: _dec(j['porcentajeCumplimiento']),
      );
}

class KpiVentaTipo {
  final String tipoVenta;
  final int transacciones;
  final int volumenEntregado;
  final double montoTotal;

  const KpiVentaTipo({
    required this.tipoVenta,
    required this.transacciones,
    required this.volumenEntregado,
    required this.montoTotal,
  });

  factory KpiVentaTipo.fromJson(Map<String, dynamic> j) => KpiVentaTipo(
        tipoVenta: (j['tipoVenta'] ?? '').toString(),
        transacciones: _int(j['cantidadTransacciones']),
        volumenEntregado: _int(j['volumenEntregado']),
        montoTotal: _dec(j['montoTotal']),
      );
}

class KpiVentas {
  final double montoTotal;
  final int volumenEntregado;
  final int volumenRecibido;
  final int transacciones;
  final double ticketPromedio;
  final List<KpiVentaTipo> porTipo;

  const KpiVentas({
    this.montoTotal = 0,
    this.volumenEntregado = 0,
    this.volumenRecibido = 0,
    this.transacciones = 0,
    this.ticketPromedio = 0,
    this.porTipo = const [],
  });

  factory KpiVentas.fromJson(Map<String, dynamic> j) => KpiVentas(
        montoTotal: _dec(j['montoTotal']),
        volumenEntregado: _int(j['volumenTotalEntregado']),
        volumenRecibido: _int(j['volumenTotalRecibido']),
        transacciones: _int(j['cantidadTransacciones']),
        ticketPromedio: _dec(j['ticketPromedio']),
        porTipo: _lista(j['desglosePorTipo']).map(KpiVentaTipo.fromJson).toList(),
      );
}

class KpiCanjes {
  final int totalCanjes;
  final int visitasConCanje;
  final double tasaDefectuososPorcentaje;

  const KpiCanjes({
    this.totalCanjes = 0,
    this.visitasConCanje = 0,
    this.tasaDefectuososPorcentaje = 0,
  });

  factory KpiCanjes.fromJson(Map<String, dynamic> j) => KpiCanjes(
        totalCanjes: _int(j['totalCanjes']),
        visitasConCanje: _int(j['visitasConCanje']),
        tasaDefectuososPorcentaje: _dec(j['indiceRotacionPorcentaje']),
      );
}

class KpiComodatos {
  final int totalContratado;
  final int totalAuditado;
  final int discrepancias;
  final int auditorias;
  final int auditoriasConFaltante;
  final int auditoriasConformes;
  final double tasaConformidad;

  const KpiComodatos({
    this.totalContratado = 0,
    this.totalAuditado = 0,
    this.discrepancias = 0,
    this.auditorias = 0,
    this.auditoriasConFaltante = 0,
    this.auditoriasConformes = 0,
    this.tasaConformidad = 0,
  });

  factory KpiComodatos.fromJson(Map<String, dynamic> j) => KpiComodatos(
        totalContratado: _int(j['totalContratado']),
        totalAuditado: _int(j['totalAuditadoFisico']),
        discrepancias: _int(j['totalDiscrepancias']),
        auditorias: _int(j['auditoriasTotales']),
        auditoriasConFaltante: _int(j['auditoriasConFaltante']),
        auditoriasConformes: _int(j['auditoriasConformes']),
        tasaConformidad: _dec(j['tasaConformidadPorcentaje']),
      );
}

class KpiRuta {
  final int? idRuta;
  final String nombre;
  final int programadas;
  final int realizadas;
  final double porcentajeCumplimiento;
  final int volumenEntregado;
  final double montoTotal;

  const KpiRuta({
    required this.idRuta,
    required this.nombre,
    required this.programadas,
    required this.realizadas,
    required this.porcentajeCumplimiento,
    required this.volumenEntregado,
    required this.montoTotal,
  });

  factory KpiRuta.fromJson(Map<String, dynamic> j) {
    final id = parseInt(j['idRuta']);
    final nombre = (j['nombreRuta'] ?? '').toString().trim();
    return KpiRuta(
      idRuta: id,
      nombre: nombre.isNotEmpty ? nombre : (id != null ? 'Ruta $id' : 'Sin ruta'),
      programadas: _int(j['visitasProgramadas']),
      realizadas: _int(j['visitasRealizadas']),
      porcentajeCumplimiento: _dec(j['porcentajeCumplimiento']),
      volumenEntregado: _int(j['volumenEntregado']),
      montoTotal: _dec(j['montoTotal']),
    );
  }
}

class KpiChofer {
  final String? idChofer;
  final String nombre;
  final int programadas;
  final int realizadas;
  final double porcentajeCumplimiento;
  final double efectividadVenta;
  final double tasaRecupero;
  final double montoTotal;

  const KpiChofer({
    required this.idChofer,
    required this.nombre,
    required this.programadas,
    required this.realizadas,
    required this.porcentajeCumplimiento,
    required this.efectividadVenta,
    required this.tasaRecupero,
    required this.montoTotal,
  });

  factory KpiChofer.fromJson(Map<String, dynamic> j) {
    final nombre = (j['nombreChofer'] ?? '').toString().trim();
    return KpiChofer(
      idChofer: j['idChofer']?.toString(),
      nombre: nombre.isNotEmpty ? nombre : 'Sin chofer',
      programadas: _int(j['visitasProgramadas']),
      realizadas: _int(j['visitasRealizadas']),
      porcentajeCumplimiento: _dec(j['porcentajeCumplimiento']),
      efectividadVenta: _dec(j['efectividadVenta']),
      tasaRecupero: _dec(j['tasaRecuperoPorcentaje']),
      montoTotal: _dec(j['montoTotal']),
    );
  }
}

class VentaSucursal {
  final int? idSucursal;
  final String nombre;
  final double montoTotal;
  final int volumenEntregado;
  final int cantidadVentas;

  const VentaSucursal({
    required this.idSucursal,
    required this.nombre,
    required this.montoTotal,
    required this.volumenEntregado,
    required this.cantidadVentas,
  });
}

class DashboardKpis {
  final KpiAgenda agenda;
  final KpiVentas ventas;
  final KpiCanjes canjes;
  final KpiComodatos comodatos;
  final List<KpiRuta> rutas;
  final List<KpiChofer> choferes;
  final List<VentaSucursal> ventasPorSucursal;

  const DashboardKpis({
    required this.agenda,
    required this.ventas,
    required this.canjes,
    required this.comodatos,
    required this.rutas,
    required this.choferes,
    required this.ventasPorSucursal,
  });

  factory DashboardKpis.fromJson(Map<String, dynamic> j) {
    final resumen = _mapa(j['resumenGlobal']);
    return DashboardKpis(
      agenda: KpiAgenda.fromJson(_mapa(resumen['agenda'])),
      ventas: KpiVentas.fromJson(_mapa(resumen['ventas'])),
      canjes: KpiCanjes.fromJson(_mapa(resumen['canjes'])),
      comodatos: KpiComodatos.fromJson(_mapa(resumen['comodatos'])),
      rutas: _lista(j['desglosePorRuta']).map(KpiRuta.fromJson).toList(),
      choferes: _lista(j['desglosePorChofer']).map(KpiChofer.fromJson).toList(),
      ventasPorSucursal: _agruparSucursales(_lista(j['desglosePorCliente'])),
    );
  }

  static List<VentaSucursal> _agruparSucursales(List<Map<String, dynamic>> filas) {
    final acumulado = <String, VentaSucursal>{};
    for (final f in filas) {
      final id = parseInt(f['idCliente']);
      final nombreCrudo = (f['nombreCliente'] ?? '').toString().trim();
      final nombre = nombreCrudo.isNotEmpty ? nombreCrudo : 'Sucursal sin nombre';
      final clave = id != null && id != 0 ? 'id:$id' : 'n:$nombre';
      final previo = acumulado[clave];
      acumulado[clave] = VentaSucursal(
        idSucursal: id == 0 ? null : id,
        nombre: previo?.nombre ?? nombre,
        montoTotal: (previo?.montoTotal ?? 0) + _dec(f['montoTotal']),
        volumenEntregado: (previo?.volumenEntregado ?? 0) + _int(f['volumenEntregado']),
        cantidadVentas: (previo?.cantidadVentas ?? 0) + _int(f['cantidadVentas']),
      );
    }
    final lista = acumulado.values.where((s) => s.montoTotal > 0 || s.cantidadVentas > 0).toList()
      ..sort((a, b) => b.montoTotal.compareTo(a.montoTotal));
    return lista;
  }

  int get sucursalesConVenta => ventasPorSucursal.length;
}
