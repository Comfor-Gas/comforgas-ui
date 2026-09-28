import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import 'chip_filtro.dart';
import 'filtros_panel.dart';

DateTime _dia(DateTime d) => DateTime(d.year, d.month, d.day);

bool _mismoDia(DateTime? a, DateTime? b) =>
    a != null && b != null && a.year == b.year && a.month == b.month && a.day == b.day;

String formatFechaFiltro(DateTime f) {
  final d = f.day.toString().padLeft(2, '0');
  final m = f.month.toString().padLeft(2, '0');
  return '$d/$m/${f.year}';
}

Widget _temaCalendario(BuildContext context, Widget? child) {
  final base = Theme.of(context);
  return Theme(
    data: base.copyWith(
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.orange,
        onPrimary: AppColors.white,
        secondary: AppColors.orange,
        onSurface: AppColors.steelBlue,
        surface: AppColors.white,
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.orange),
      ),
    ),
    child: child!,
  );
}

Future<DateTime?> elegirFechaFiltro(
  BuildContext context, {
  required DateTime inicial,
  DateTime? primera,
  DateTime? ultima,
}) {
  final hoy = _dia(DateTime.now());
  final first = primera ?? DateTime(hoy.year - 2, 1, 1);
  final last = ultima ?? DateTime(hoy.year + 1, 12, 31);
  var init = _dia(inicial);
  if (init.isBefore(first)) init = first;
  if (init.isAfter(last)) init = last;
  return showDatePicker(
    context: context,
    initialDate: init,
    firstDate: first,
    lastDate: last,
    builder: _temaCalendario,
  );
}

Future<DateTimeRange?> elegirRangoFiltro(
  BuildContext context, {
  DateTime? desde,
  DateTime? hasta,
  DateTime? primera,
  DateTime? ultima,
}) {
  final hoy = _dia(DateTime.now());
  final first = primera ?? DateTime(hoy.year - 2, 1, 1);
  final last = ultima ?? hoy;
  DateTimeRange? inicial;
  if (desde != null && hasta != null && !desde.isBefore(first) && !hasta.isAfter(last)) {
    inicial = DateTimeRange(start: _dia(desde), end: _dia(hasta));
  }
  return showDateRangePicker(
    context: context,
    firstDate: first,
    lastDate: last,
    initialDateRange: inicial,
    helpText: 'Elegí el rango de fechas',
    saveText: 'Aplicar',
    builder: (context, child) => _temaCalendario(
      context,
      Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420, maxHeight: 620),
          child: child,
        ),
      ),
    ),
  );
}

enum PresetRango { hoy, ultimos7, ultimos30, esteMes }

extension PresetRangoInfo on PresetRango {
  String get etiqueta {
    switch (this) {
      case PresetRango.hoy:
        return 'Hoy';
      case PresetRango.ultimos7:
        return 'Últimos 7 días';
      case PresetRango.ultimos30:
        return 'Últimos 30 días';
      case PresetRango.esteMes:
        return 'Este mes';
    }
  }

  DateTimeRange get rango {
    final hoy = _dia(DateTime.now());
    switch (this) {
      case PresetRango.hoy:
        return DateTimeRange(start: hoy, end: hoy);
      case PresetRango.ultimos7:
        return DateTimeRange(start: hoy.subtract(const Duration(days: 6)), end: hoy);
      case PresetRango.ultimos30:
        return DateTimeRange(start: hoy.subtract(const Duration(days: 29)), end: hoy);
      case PresetRango.esteMes:
        return DateTimeRange(start: DateTime(hoy.year, hoy.month, 1), end: hoy);
    }
  }
}

class SelectorRangoFechas extends StatelessWidget {
  final DateTime? desde;
  final DateTime? hasta;
  final void Function(DateTime? desde, DateTime? hasta) onCambio;
  final bool permitirSinRango;
  final String etiqueta;
  final String etiquetaSinRango;
  final List<PresetRango> presets;

  const SelectorRangoFechas({
    super.key,
    required this.desde,
    required this.hasta,
    required this.onCambio,
    this.permitirSinRango = false,
    this.etiqueta = 'Período',
    this.etiquetaSinRango = 'Todas',
    this.presets = PresetRango.values,
  });

  PresetRango? get _presetActivo {
    if (desde == null || hasta == null) return null;
    for (final p in presets) {
      final r = p.rango;
      if (_mismoDia(r.start, desde) && _mismoDia(r.end, hasta)) return p;
    }
    return null;
  }

  String? get _textoRango {
    final d = desde;
    final h = hasta;
    if (d == null && h == null) return null;
    if (d != null && h != null) {
      return _mismoDia(d, h) ? formatFechaFiltro(d) : '${formatFechaFiltro(d)} – ${formatFechaFiltro(h)}';
    }
    if (d != null) return 'Desde ${formatFechaFiltro(d)}';
    return 'Hasta ${formatFechaFiltro(h!)}';
  }

  Future<void> _personalizado(BuildContext context) async {
    final rango = await elegirRangoFiltro(context, desde: desde, hasta: hasta);
    if (rango == null) return;
    onCambio(_dia(rango.start), _dia(rango.end));
  }

  @override
  Widget build(BuildContext context) {
    final activo = _presetActivo;
    final sinRango = desde == null && hasta == null;
    final personalizado = activo == null && !sinRango;
    final texto = _textoRango;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        EtiquetaFiltro(etiqueta),
        if (permitirSinRango)
          ChipFiltro(
            etiqueta: etiquetaSinRango,
            activo: sinRango,
            onTap: () => onCambio(null, null),
          ),
        for (final p in presets)
          ChipFiltro(
            etiqueta: p.etiqueta,
            activo: activo == p,
            onTap: () {
              final r = p.rango;
              onCambio(r.start, r.end);
            },
          ),
        ChipFiltro(
          etiqueta: personalizado && texto != null ? texto : 'Personalizado',
          icono: Icons.date_range_outlined,
          activo: personalizado,
          onTap: () => _personalizado(context),
        ),
        if (!personalizado && texto != null)
          Text(texto, style: AppTextStyles.footer.copyWith(color: AppColors.graphiteGray)),
      ],
    );
  }
}

class SelectorFechaUnica extends StatelessWidget {
  final DateTime? fecha;
  final ValueChanged<DateTime> onCambio;
  final String etiqueta;
  final bool incluirManiana;
  final DateTime? primera;
  final DateTime? ultima;
  final VoidCallback? onSinFecha;
  final String etiquetaSinFecha;

  const SelectorFechaUnica({
    super.key,
    required this.fecha,
    required this.onCambio,
    this.etiqueta = 'Fecha',
    this.incluirManiana = false,
    this.primera,
    this.ultima,
    this.onSinFecha,
    this.etiquetaSinFecha = 'Todas',
  });

  @override
  Widget build(BuildContext context) {
    final hoy = _dia(DateTime.now());
    final ayer = hoy.subtract(const Duration(days: 1));
    final maniana = hoy.add(const Duration(days: 1));
    final opciones = <(String, DateTime)>[
      ('Ayer', ayer),
      ('Hoy', hoy),
      if (incluirManiana) ('Mañana', maniana),
    ];
    final actual = fecha;
    final coincide = actual == null || opciones.any((o) => _mismoDia(o.$2, actual));
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        EtiquetaFiltro(etiqueta),
        if (onSinFecha != null)
          ChipFiltro(
            etiqueta: etiquetaSinFecha,
            activo: actual == null,
            onTap: onSinFecha,
          ),
        for (final o in opciones)
          ChipFiltro(
            etiqueta: o.$1,
            activo: _mismoDia(o.$2, fecha),
            onTap: () => onCambio(o.$2),
          ),
        ChipFiltro(
          etiqueta: coincide || actual == null ? 'Otra fecha' : formatFechaFiltro(actual),
          icono: Icons.calendar_today_outlined,
          activo: !coincide,
          onTap: () async {
            final elegida = await elegirFechaFiltro(
              context,
              inicial: actual ?? hoy,
              primera: primera,
              ultima: ultima,
            );
            if (elegida != null) onCambio(_dia(elegida));
          },
        ),
        if (coincide && actual != null)
          Text(formatFechaFiltro(actual), style: AppTextStyles.footer.copyWith(color: AppColors.graphiteGray)),
      ],
    );
  }
}
