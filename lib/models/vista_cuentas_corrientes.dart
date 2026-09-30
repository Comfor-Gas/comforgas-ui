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


  bool get soloDeudores => this == VistaCuentasCorrientes.cobranzas;
  bool get soloMorosos => this == VistaCuentasCorrientes.morosos;
}
