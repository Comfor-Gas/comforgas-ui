import '../data/mock_chofer_data.dart';
import '../utils/json_parsing.dart';
import 'visita_model.dart';

class ClienteFicha {
  final int orden;
  final String clienteId;
  final String nombre;
  final String domicilio;
  final String barrio;
  final String telefono;
  final bool comodato10;
  final bool comodato11;
  final bool comodato12;
  final DateTime? ultimaBajada;

  const ClienteFicha({
    required this.orden,
    required this.clienteId,
    required this.nombre,
    required this.domicilio,
    required this.barrio,
    required this.telefono,
    required this.comodato10,
    required this.comodato11,
    required this.comodato12,
    required this.ultimaBajada,
  });

  bool get tieneComodatoActivo => comodato10 || comodato11 || comodato12;

  List<int> get comodatosActivos => [
        if (comodato10) 10,
        if (comodato11) 11,
        if (comodato12) 12,
      ];

  bool get tieneBarrio => barrio.trim().isNotEmpty;

  bool get tieneTelefono => telefono.trim().isNotEmpty;

  factory ClienteFicha.fromVisita(
    VisitaModel visita, {
    String? nombreResuelto,
    String? domicilioResuelto,
  }) {
    final snapshot = visita.sucursalSnapshot;

    String texto(List<String> claves) {
      for (final clave in claves) {
        final valor = snapshot[clave];
        if (valor is String && valor.trim().isNotEmpty) return valor.trim();
        if (valor is num) return valor.toString();
      }
      return '';
    }

    final idClienteNum = parseInt(snapshot['clienteId']) ??
        parseInt(snapshot['idClienteExt']) ??
        parseInt(snapshot['idCliente']) ??
        visita.idSucursal;

    final nombre = nombreResuelto?.trim().isNotEmpty == true
        ? nombreResuelto!.trim()
        : (texto(['nombre', 'nombreSucursal', 'razonSocial', 'cliente']).isNotEmpty
            ? texto(['nombre', 'nombreSucursal', 'razonSocial', 'cliente'])
            : 'Sucursal #${visita.idSucursal}');

    final domicilio = domicilioResuelto?.trim().isNotEmpty == true
        ? domicilioResuelto!.trim()
        : (texto(['direccion', 'domicilio', 'address']).isNotEmpty
            ? texto(['direccion', 'domicilio', 'address'])
            : 'Sin dirección registrada');

    bool? boolDe(String clave) {
      final valor = snapshot[clave];
      if (valor is bool) return valor;
      if (valor is num) return valor != 0;
      if (valor is String) {
        final normal = valor.trim().toLowerCase();
        if (normal == 'true' || normal == '1' || normal == 'si' || normal == 'sí') {
          return true;
        }
        if (normal == 'false' || normal == '0' || normal == 'no') return false;
      }
      return null;
    }

    final c10 = boolDe('comodato10');
    final c11 = boolDe('comodato11');
    final c12 = boolDe('comodato12');

    final bool comodato10;
    final bool comodato11;
    final bool comodato12;
    if (c10 == null && c11 == null && c12 == null) {
      final mock = mockComodatoFor(idClienteNum);
      comodato10 = mock.comodato10;
      comodato11 = mock.comodato11;
      comodato12 = mock.comodato12;
    } else {
      comodato10 = c10 ?? false;
      comodato11 = c11 ?? false;
      comodato12 = c12 ?? false;
    }

    final ultimaBajada = parseDate(snapshot['ultimaBajada']) ??
        parseDate(snapshot['ultimaCompra']);

    return ClienteFicha(
      orden: visita.ordenVisita,
      clienteId: idClienteNum.toString(),
      nombre: nombre,
      domicilio: domicilio,
      barrio: texto(['barrio', 'zona']),
      telefono: texto(['telefono', 'phone', 'celular']),
      comodato10: comodato10,
      comodato11: comodato11,
      comodato12: comodato12,
      ultimaBajada: ultimaBajada,
    );
  }
}
