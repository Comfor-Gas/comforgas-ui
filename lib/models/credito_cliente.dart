import '../utils/json_parsing.dart';

class CreditoCliente {
  final double? limiteCredito;
  final double? saldoUsado;
  final double? saldoDisponible;
  final bool moroso;

  const CreditoCliente({
    this.limiteCredito,
    this.saldoUsado,
    this.saldoDisponible,
    this.moroso = false,
  });

  bool get tieneDatos => limiteCredito != null || saldoUsado != null;

  double get disponible {
    if (saldoDisponible != null) return saldoDisponible!;
    if (limiteCredito != null && saldoUsado != null) {
      return limiteCredito! - saldoUsado!;
    }
    return 0;
  }

  bool get limiteExcedido =>
      limiteCredito != null && saldoUsado != null && saldoUsado! > limiteCredito!;

  bool get tieneAlerta => moroso || limiteExcedido;

  factory CreditoCliente.fromSnapshot(Map<String, dynamic> snapshot) {
    bool boolDe(String clave) {
      final valor = snapshot[clave];
      if (valor is bool) return valor;
      if (valor is num) return valor != 0;
      if (valor is String) {
        final n = valor.trim().toLowerCase();
        return n == 'true' || n == '1' || n == 'si' || n == 'sí';
      }
      return false;
    }

    return CreditoCliente(
      limiteCredito: parseDouble(snapshot['limiteCredito']),
      saldoUsado: parseDouble(snapshot['saldoUsado']),
      saldoDisponible: parseDouble(snapshot['saldoDisponible']),
      moroso: boolDe('moroso'),
    );
  }
}
