import 'package:flutter/material.dart';

enum MetodoPago { efectivo, cheque, transferencia, cuentaCorriente }

extension MetodoPagoX on MetodoPago {
  String get codigoBackend {
    switch (this) {
      case MetodoPago.efectivo:
        return 'EFECTIVO';
      case MetodoPago.cheque:
        return 'CHEQUE';
      case MetodoPago.transferencia:
        return 'TRANSFERENCIA';
      case MetodoPago.cuentaCorriente:
        return 'CUENTA_CORRIENTE';
    }
  }

  String get etiqueta {
    switch (this) {
      case MetodoPago.efectivo:
        return 'Efectivo';
      case MetodoPago.cheque:
        return 'Cheque';
      case MetodoPago.transferencia:
        return 'Transferencia';
      case MetodoPago.cuentaCorriente:
        return 'Cta Cte';
    }
  }

  IconData get icono {
    switch (this) {
      case MetodoPago.efectivo:
        return Icons.payments_outlined;
      case MetodoPago.cheque:
        return Icons.receipt_long_outlined;
      case MetodoPago.transferencia:
        return Icons.swap_horiz;
      case MetodoPago.cuentaCorriente:
        return Icons.account_balance_outlined;
    }
  }
}
