class MockChofer {
  final String id;
  final String nombre;

  const MockChofer({required this.id, required this.nombre});
}

class MockCliente {
  final int idSucursal;
  final int idRuta;
  final String nombre;
  final String direccion;

  const MockCliente({
    required this.idSucursal,
    required this.idRuta,
    required this.nombre,
    required this.direccion,
  });
}

const List<MockChofer> mockChoferes = [
  MockChofer(id: '11111111-1111-4111-8111-111111111111', nombre: 'Carlos Gómez'),
  MockChofer(id: '22222222-2222-4222-8222-222222222222', nombre: 'Luis Pérez'),
  MockChofer(id: '33333333-3333-4333-8333-333333333333', nombre: 'Marta Ibáñez'),
  MockChofer(id: '44444444-4444-4444-8444-444444444444', nombre: 'Jorge Ramírez'),
];

const List<MockCliente> mockClientes = [
  MockCliente(
    idSucursal: 101,
    idRuta: 1,
    nombre: 'Almacén Don Julio',
    direccion: 'Av. 25 de Mayo 1450, Formosa',
  ),
  MockCliente(
    idSucursal: 102,
    idRuta: 2,
    nombre: 'Distribuidora San Marcos',
    direccion: 'Belgrano 780, Formosa',
  ),
  MockCliente(
    idSucursal: 103,
    idRuta: 1,
    nombre: 'Kiosco La Esquina',
    direccion: 'Mitre 220, Formosa',
  ),
  MockCliente(
    idSucursal: 104,
    idRuta: 3,
    nombre: 'Supermercado Central',
    direccion: 'España 990, Formosa',
  ),
];
