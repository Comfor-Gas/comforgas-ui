import 'dart:convert';

import 'package:hive/hive.dart';

class RecaudacionDiaria {
  final int efectivo;
  final int cheque;
  final int transferencia;
  final int cuentaCorriente;

  const RecaudacionDiaria({
    this.efectivo = 0,
    this.cheque = 0,
    this.transferencia = 0,
    this.cuentaCorriente = 0,
  });

  int get total => efectivo + cheque + transferencia + cuentaCorriente;

  bool get vacia => total == 0;

  Map<String, dynamic> toJson() => {
        'efectivo': efectivo,
        'cheque': cheque,
        'transferencia': transferencia,
        'cuentaCorriente': cuentaCorriente,
      };

  factory RecaudacionDiaria.fromJson(Map<String, dynamic> json) {
    return RecaudacionDiaria(
      efectivo: int.tryParse('${json['efectivo'] ?? 0}') ?? 0,
      cheque: int.tryParse('${json['cheque'] ?? 0}') ?? 0,
      transferencia: int.tryParse('${json['transferencia'] ?? 0}') ?? 0,
      cuentaCorriente: int.tryParse('${json['cuentaCorriente'] ?? 0}') ?? 0,
    );
  }
}

class RecaudacionDiariaService {
  RecaudacionDiariaService._();
  static final RecaudacionDiariaService instance = RecaudacionDiariaService._();

  static const String boxName = 'recaudacion_diaria_v2';
  Box<String>? _box;

  Future<void> init() async {
    _box = await Hive.openBox<String>(boxName);
  }

  String _clave(String idUsuario, DateTime fecha) {
    final f = '${fecha.year.toString().padLeft(4, '0')}-'
        '${fecha.month.toString().padLeft(2, '0')}-'
        '${fecha.day.toString().padLeft(2, '0')}';
    return '$idUsuario#$f';
  }

  RecaudacionDiaria obtener(String idUsuario, DateTime fecha) {
    final box = _box;
    if (box == null || idUsuario.isEmpty) return const RecaudacionDiaria();
    final raw = box.get(_clave(idUsuario, fecha));
    if (raw == null) return const RecaudacionDiaria();
    try {
      final d = jsonDecode(raw);
      if (d is! Map<String, dynamic>) return const RecaudacionDiaria();
      return RecaudacionDiaria.fromJson(d);
    } catch (_) {
      return const RecaudacionDiaria();
    }
  }

  int obtenerTotal(String idUsuario, DateTime fecha) =>
      obtener(idUsuario, fecha).total;

  Future<void> sumar(
    String idUsuario,
    DateTime fecha, {
    int efectivo = 0,
    int cheque = 0,
    int transferencia = 0,
    int cuentaCorriente = 0,
  }) async {
    final box = _box;
    if (box == null || idUsuario.isEmpty) return;
    if (efectivo <= 0 && cheque <= 0 && transferencia <= 0 && cuentaCorriente <= 0) {
      return;
    }
    final actual = obtener(idUsuario, fecha);
    final nueva = RecaudacionDiaria(
      efectivo: actual.efectivo + (efectivo > 0 ? efectivo : 0),
      cheque: actual.cheque + (cheque > 0 ? cheque : 0),
      transferencia: actual.transferencia + (transferencia > 0 ? transferencia : 0),
      cuentaCorriente:
          actual.cuentaCorriente + (cuentaCorriente > 0 ? cuentaCorriente : 0),
    );
    await box.put(_clave(idUsuario, fecha), jsonEncode(nueva.toJson()));
  }
}
