enum VistaCuentasCorrientes { cobranzas, morosos, todas }

extension VistaCuentasCorrientesInfo on VistaCuentasCorrientes {
  String get etiqueta {
    switch (this) {
      case VistaCuentasCorrientes.cobranzas:
        return 'Gestión de Cobranzas';
      case VistaCuentasCorrientes.morosos:
        return 'Morosos / Riesgo';
      case VistaCuentasCorrientes.todas:
        return 'Todas las cuentas';
    }
  }

  String get descripcion {
    switch (this) {
      case VistaCuentasCorrientes.cobranzas:
        return 'Clientes con saldo pendiente, incluidas las compras a crédito de hoy. Son los que se pueden cobrar.';
      case VistaCuentasCorrientes.morosos:
        return 'Clientes con deuda vencida: cargos de ayer o antes que todavía no se pagaron.';
      case VistaCuentasCorrientes.todas:
        return 'Todas las cuentas corrientes activas, también las que tienen saldo en \$0.';
    }
  }

  bool get soloDeudores => this == VistaCuentasCorrientes.cobranzas;
  bool get soloMorosos => this == VistaCuentasCorrientes.morosos;
}
