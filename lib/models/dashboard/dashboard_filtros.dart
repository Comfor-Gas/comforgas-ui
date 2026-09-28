import '../../utils/json_parsing.dart';

enum RangoPreset { hoy, ultimos7, ultimos30, esteMes, personalizado }

extension RangoPresetEtiqueta on RangoPreset {
  String get etiqueta {
    switch (this) {
      case RangoPreset.hoy:
        return 'Hoy';
      case RangoPreset.ultimos7:
        return 'Últimos 7 días';
      case RangoPreset.ultimos30:
        return 'Últimos 30 días';
      case RangoPreset.esteMes:
        return 'Este mes';
      case RangoPreset.personalizado:
        return 'Personalizado';
    }
  }
}

class DashboardFiltros {
  final DateTime desde;
  final DateTime hasta;
  final RangoPreset preset;
  final String? idChofer;
  final int? idRuta;
  final int? idSucursal;

  const DashboardFiltros({
    required this.desde,
    required this.hasta,
    this.preset = RangoPreset.personalizado,
    this.idChofer,
    this.idRuta,
    this.idSucursal,
  });

  static DateTime _dia(DateTime d) => DateTime(d.year, d.month, d.day);

  factory DashboardFiltros.inicial() => DashboardFiltros.desdePreset(RangoPreset.ultimos7);

  factory DashboardFiltros.desdePreset(
    RangoPreset preset, {
    String? idChofer,
    int? idRuta,
    int? idSucursal,
  }) {
    final hoy = _dia(DateTime.now());
    DateTime desde;
    switch (preset) {
      case RangoPreset.hoy:
      case RangoPreset.personalizado:
        desde = hoy;
        break;
      case RangoPreset.ultimos7:
        desde = hoy.subtract(const Duration(days: 6));
        break;
      case RangoPreset.ultimos30:
        desde = hoy.subtract(const Duration(days: 29));
        break;
      case RangoPreset.esteMes:
        desde = DateTime(hoy.year, hoy.month, 1);
        break;
    }
    return DashboardFiltros(
      desde: desde,
      hasta: hoy,
      preset: preset,
      idChofer: idChofer,
      idRuta: idRuta,
      idSucursal: idSucursal,
    );
  }

  int get cantidadDias => _dia(hasta).difference(_dia(desde)).inDays + 1;

  bool get tieneFiltrosDeEntidad => idChofer != null || idRuta != null || idSucursal != null;

  DashboardFiltros conRango(DateTime desde, DateTime hasta, RangoPreset preset) {
    return DashboardFiltros(
      desde: _dia(desde),
      hasta: _dia(hasta),
      preset: preset,
      idChofer: idChofer,
      idRuta: idRuta,
      idSucursal: idSucursal,
    );
  }

  DashboardFiltros conChofer(String? id) => DashboardFiltros(
        desde: desde,
        hasta: hasta,
        preset: preset,
        idChofer: id,
        idRuta: idRuta,
        idSucursal: idSucursal,
      );

  DashboardFiltros conRuta(int? id) => DashboardFiltros(
        desde: desde,
        hasta: hasta,
        preset: preset,
        idChofer: idChofer,
        idRuta: id,
        idSucursal: idSucursal,
      );

  DashboardFiltros conSucursal(int? id) => DashboardFiltros(
        desde: desde,
        hasta: hasta,
        preset: preset,
        idChofer: idChofer,
        idRuta: idRuta,
        idSucursal: id,
      );

  DashboardFiltros sinEntidades() => DashboardFiltros(
        desde: desde,
        hasta: hasta,
        preset: preset,
      );

  Map<String, String> queryParams({DateTime? desdeOverride, DateTime? hastaOverride}) {
    return {
      'fechaDesde': formatDateOnly(desdeOverride ?? desde),
      'fechaHasta': formatDateOnly(hastaOverride ?? hasta),
      if (idRuta != null) 'idRuta': '$idRuta',
      if (idChofer != null && idChofer!.isNotEmpty) 'idChofer': idChofer!,
      if (idSucursal != null) 'idCliente': '$idSucursal',
    };
  }
}
