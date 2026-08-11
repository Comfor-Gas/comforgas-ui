import 'dart:io';
import 'package:image_picker/image_picker.dart';

class PhotoCaptureException implements Exception {
  final String message;
  PhotoCaptureException(this.message);

  @override
  String toString() => message;
}

class PhotoCaptureService {
  final ImagePicker _picker;

  PhotoCaptureService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  Future<File?> capturarFoto({
    CameraDevice camara = CameraDevice.rear,
    int calidad = 82,
  }) async {
    try {
      final XFile? archivo = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: camara,
        imageQuality: calidad,
        maxWidth: 1600,
      );
      if (archivo == null) return null;
      return File(archivo.path);
    } catch (_) {
      throw PhotoCaptureException(
        'No se pudo acceder a la camara. Revisa los permisos de la app en el sistema.',
      );
    }
  }
}
