import 'package:hive/hive.dart';

class CanjePendiente {
  final String uuidOffline;
  final int? idVisita;
  final int idAgendaItem;
  final String idUsuario;
  final DateTime? fecha;
  final int? idClienteExt;
  final String productoId;
  final String sku;
  final String descripcion;
  final int kg;
  final String descripcionDanio;
  final DateTime timestamp;
  final DateTime creadoEn;
  final int intentos;
  final String? ultimoError;

  const CanjePendiente({
    required this.uuidOffline,
    this.idVisita,
    required this.idAgendaItem,
    required this.idUsuario,
    this.fecha,
    this.idClienteExt,
    required this.productoId,
    required this.sku,
    required this.descripcion,
    required this.kg,
    required this.descripcionDanio,
    required this.timestamp,
    required this.creadoEn,
    this.intentos = 0,
    this.ultimoError,
  });

  CanjePendiente copyWith({int? intentos, String? ultimoError}) {
    return CanjePendiente(
      uuidOffline: uuidOffline,
      idVisita: idVisita,
      idAgendaItem: idAgendaItem,
      idUsuario: idUsuario,
      fecha: fecha,
      idClienteExt: idClienteExt,
      productoId: productoId,
      sku: sku,
      descripcion: descripcion,
      kg: kg,
      descripcionDanio: descripcionDanio,
      timestamp: timestamp,
      creadoEn: creadoEn,
      intentos: intentos ?? this.intentos,
      ultimoError: ultimoError ?? this.ultimoError,
    );
  }
}

class CanjePendienteAdapter extends TypeAdapter<CanjePendiente> {
  @override
  final int typeId = 30;

  @override
  CanjePendiente read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CanjePendiente(
      uuidOffline: fields[0] as String,
      idVisita: fields[1] as int?,
      idAgendaItem: fields[2] as int? ?? -1,
      idUsuario: fields[3] as String? ?? '',
      fecha: fields[4] as DateTime?,
      idClienteExt: fields[5] as int?,
      productoId: fields[6] as String? ?? '',
      sku: fields[7] as String? ?? '',
      descripcion: fields[8] as String? ?? '',
      kg: fields[9] as int? ?? 0,
      descripcionDanio: fields[10] as String? ?? '',
      timestamp: fields[11] as DateTime,
      creadoEn: fields[12] as DateTime,
      intentos: fields[13] as int? ?? 0,
      ultimoError: fields[14] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, CanjePendiente obj) {
    writer
      ..writeByte(15)
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
      ..write(obj.productoId)
      ..writeByte(7)
      ..write(obj.sku)
      ..writeByte(8)
      ..write(obj.descripcion)
      ..writeByte(9)
      ..write(obj.kg)
      ..writeByte(10)
      ..write(obj.descripcionDanio)
      ..writeByte(11)
      ..write(obj.timestamp)
      ..writeByte(12)
      ..write(obj.creadoEn)
      ..writeByte(13)
      ..write(obj.intentos)
      ..writeByte(14)
      ..write(obj.ultimoError);
  }
}
