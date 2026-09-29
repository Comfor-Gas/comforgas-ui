import '../../../models/control_comodato.dart';

String fechaControlComodato(DateTime? f) {
  if (f == null) return '—';
  final l = f.toLocal();
  final dd = l.day.toString().padLeft(2, '0');
  final mm = l.month.toString().padLeft(2, '0');
  return '$dd/$mm/${l.year}';
}

String clienteControlComodato(ControlComodato control, String? nombreCliente) {
  final nombre = nombreCliente?.trim();
  if (nombre != null && nombre.isNotEmpty) return nombre;
  final nombreControl = control.nombreCliente?.trim();
  if (nombreControl != null && nombreControl.isNotEmpty) return nombreControl;
  final id = control.idClienteExt;
  return id == null ? 'Cliente s/d' : 'Cliente #$id';
}
