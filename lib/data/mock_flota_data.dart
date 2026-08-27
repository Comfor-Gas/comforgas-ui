import '../models/deposito_camion.dart';
import '../models/movimiento_stock.dart';
import '../models/producto_catalogo.dart';

List<ProductoCatalogo> productosFlotaDeEjemplo() {
  return const [
    ProductoCatalogo(
      idProducto: 'GARRAFA-10',
      sku: '10kg GLP',
      descripcion: 'Garrafa 10 kg',
      pesoKg: 10,
      tipoProducto: 'GARRAFA',
    ),
    ProductoCatalogo(
      idProducto: 'GARRAFA-45',
      sku: '45kg GLP',
      descripcion: 'Garrafa 45 kg',
      pesoKg: 45,
      tipoProducto: 'GARRAFA',
    ),
  ];
}

List<DepositoCamion> camionesFlotaDeEjemplo() {
  return const [
    DepositoCamion(
      id: 1,
      nombre: 'Camión AF 123 CD',
      patente: 'AF 123 CD',
      numeroMovil: 1,
      activo: true,
      repartidor: RepartidorInfo(id: 'c1', nombre: 'Diego Gómez', email: 'diego@comforgas.com'),
      llenos: 150,
      vacios: 42,
      stockCargado: true,
    ),
    DepositoCamion(
      id: 2,
      nombre: 'Camión AG 552 ZK',
      patente: 'AG 552 ZK',
      numeroMovil: 2,
      activo: true,
      repartidor: RepartidorInfo(id: 'c2', nombre: 'Canota Gómez', email: 'canota@comforgas.com'),
      llenos: 150,
      vacios: 150,
      stockCargado: true,
    ),
    DepositoCamion(
      id: 3,
      nombre: 'Camión AC 789 EF',
      patente: 'AC 789 EF',
      numeroMovil: 3,
      activo: true,
      repartidor: RepartidorInfo(id: 'c1', nombre: 'Diego Gómez', email: 'diego@comforgas.com'),
      llenos: 140,
      vacios: 70,
      stockCargado: true,
    ),
    DepositoCamion(
      id: 4,
      nombre: 'Camión WIR 538',
      patente: 'WIR 538',
      numeroMovil: 4,
      activo: true,
      llenos: 0,
      vacios: 0,
      stockCargado: true,
    ),
  ];
}

List<MovimientoStock> historialRecargasDeEjemplo() {
  final ahora = DateTime.now();
  return [
    MovimientoStock(
      id: 1,
      tipoMovimiento: 'CARGA_CAMION',
      productoSku: '10kg GLP',
      productoDescripcion: 'Garrafa 10 kg',
      cantidad: 60,
      usuario: 'Carlos López',
      fecha: ahora.subtract(const Duration(hours: 2)),
      observaciones: 'Recarga Completa - Turno Mañana',
      origenNombre: 'Depósito Central',
      destinoNombre: 'Camión WIR 538',
    ),
    MovimientoStock(
      id: 2,
      tipoMovimiento: 'CARGA_CAMION',
      productoSku: '10kg GLP',
      productoDescripcion: 'Garrafa 10 kg',
      cantidad: 45,
      usuario: 'Carlos López',
      fecha: ahora.subtract(const Duration(days: 1, hours: 3)),
      observaciones: 'Recarga - Turno Tarde',
      origenNombre: 'Depósito Central',
      destinoNombre: 'Camión WIR 538',
    ),
    MovimientoStock(
      id: 3,
      tipoMovimiento: 'CARGA_CAMION',
      productoSku: '10kg GLP',
      productoDescripcion: 'Garrafa 10 kg',
      cantidad: 35,
      usuario: 'Carlos López',
      fecha: ahora.subtract(const Duration(days: 2, hours: 5)),
      observaciones: 'Recarga - Turno Tarde',
      origenNombre: 'Depósito Central',
      destinoNombre: 'Camión WIR 538',
    ),
  ];
}
