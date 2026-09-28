import 'dart:js_interop';
import 'dart:typed_data';
import 'package:web/web.dart' as web;

bool get descargaDisponible => true;

Future<void> descargarArchivo(Uint8List bytes, String nombre, String mimeType) async {
  final blob = web.Blob(<JSAny>[bytes.toJS].toJS, web.BlobPropertyBag(type: mimeType));
  final url = web.URL.createObjectURL(blob);
  final enlace = web.HTMLAnchorElement()
    ..href = url
    ..download = nombre;
  enlace.style.display = 'none';
  web.document.body?.appendChild(enlace);
  enlace.click();
  enlace.remove();
  await Future<void>.delayed(const Duration(seconds: 2));
  web.URL.revokeObjectURL(url);
}
