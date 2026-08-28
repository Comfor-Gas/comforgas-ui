import 'package:hive/hive.dart';

class CobroPendiente {
  final String uuidOffline;

  /// PK de la venta cuando ya está confirmada por el servidor. Es `null`
  /// cuando la venta se registró offline y todavía no sincronizó; en ese caso
  /// la referencia viaja en [uuidVentaOffline].
  final int? idVenta;

  /// UUID offline de la venta aún no materializada. El backend liga el cobro a
  /// la venta por este UUID durante la sincronización por lote.
  final String? uuidVentaOffline;
  final String metodoPago;
  final int monto;
  final DateTime timestampCobro;
  final DateTime creadoEn;
  final int intentos;
  final String? ultimoError;

  const CobroPendiente({
    required this.uuidOffline,
    this.idVenta,
    this.uuidVentaOffline,
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
      uuidVentaOffline: uuidVentaOffline,
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
      // Retrocompatible: los registros viejos guardaban idVenta como int no
      // nulo y no tenían el campo 8 (uuidVentaOffline).
      idVenta: fields[1] as int?,
      uuidVentaOffline: fields[8] as String?,
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
      ..writeByte(9)
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
      ..write(obj.ultimoError)
      ..writeByte(8)
      ..write(obj.uuidVentaOffline);
  }
}
