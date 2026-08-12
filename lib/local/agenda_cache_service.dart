import 'dart:convert';
import 'package:hive/hive.dart';
import '../models/visita_estado.dart';
import '../models/visita_model.dart';

class AgendaCacheService {
  AgendaCacheService._();

  static final AgendaCacheService instance = AgendaCacheService._();

  static const String boxName = 'agenda_cache';

  Box<String>? _box;

  Future<void> init() async {
    _box = await Hive.openBox<String>(boxName);
  }

  Box<String> get _requireBox {
    final box = _box;
    if (box == null) {
      throw StateError('AgendaCacheService.init() no fue llamado antes de usarlo.');
    }
    return box;
  }

  String _key(String idUsuario, DateTime fecha) {
    final f = '${fecha.year.toString().padLeft(4, '0')}-'
        '${fecha.month.toString().padLeft(2, '0')}-'
        '${fecha.day.toString().padLeft(2, '0')}';
    return '$idUsuario|$f';
  }

  Future<void> guardar(String idUsuario, DateTime fecha, List<VisitaModel> visitas) async {
    final data = visitas.map(_toCacheJson).toList();
    await _requireBox.put(_key(idUsuario, fecha), jsonEncode(data));
  }

  List<VisitaModel>? obtener(String idUsuario, DateTime fecha) {
    final raw = _requireBox.get(_key(idUsuario, fecha));
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return null;
      return decoded.whereType<Map<String, dynamic>>().map(VisitaModel.fromJson).toList();
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> _toCacheJson(VisitaModel v) {
    return {
      'idVisita': v.idVisita,
      'idUsuario': v.idUsuario,
      'nombreUsuario': v.nombreUsuario,
      'idSucursal': v.idSucursal,
      'idRuta': v.idRuta,
      'sucursalSnapshot': v.sucursalSnapshot,
      'rutaSnapshot': v.rutaSnapshot,
      'ordenVisita': v.ordenVisita,
      'estadoVisita': VisitaEstadoMapper.toValue(v.estadoVisita),
      if (v.fecha != null) 'fecha': v.fecha!.toIso8601String(),
      'observaciones': v.observaciones,
      if (v.timestampInicio != null) 'timestampInicio': v.timestampInicio!.toIso8601String(),
      if (v.timestampFin != null) 'timestampFin': v.timestampFin!.toIso8601String(),
      'latitudInicio': v.latitudInicio,
      'longitudInicio': v.longitudInicio,
      'geolocalizacionValida': v.geolocalizacionValida,
      if (v.createdAt != null) 'createdAt': v.createdAt!.toIso8601String(),
      if (v.updatedAt != null) 'updatedAt': v.updatedAt!.toIso8601String(),
    };
  }
}
