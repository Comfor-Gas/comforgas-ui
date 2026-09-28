import '../utils/garrafa_match.dart';
import '../utils/json_parsing.dart';
import 'tipo_operacion_venta.dart';

class ComprobanteLinea {
  final String descripcion;
  final String tipoLabel;
  final int cantidadEntregada;
  final int cantidadRecibida;
  final bool usaRecibidos;
  final int precioUnitario;
  final bool inconsistente;

  const ComprobanteLinea({
    required this.descripcion,
    required this.tipoLabel,
    required this.cantidadEntregada,
    required this.cantidadRecibida,
    required this.usaRecibidos,
    required this.precioUnitario,
    this.inconsistente = false,
  });

  int get subtotal => precioUnitario * cantidadEntregada;

  factory ComprobanteLinea.fromJson(Map<String, dynamic> json) {
    final snapshot = json['productoSnapshot'] is Map<String, dynamic>
        ? json['productoSnapshot'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final idProducto = (json['idProducto'] ?? '').toString();
    final sku = (snapshot['sku'] ?? idProducto).toString();
    final descripcionRaw = (snapshot['descripcion'] ?? '').toString().trim();
    final kg = kgDesdeTexto(descripcionRaw) ?? kgDesdeTexto(sku);
    final tipoBackend = (json['tipoVenta'] ?? '').toString();
    final tipo = tipoOperacionDesdeBackend(tipoBackend);
    return ComprobanteLinea(
      descripcion: descripcionRaw.isNotEmpty
          ? descripcionRaw
          : (kg != null ? 'Garrafa $kg kg' : sku),
      tipoLabel: tipo?.info.label ?? tipoBackend.toUpperCase().replaceAll('_', ' '),
      cantidadEntregada: parseInt(json['cantidadEntregada']) ?? 0,
      cantidadRecibida: parseInt(json['cantidadRecibida']) ?? 0,
      usaRecibidos: tipo?.usaRecibidos ?? true,
      precioUnitario: parseInt(json['precioUnitario']) ?? 0,
      inconsistente: json['inconsistente'] == true,
    );
  }
}

class ComprobanteVenta {
  final int? idVenta;
  final DateTime? fecha;
  final int montoTotal;
  final List<ComprobanteLinea> lineas;

  const ComprobanteVenta({
    this.idVenta,
    this.fecha,
    required this.montoTotal,
    this.lineas = const [],
  });

  factory ComprobanteVenta.fromJson(Map<String, dynamic> json) {
    final detalles = json['detalles'];
    return ComprobanteVenta(
      idVenta: parseInt(json['idVenta']),
      fecha: parseDate(json['timestampVenta']),
      montoTotal: parseInt(json['montoTotal']) ?? 0,
      lineas: detalles is List
          ? detalles.whereType<Map<String, dynamic>>().map(ComprobanteLinea.fromJson).toList()
          : const [],
    );
  }
}

class ComprobanteCanje {
  final String descripcion;
  final String? danio;

  const ComprobanteCanje({required this.descripcion, this.danio});

  factory ComprobanteCanje.fromJson(Map<String, dynamic> json) {
    final snapshot = json['productoSnapshot'] is Map<String, dynamic>
        ? json['productoSnapshot'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final idProducto = (json['idProducto'] ?? '').toString();
    final descripcion = (snapshot['descripcion'] ?? '').toString().trim();
    final kg = kgDesdeTexto(descripcion) ?? kgDesdeTexto((snapshot['sku'] ?? idProducto).toString());
    final danio = json['descripcionDanio']?.toString();
    return ComprobanteCanje(
      descripcion: descripcion.isNotEmpty ? descripcion : (kg != null ? 'Garrafa $kg kg' : idProducto),
      danio: danio == null || danio.trim().isEmpty ? null : danio.trim(),
    );
  }
}

class ComprobanteComodato {
  final int cantidadContratada;
  final int cantidadFisica;

  const ComprobanteComodato({required this.cantidadContratada, required this.cantidadFisica});

  int get faltante => cantidadContratada > cantidadFisica ? cantidadContratada - cantidadFisica : 0;

  factory ComprobanteComodato.fromJson(Map<String, dynamic> json) {
    return ComprobanteComodato(
      cantidadContratada:
          parseInt(json['cantidad_contratada']) ?? parseInt(json['cantidadContratada']) ?? 0,
      cantidadFisica:
          parseInt(json['cantidad_fisica_actual']) ?? parseInt(json['cantidadFisicaActual']) ?? 0,
    );
  }
}

class ComprobanteVisita {
  final int idVisita;
  final List<ComprobanteVenta> ventas;
  final int montoTotal;
  final int llenasEntregadas;
  final int vaciasRecibidas;
  final List<ComprobanteCanje> canjes;
  final ComprobanteComodato? comodato;
  final Map<String, int> cobrosPorMetodo;
  final int envasesEnPrestamo;
  final String? motivoNoAsistencia;

  const ComprobanteVisita({
    required this.idVisita,
    this.ventas = const [],
    this.montoTotal = 0,
    this.llenasEntregadas = 0,
    this.vaciasRecibidas = 0,
    this.canjes = const [],
    this.comodato,
    this.cobrosPorMetodo = const {},
    this.envasesEnPrestamo = 0,
    this.motivoNoAsistencia,
  });

  int get totalCobrado => cobrosPorMetodo.values.fold<int>(0, (a, v) => a + v);

  bool get sinMovimientos => ventas.isEmpty && canjes.isEmpty && comodato == null;

  factory ComprobanteVisita.fromResumenJson(Map<String, dynamic> json) {
    final bloque = json['ventas'] is Map<String, dynamic>
        ? json['ventas'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final ventasRaw = bloque['ventas'];
    final ventas = ventasRaw is List
        ? ventasRaw
            .whereType<Map<String, dynamic>>()
            .where((v) => (v['estadoVenta'] ?? '').toString().toUpperCase() != 'CANCELADO')
            .map(ComprobanteVenta.fromJson)
            .toList()
        : <ComprobanteVenta>[];
    final canjesRaw = json['canjes'];
    final comodato = json['comodato'];
    final cobrosPorMetodo = <String, int>{};
    final cobrosRaw = json['cobros'];
    if (cobrosRaw is List) {
      for (final c in cobrosRaw.whereType<Map<String, dynamic>>()) {
        final metodo = (c['metodoPago'] ?? 'OTRO').toString().toUpperCase();
        final monto = parseInt(c['monto']) ?? 0;
        if (monto > 0) cobrosPorMetodo[metodo] = (cobrosPorMetodo[metodo] ?? 0) + monto;
      }
    }
    var envasesEnPrestamo = 0;
    final notasRaw = json['notasDebito'];
    if (notasRaw is List) {
      for (final n in notasRaw.whereType<Map<String, dynamic>>()) {
        envasesEnPrestamo += parseInt(n['envases']) ?? 0;
      }
    }
    final motivo = json['motivoNoAsistencia']?.toString();
    return ComprobanteVisita(
      idVisita: parseInt(json['idVisita']) ?? 0,
      ventas: ventas,
      montoTotal: parseInt(bloque['montoTotal']) ?? ventas.fold<int>(0, (a, v) => a + v.montoTotal),
      llenasEntregadas: parseInt(bloque['unidadesLlenasEntregadas']) ?? 0,
      vaciasRecibidas: parseInt(bloque['unidadesVaciasRecibidas']) ?? 0,
      canjes: canjesRaw is List
          ? canjesRaw.whereType<Map<String, dynamic>>().map(ComprobanteCanje.fromJson).toList()
          : const [],
      comodato: comodato is Map<String, dynamic> ? ComprobanteComodato.fromJson(comodato) : null,
      cobrosPorMetodo: cobrosPorMetodo,
      envasesEnPrestamo: envasesEnPrestamo,
      motivoNoAsistencia: motivo == null || motivo.isEmpty ? null : motivo,
    );
  }
}
