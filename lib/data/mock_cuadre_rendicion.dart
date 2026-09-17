import '../models/cuadre_rendicion.dart';

CuadreRendicion cuadreRendicionDeEjemplo({
  required String idUsuario,
  required String nombre,
  required DateTime fecha,
}) {
  return CuadreRendicion(
    idUsuario: idUsuario,
    nombreChofer: nombre.isNotEmpty ? nombre : 'chofer0',
    fecha: fecha,
    estado: 'PENDIENTE_CONCILIACION',
    rutaBloqueada: false,
    efectivoDeclarado: 232000,
    chequesDeclarado: 96000,
    transferenciasDeclarado: 0,
    envases: const [
      CuadreEnvaseLinea(
        sku: 'GARRAFA-10',
        etiqueta: '10 kg',
        llenosSistema: 5,
        llenosDeclarado: 5,
        vaciosSistema: 32,
        vaciosDeclarado: 30,
      ),
      CuadreEnvaseLinea(
        sku: 'GARRAFA-15',
        etiqueta: '15 kg',
        llenosSistema: 3,
        llenosDeclarado: 3,
        vaciosSistema: 8,
        vaciosDeclarado: 8,
      ),
    ],
    observaciones: '',
  );
}
