import '../utils/json_parsing.dart';

class CuentaCorrienteResumen {
  final int idCliente;
  final String nombreCliente;
  final bool moroso;
  final int limiteCredito;
  final int saldoUsado;
  final int montoVencido;

  const CuentaCorrienteResumen({
    required this.idCliente,
    required this.nombreCliente,
    required this.moroso,
    required this.limiteCredito,
    required this.saldoUsado,
    required this.montoVencido,
  });

  bool get tieneVencido => montoVencido > 0;

  String get nombreMostrado =>
      nombreCliente.trim().isNotEmpty ? nombreCliente : 'Cliente #$idCliente';

  factory CuentaCorrienteResumen.fromJson(Map<String, dynamic> json) {
    return CuentaCorrienteResumen(
      idCliente: parseInt(json['idClienteExterno']) ?? parseInt(json['idCliente']) ?? 0,
      nombreCliente: (json['nombreCliente'] ?? '').toString(),
      moroso: json['moroso'] == true,
      limiteCredito: parseInt(json['limiteCredito']) ?? 0,
      saldoUsado: parseInt(json['saldoUsado']) ?? 0,
      montoVencido: parseInt(json['montoVencido']) ?? 0,
    );
  }
}

class ReporteCuentasCorrientes {
  final int totalDeuda;
  final int clientesMorosos;
  final int? clientesConDeudaBackend;
  final int totalClientes;
  final List<CuentaCorrienteResumen> clientes;
  final int totalPaginas;

  const ReporteCuentasCorrientes({
    this.totalDeuda = 0,
    this.clientesMorosos = 0,
    this.clientesConDeudaBackend,
    this.totalClientes = 0,
    this.clientes = const [],
    this.totalPaginas = 1,
  });

  int get clientesConDeuda =>
      clientesConDeudaBackend ?? clientes.where((c) => c.saldoUsado > 0).length;

  ReporteCuentasCorrientes conClientes(List<CuentaCorrienteResumen> todos) {
    return ReporteCuentasCorrientes(
      totalDeuda: totalDeuda,
      clientesMorosos: clientesMorosos,
      clientesConDeudaBackend: clientesConDeudaBackend,
      totalClientes: totalClientes,
      clientes: todos,
      totalPaginas: totalPaginas,
    );
  }

  factory ReporteCuentasCorrientes.fromJson(Map<String, dynamic> json) {
    final clientes = (json['clientes'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(CuentaCorrienteResumen.fromJson)
        .toList();
    return ReporteCuentasCorrientes(
      totalDeuda: parseInt(json['totalDeuda']) ?? 0,
      clientesMorosos: parseInt(json['clientesMorosos']) ?? 0,
      clientesConDeudaBackend: parseInt(json['clientesConDeuda']),
      totalClientes: parseInt(json['totalClientes']) ?? clientes.length,
      clientes: clientes,
      totalPaginas: parseInt(json['totalPaginas']) ?? 1,
    );
  }
}
