import '../models/carga_chofer.dart';

const bool kStockChoferMovMock = true;

List<CargaChofer> mockCargasChofer() {
  final hoy = DateTime.now();
  return [
    CargaChofer(
      inicial: true,
      folio: 'CARGA-INICIAL-001',
      fecha: DateTime(hoy.year, hoy.month, hoy.day, 7, 30),
      lineas: const [
        CargaChoferLinea(etiqueta: '10 kg', cantidad: 120),
        CargaChoferLinea(etiqueta: '15 kg', cantidad: 40),
        CargaChoferLinea(etiqueta: '45 kg', cantidad: 16),
      ],
    ),
    CargaChofer(
      inicial: false,
      folio: 'RECARGA-002',
      fecha: DateTime(hoy.year, hoy.month, hoy.day, 12, 15),
      lineas: const [
        CargaChoferLinea(etiqueta: '10 kg', cantidad: 20),
      ],
    ),
  ];
}
