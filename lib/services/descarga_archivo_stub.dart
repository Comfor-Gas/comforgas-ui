import 'dart:typed_data';

bool get descargaDisponible => false;

Future<void> descargarArchivo(Uint8List bytes, String nombre, String mimeType) async {
  throw UnsupportedError('La descarga de archivos solo está disponible en la versión web.');
}
