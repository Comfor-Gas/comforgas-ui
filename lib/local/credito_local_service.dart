import '../models/credito_cliente.dart';

class _CargoLocal {
  final int monto;
  final DateTime registradoEn;

  const _CargoLocal(this.monto, this.registradoEn);
}

class CreditoLocalService {
  CreditoLocalService._();

  static final CreditoLocalService instance = CreditoLocalService._();

  static const String claveConsultadoEn = 'creditoConsultadoEn';

  final Map<int, List<_CargoLocal>> _cargos = {};

  void registrarCargo(int idClienteExt, int monto) {
    if (monto <= 0) return;
    _cargos.putIfAbsent(idClienteExt, () => []).add(_CargoLocal(monto, DateTime.now().toUtc()));
  }

  int cargadoDesde(int idClienteExt, DateTime? consultadoEn) {
    final lista = _cargos[idClienteExt];
    if (lista == null || lista.isEmpty) return 0;
    final hoy = DateTime.now();
    final desde = consultadoEn?.toUtc();
    var total = 0;
    for (final c in lista) {
      final local = c.registradoEn.toLocal();
      if (local.year != hoy.year || local.month != hoy.month || local.day != hoy.day) continue;
      if (desde != null && !c.registradoEn.isAfter(desde)) continue;
      total += c.monto;
    }
    return total;
  }

  CreditoCliente creditoActual(Map<String, dynamic> snapshot, int? idClienteExt) {
    final base = CreditoCliente.fromSnapshot(snapshot);
    if (idClienteExt == null) return base;
    final consultado = DateTime.tryParse('${snapshot[claveConsultadoEn] ?? ''}');
    return base.conCargoLocal(cargadoDesde(idClienteExt, consultado));
  }
}
