import '../models/visita_model.dart';

int _porOrden(VisitaModel a, VisitaModel b) {
  final porOrden = a.ordenVisita.compareTo(b.ordenVisita);
  if (porOrden != 0) return porOrden;
  return (a.idAgendaItem ?? 0).compareTo(b.idAgendaItem ?? 0);
}

int _porCarga(VisitaModel a, VisitaModel b) {
  final idA = a.idAgendaItem;
  final idB = b.idAgendaItem;
  if (idA != null && idB != null && idA != idB) return idA.compareTo(idB);
  return _porOrden(a, b);
}

void ordenarVisitas(List<VisitaModel> visitas) {
  final ordenes = <int>{};
  var repetidos = false;
  for (final v in visitas) {
    if (!ordenes.add(v.ordenVisita)) {
      repetidos = true;
      break;
    }
  }
  visitas.sort(repetidos ? _porCarga : _porOrden);
}
