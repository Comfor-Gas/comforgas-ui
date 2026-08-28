import 'package:hive/hive.dart';

class CobroPendiente {
  final String uuidOffline;
  final int idVenta;
  final String metodoPago;
  final int monto;
  final DateTime timestampCobro;
  final DateTime creadoEn;
  final int intentos;
  final String? ultimoError;

  const CobroPendiente({
    required this.uuidOffline,
    required this.idVenta,
    required this.metodoPago,
    required this.monto,
    required this.timestampCobro,
    required this.creadoEn,
    this.intentos = 0,
    this.ultimoError,
  });

  CobroPendiente copyWith({int? intentos, String? ultimoError}) {
    return CobroPendiente(
      uuidOffline: uuidOffline,
      idVenta: idVenta,
      metodoPago: metodoPago,
      monto: monto,
      timestampCobro: timestampCobro,
      creadoEn: creadoEn,
      intentos: intentos ?? this.intentos,
      ultimoError: ultimoError ?? this.ultimoError,
    );
  }
}

class CobroPendienteAdapter extends TypeAdapter<CobroPendiente> {
  @override
  final int typeId = 28;

  @override
  CobroPendiente read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CobroPendiente(
      uuidOffline: fields[0] as String,
      idVenta: fields[1] as int,
      metodoPago: fields[2] as String,
      monto: fields[3] as int,
      timestampCobro: fields[4] as DateTime,
      creadoEn: fields[5] as DateTime,
      intentos: fields[6] as int? ?? 0,
      ultimoError: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, CobroPendiente obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.uuidOffline)
      ..writeByte(1)
      ..write(obj.idVenta)
      ..writeByte(2)
      ..write(obj.metodoPago)
      ..writeByte(3)
      ..write(obj.monto)
      ..writeByte(4)
      ..write(obj.timestampCobro)
      ..writeByte(5)
      ..write(obj.creadoEn)
      ..writeByte(6)
      ..write(obj.intentos)
      ..writeByte(7)
      ..write(obj.ultimoError);
  }
}
