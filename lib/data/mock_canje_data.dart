import '../models/canje_garrafa.dart';

const bool kCanjeMock = true;

CanjeGarrafa mockCanjeDesdeDraft(CanjeGarrafaDraft draft) {
  return CanjeGarrafa(
    idCanje: DateTime.now().millisecondsSinceEpoch % 100000,
    idVisita: draft.idVisita,
    productoId: draft.productoId,
    sku: draft.sku,
    descripcion: draft.descripcion,
    kg: draft.kg,
    descripcionDanio: draft.descripcionDanio.trim(),
    timestamp: draft.timestamp,
    uuidOffline: draft.uuidOffline,
  );
}

List<CanjeGarrafa> mockCanjesDeVisita(int idVisita) {
  return const [];
}
