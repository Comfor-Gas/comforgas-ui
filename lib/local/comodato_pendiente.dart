import 'package:hive/hive.dart';

class ComodatoPendiente {
  final String uuidOffline;
  final int? idVisita;
  final int idAgendaItem;
  final String idUsuario;
  final DateTime? fecha;
  final int? idClienteExt;
  final DateTime timestampControl;
  final String? observaciones;
  final int cantidadContratada;
  final int cantidadFisicaActual;
  final DateTime creadoEn;
  final int intentos;
  final String? ultimoError;

  const ComodatoPendiente({
    required this.uuidOffline,
    this.idVisita,
    required this.idAgendaItem,
    required this.idUsuario,
    this.fecha,
    this.idClienteExt,
    required this.timestampControl,
    this.observaciones,
    required this.cantidadContratada,
    required this.cantidadFisicaActual,
    required this.creadoEn,
    this.intentos = 0,
    this.ultimoError,
  });

  ComodatoPendiente copyWith({int? intentos, String? ultimoError}) {
    return ComodatoPendiente(
      uuidOffline: uuidOffline,
      idVisita: idVisita,
      idAgendaItem: idAgendaItem,
      idUsuario: idUsuario,
      fecha: fecha,
      idClienteExt: idClienteExt,
      timestampControl: timestampControl,
      observaciones: observaciones,
      cantidadContratada: cantidadContratada,
      cantidadFisicaActual: cantidadFisicaActual,
      creadoEn: creadoEn,
      intentos: intentos ?? this.intentos,
      ultimoError: ultimoError ?? this.ultimoError,
    );
  }
}

class ComodatoPendienteAdapter extends TypeAdapter<ComodatoPendiente> {
  @override
  final int typeId = 29;

  static int _int(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  static DateTime _fecha(dynamic v) => v is DateTime ? v : DateTime.now();

  @override
  ComodatoPendiente read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ComodatoPendiente(
      uuidOffline: fields[0] is String ? fields[0] as String : '',
      idVisita: fields[1] is int ? fields[1] as int : null,
      idAgendaItem: fields[2] is int ? fields[2] as int : -1,
      idUsuario: fields[3] is String ? fields[3] as String : '',
      fecha: fields[4] is DateTime ? fields[4] as DateTime : null,
      idClienteExt: fields[5] is int ? fields[5] as int : null,
      timestampControl: _fecha(fields[6]),
      observaciones: fields[7] is String ? fields[7] as String : null,
      cantidadContratada: _int(fields[8]),
      cantidadFisicaActual: _int(fields[9]),
      creadoEn: _fecha(fields[10]),
      intentos: fields[11] is int ? fields[11] as int : 0,
      ultimoError: fields[12] is String ? fields[12] as String : null,
    );
  }

  @override
  void write(BinaryWriter writer, ComodatoPendiente obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.uuidOffline)
      ..writeByte(1)
      ..write(obj.idVisita)
      ..writeByte(2)
      ..write(obj.idAgendaItem)
      ..writeByte(3)
      ..write(obj.idUsuario)
      ..writeByte(4)
      ..write(obj.fecha)
      ..writeByte(5)
      ..write(obj.idClienteExt)
      ..writeByte(6)
      ..write(obj.timestampControl)
      ..writeByte(7)
      ..write(obj.observaciones)
      ..writeByte(8)
      ..write(obj.cantidadContratada)
      ..writeByte(9)
      ..write(obj.cantidadFisicaActual)
      ..writeByte(10)
      ..write(obj.creadoEn)
      ..writeByte(11)
      ..write(obj.intentos)
      ..writeByte(12)
      ..write(obj.ultimoError);
  }
}
