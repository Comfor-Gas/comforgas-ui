import '../models/estado_garrafa.dart';

class EstadosGarrafaRef {
  final int? llenaId;
  final int? vaciaId;
  final int? averiadoId;

  const EstadosGarrafaRef({this.llenaId, this.vaciaId, this.averiadoId});

  bool get disponible => llenaId != null && vaciaId != null && averiadoId != null;

  factory EstadosGarrafaRef.desde(List<EstadoGarrafa> estados) {
    int? idDe(List<String> codigos) {
      for (final codigo in codigos) {
        for (final estado in estados) {
          if (estado.codigo.toUpperCase() == codigo) return estado.id;
        }
      }
      return null;
    }

    return EstadosGarrafaRef(
      llenaId: idDe(['LLENA']),
      vaciaId: idDe(['VACIA']),
      averiadoId: idDe(['FUERA_SERVICIO', 'REPARACION']),
    );
  }
}
