import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

class ControladorCarga extends ChangeNotifier {
  final Set<Object> _activos = <Object>{};

  bool get activo => _activos.isNotEmpty;

  void marcar(Object origen, bool cargando) {
    final antes = activo;
    if (cargando) {
      _activos.add(origen);
    } else {
      _activos.remove(origen);
    }
    if (antes != activo) notifyListeners();
  }
}

class _AlcanceCarga extends InheritedWidget {
  final ControladorCarga controlador;

  const _AlcanceCarga({required this.controlador, required super.child});

  @override
  bool updateShouldNotify(_AlcanceCarga oldWidget) => oldWidget.controlador != controlador;
}

class ZonaCarga extends StatefulWidget {
  final Widget child;

  const ZonaCarga({super.key, required this.child});

  static ControladorCarga? de(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_AlcanceCarga>()?.controlador;

  @override
  State<ZonaCarga> createState() => _ZonaCargaState();
}

class _ZonaCargaState extends State<ZonaCarga> {
  final _controlador = ControladorCarga();

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _AlcanceCarga(
      controlador: _controlador,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListenableBuilder(
            listenable: _controlador,
            builder: (context, _) => BarraCarga(visible: _controlador.activo),
          ),
          Expanded(child: widget.child),
        ],
      ),
    );
  }
}

class BarraCarga extends StatelessWidget {
  final bool visible;

  const BarraCarga({super.key, required this.visible});

  static const double alto = 3;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: alto,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: visible ? 1 : 0,
        child: visible
            ? const LinearProgressIndicator(
                minHeight: alto,
                color: AppColors.orange,
                backgroundColor: Color(0x33F27424),
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}

class ReportarCarga extends StatefulWidget {
  final bool cargando;
  final Widget child;

  const ReportarCarga({super.key, required this.cargando, this.child = const SizedBox.shrink()});

  @override
  State<ReportarCarga> createState() => _ReportarCargaState();
}

class _ReportarCargaState extends State<ReportarCarga> {
  ControladorCarga? _controlador;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final nuevo = ZonaCarga.de(context);
    if (nuevo != _controlador) {
      final anterior = _controlador;
      _controlador = nuevo;
      _publicar(anterior, false);
      _publicar(nuevo, widget.cargando);
    }
  }

  @override
  void didUpdateWidget(covariant ReportarCarga oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cargando != widget.cargando) _publicar(_controlador, widget.cargando);
  }

  @override
  void dispose() {
    _publicar(_controlador, false);
    super.dispose();
  }

  void _publicar(ControladorCarga? controlador, bool cargando) {
    if (controlador == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        controlador.marcar(this, cargando);
      } catch (_) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_controlador == null && widget.cargando) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const BarraCarga(visible: true),
          widget.child,
        ],
      );
    }
    return widget.child;
  }
}
