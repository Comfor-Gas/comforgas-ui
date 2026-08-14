import 'dart:typed_data';
import 'package:hive/hive.dart';

class OfflineEventoTipo {
  OfflineEventoTipo._();

  static const String checkIn = 'CHECK_IN';
  static const String checkOut = 'CHECK_OUT';
  static const String evidencia = 'EVIDENCIA';
}

class OfflineEvento {
  final String uuidOffline;
  final String tipoEvento;
  final int idAgendaItem;
  final int? idVisita;
  final DateTime timestampOrigen;

  // CHECK_IN
  final double? latitud;
  final double? longitud;

  // CHECK_OUT
  final String? observaciones;
  final DateTime? timestampFin;
  final double? latitudFin;
  final double? longitudFin;

  // EVIDENCIA
  final Uint8List? archivoBytes;
  final String? tipoEvidencia;
  final String? mimeType;

  // Metadata 
  final DateTime creadoEn;
  final int intentos;
  final String? ultimoError;

  const OfflineEvento({
    required this.uuidOffline,
    required this.tipoEvento,
    required this.idAgendaItem,
    this.idVisita,
    required this.timestampOrigen,
    required this.creadoEn,
    this.latitud,
    this.longitud,
    this.observaciones,
    this.timestampFin,
    this.latitudFin,
    this.longitudFin,
    this.archivoBytes,
    this.tipoEvidencia,
    this.mimeType,
    this.intentos = 0,
    this.ultimoError,
  });

  OfflineEvento copyWith({int? intentos, String? ultimoError}) {
    return OfflineEvento(
      uuidOffline: uuidOffline,
      tipoEvento: tipoEvento,
      idAgendaItem: idAgendaItem,
      idVisita: idVisita,
      timestampOrigen: timestampOrigen,
      creadoEn: creadoEn,
      latitud: latitud,
      longitud: longitud,
      observaciones: observaciones,
      timestampFin: timestampFin,
      latitudFin: latitudFin,
      longitudFin: longitudFin,
      archivoBytes: archivoBytes,
      tipoEvidencia: tipoEvidencia,
      mimeType: mimeType,
      intentos: intentos ?? this.intentos,
      ultimoError: ultimoError ?? this.ultimoError,
    );
  }
}

class OfflineEventoAdapter extends TypeAdapter<OfflineEvento> {
  @override
  final int typeId = 27;

  @override
  OfflineEvento read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return OfflineEvento(
      uuidOffline: fields[0] as String,
      tipoEvento: fields[1] as String,
      idVisita: fields[2] as int?,
      timestampOrigen: fields[3] as DateTime,
      latitud: fields[4] as double?,
      longitud: fields[5] as double?,
      observaciones: fields[6] as String?,
      timestampFin: fields[7] as DateTime?,
      latitudFin: fields[8] as double?,
      longitudFin: fields[9] as double?,
      archivoBytes: fields[10] as Uint8List?,
      tipoEvidencia: fields[11] as String?,
      mimeType: fields[12] as String?,
      creadoEn: fields[13] as DateTime,
      intentos: fields[14] as int? ?? 0,
      ultimoError: fields[15] as String?,
      idAgendaItem: fields[16] as int? ?? -1,
    );
  }

  @override
  void write(BinaryWriter writer, OfflineEvento obj) {
    writer
      ..writeByte(17)
      ..writeByte(0)
      ..write(obj.uuidOffline)
      ..writeByte(1)
      ..write(obj.tipoEvento)
      ..writeByte(2)
      ..write(obj.idVisita)
      ..writeByte(3)
      ..write(obj.timestampOrigen)
      ..writeByte(4)
      ..write(obj.latitud)
      ..writeByte(5)
      ..write(obj.longitud)
      ..writeByte(6)
      ..write(obj.observaciones)
      ..writeByte(7)
      ..write(obj.timestampFin)
      ..writeByte(8)
      ..write(obj.latitudFin)
      ..writeByte(9)
      ..write(obj.longitudFin)
      ..writeByte(10)
      ..write(obj.archivoBytes)
      ..writeByte(11)
      ..write(obj.tipoEvidencia)
      ..writeByte(12)
      ..write(obj.mimeType)
      ..writeByte(13)
      ..write(obj.creadoEn)
      ..writeByte(14)
      ..write(obj.intentos)
      ..writeByte(15)
      ..write(obj.ultimoError)
      ..writeByte(16)
      ..write(obj.idAgendaItem);
  }
}
