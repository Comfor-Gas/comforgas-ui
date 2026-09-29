import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import 'decoracion_filtro.dart';

class OpcionFiltro {
  final String id;
  final String etiqueta;
  final bool completado;
  final String? tooltipCompletado;

  const OpcionFiltro(this.id, this.etiqueta, {this.completado = false, this.tooltipCompletado});
}

class FiltroBuscable extends StatefulWidget {
  final String etiqueta;
  final IconData icono;
  final List<OpcionFiltro> opciones;
  final String? seleccion;
  final ValueChanged<String?> onCambio;
  final bool habilitado;
  final bool obligatorio;
  final String hint;
  final double ancho;

  const FiltroBuscable({
    super.key,
    required this.etiqueta,
    required this.icono,
    required this.opciones,
    required this.seleccion,
    required this.onCambio,
    this.habilitado = true,
    this.obligatorio = false,
    this.hint = 'Todos',
    this.ancho = 220,
  });

  @override
  State<FiltroBuscable> createState() => _FiltroBuscableState();
}

class _FiltroBuscableState extends State<FiltroBuscable> {
  static const int _maxResultados = 60;

  final _ctrl = TextEditingController();
  final _foco = FocusNode();

  @override
  void initState() {
    super.initState();
    _ctrl.text = _etiquetaSeleccion;
    _foco.addListener(_alCambiarFoco);
  }

  @override
  void didUpdateWidget(covariant FiltroBuscable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.seleccion != widget.seleccion || oldWidget.opciones != widget.opciones) {
      if (!_foco.hasFocus) _ctrl.text = _etiquetaSeleccion;
    }
  }

  @override
  void dispose() {
    _foco.removeListener(_alCambiarFoco);
    _foco.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  String get _etiquetaSeleccion {
    final id = widget.seleccion;
    if (id == null) return '';
    for (final o in widget.opciones) {
      if (o.id == id) return o.etiqueta;
    }
    return '';
  }

  void _alCambiarFoco() {
    if (_foco.hasFocus) {
      _ctrl.selection = TextSelection(baseOffset: 0, extentOffset: _ctrl.text.length);
    } else {
      _ctrl.text = _etiquetaSeleccion;
    }
    setState(() {});
  }

  Iterable<OpcionFiltro> _filtrar(TextEditingValue valor) {
    final q = valor.text.trim().toLowerCase();
    final base = q.isEmpty || q == _etiquetaSeleccion.toLowerCase()
        ? widget.opciones
        : widget.opciones.where((o) => o.etiqueta.toLowerCase().contains(q));
    return base.take(_maxResultados);
  }

  @override
  Widget build(BuildContext context) {
    final activo = widget.seleccion != null;
    return SizedBox(
      width: widget.ancho,
      child: RawAutocomplete<OpcionFiltro>(
        textEditingController: _ctrl,
        focusNode: _foco,
        displayStringForOption: (o) => o.etiqueta,
        optionsBuilder: _filtrar,
        onSelected: (o) {
          widget.onCambio(o.id);
          _foco.unfocus();
        },
        fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
          return TextField(
            controller: controller,
            focusNode: focusNode,
            enabled: widget.habilitado,
            style: estiloTextoFiltro,
            cursorColor: AppColors.steelBlue,
            decoration: decoracionFiltro(
              etiqueta: widget.etiqueta,
              icono: widget.icono,
              activo: activo,
              hint: widget.hint,
              sufijo: activo && !widget.obligatorio
                  ? IconButton(
                      tooltip: 'Quitar filtro',
                      icon: const Icon(Icons.close, size: 16, color: AppColors.graphiteGray),
                      onPressed: () {
                        widget.onCambio(null);
                        _ctrl.clear();
                        _foco.unfocus();
                      },
                    )
                  : const Icon(Icons.arrow_drop_down, color: AppColors.inputHint),
            ),
            onSubmitted: (_) => onSubmitted(),
          );
        },
        optionsViewBuilder: (context, onSelected, opciones) {
          final lista = opciones.toList();
          return Align(
            alignment: Alignment.topLeft,
            child: Material(
              elevation: 6,
              borderRadius: BorderRadius.circular(10),
              color: AppColors.white,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 280),
                child: lista.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(14),
                        child: Text('Sin resultados', style: AppTextStyles.link),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        shrinkWrap: true,
                        itemCount: lista.length,
                        itemBuilder: (context, i) {
                          final o = lista[i];
                          final elegido = o.id == widget.seleccion;
                          final resaltado = AutocompleteHighlightedOption.of(context) == i;
                          return InkWell(
                            onTap: () => onSelected(o),
                            child: Container(
                              color: elegido
                                  ? AppColors.orange.withOpacity(0.10)
                                  : (resaltado ? AppColors.background : null),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      o.etiqueta,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: elegido ? FontWeight.w800 : FontWeight.w500,
                                        color: elegido ? AppColors.orange : AppColors.steelBlue,
                                      ),
                                    ),
                                  ),
                                  if (o.completado)
                                    Tooltip(
                                      message: o.tooltipCompletado ?? 'Completado',
                                      child: const Icon(
                                        Icons.check_circle,
                                        size: 17,
                                        color: AppColors.badgeGreen,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
          );
        },
      ),
    );
  }
}
