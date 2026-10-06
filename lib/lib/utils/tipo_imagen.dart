import 'dart:io';

import 'package:http_parser/http_parser.dart';

MediaType tipoImagenDeArchivo(File archivo) {
  final porContenido = _tipoPorContenido(archivo);
  if (porContenido != null) return porContenido;
  final porExtension = _tipoPorExtension(archivo.path);
  if (porExtension != null) return porExtension;
  return MediaType('image', 'jpeg');
}

MediaType? _tipoPorContenido(File archivo) {
  List<int> b;
  try {
    final raf = archivo.openSync();
    try {
      b = raf.readSync(12);
    } finally {
      raf.closeSync();
    }
  } catch (_) {
    return null;
  }
  if (b.length >= 3 && b[0] == 0xFF && b[1] == 0xD8 && b[2] == 0xFF) {
    return MediaType('image', 'jpeg');
  }
  if (b.length >= 8 && b[0] == 0x89 && b[1] == 0x50 && b[2] == 0x4E && b[3] == 0x47) {
    return MediaType('image', 'png');
  }
  if (b.length >= 12 &&
      String.fromCharCodes(b.sublist(0, 4)) == 'RIFF' &&
      String.fromCharCodes(b.sublist(8, 12)) == 'WEBP') {
    return MediaType('image', 'webp');
  }
  if (b.length >= 12 && String.fromCharCodes(b.sublist(4, 8)) == 'ftyp') {
    final marca = String.fromCharCodes(b.sublist(8, 12)).toLowerCase();
    if (marca.startsWith('hei') || marca.startsWith('hev')) return MediaType('image', 'heic');
    if (marca == 'mif1' || marca == 'msf1') return MediaType('image', 'heif');
  }
  return null;
}

MediaType? _tipoPorExtension(String ruta) {
  final punto = ruta.lastIndexOf('.');
  if (punto < 0) return null;
  switch (ruta.substring(punto + 1).toLowerCase()) {
    case 'jpg':
    case 'jpeg':
      return MediaType('image', 'jpeg');
    case 'png':
      return MediaType('image', 'png');
    case 'webp':
      return MediaType('image', 'webp');
    case 'heic':
      return MediaType('image', 'heic');
    case 'heif':
      return MediaType('image', 'heif');
  }
  return null;
}
