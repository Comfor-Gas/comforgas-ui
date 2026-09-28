class MotivoSinOperar {
  final String codigo;
  final String etiqueta;
  final bool requiereDetalle;

  const MotivoSinOperar(this.codigo, this.etiqueta, {this.requiereDetalle = false});

  static const List<MotivoSinOperar> opciones = [
    MotivoSinOperar('CLIENTE_AUSENTE', 'No había nadie / no respondieron'),
    MotivoSinOperar('LOCAL_CERRADO', 'Local o domicilio cerrado'),
    MotivoSinOperar('NO_REQUIERE', 'El cliente no necesitaba garrafas'),
    MotivoSinOperar('DIRECCION_NO_ENCONTRADA', 'No se encontró la dirección'),
    MotivoSinOperar('OTRO', 'Otro motivo', requiereDetalle: true),
  ];
}

class ResultadoSinOperar {
  final MotivoSinOperar motivo;
  final String detalle;

  const ResultadoSinOperar({required this.motivo, required this.detalle});

  String get descripcion => detalle.isEmpty ? motivo.etiqueta : '${motivo.etiqueta}. $detalle';
}
