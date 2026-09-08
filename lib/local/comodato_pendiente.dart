import 'package:hive/hive.dart';

class ComodatoPendiente {
  final String uuidOffline;
  final int? idVisita;
  final int idAgendaItem;
  final String idUsuario;
  final DateTime? fecha;
  final int? idClienteExt;
  final DateTime timestampCaptura;
  final String? observaciones;
  final String detallesJson;
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
    required this.timestampCaptura,
    this.observaciones,
    required this.detallesJson,
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
      timestampCaptura: timestampCaptura,
      observaciones: observaciones,
      detallesJson: detallesJson,
      creadoEn: creadoEn,
      intentos: intentos ?? this.intentos,
      ultimoError: ultimoError ?? this.ultimoError,
    );
  }
}

class ComodatoPendienteAdapter extends TypeAdapter<ComodatoPendiente> {
  @override
  final int typeId = 29;

  @override
  ComodatoPendiente read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ComodatoPendiente(
      uuidOffline: fields[0] as String,
      idVisita: fields[1] as int?,
      idAgendaItem: fields[2] as int? ?? -1,
      idUsuario: fields[3] as String? ?? '',
      fecha: fields[4] as DateTime?,
      idClienteExt: fields[5] as int?,
      timestampCaptura: fields[6] as DateTime,
      observaciones: fields[7] as String?,
      detallesJson: fields[8] as String? ?? '[]',
      creadoEn: fields[9] as DateTime,
      intentos: fields[10] as int? ?? 0,
      ultimoError: fields[11] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ComodatoPendiente obj) {
    writer
      ..writeByte(12)
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
      ..write(obj.timestampCaptura)
      ..writeByte(7)
      ..write(obj.observaciones)
      ..writeByte(8)
      ..write(obj.detallesJson)
      ..writeByte(9)
      ..write(obj.creadoEn)
      ..writeByte(10)
      ..write(obj.intentos)
      ..writeByte(11)
      ..write(obj.ultimoError);
  }
}
