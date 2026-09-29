String fechaHoraCanje(DateTime? f) {
  if (f == null) return '—';
  final l = f.toLocal();
  final dd = l.day.toString().padLeft(2, '0');
  final mm = l.month.toString().padLeft(2, '0');
  final hh = l.hour.toString().padLeft(2, '0');
  final min = l.minute.toString().padLeft(2, '0');
  return '$dd/$mm $hh:$min';
}
