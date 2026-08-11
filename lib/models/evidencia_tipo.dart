/// Valores posibles de `tipoEvidencia` para una [EvidenciaFotograficaModel],
/// según lo que el chofer está fotografiando durante el check-in/check-out
/// de una visita.
class EvidenciaTipo {
  EvidenciaTipo._();

  /// Foto de la fachada del comercio/domicilio visitado.
  static const String fachada = 'FACHADA';

  /// Foto de los envases/garrafas en comodato entregados o retirados.
  static const String comodato = 'COMODATO';
}
