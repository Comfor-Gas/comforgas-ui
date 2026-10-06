import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/evidencia_fotografica_model.dart';
import '../../../models/visita_estado.dart';
import '../../../providers/auth_provider.dart';
import '../../../repositories/evidencia_repository.dart';
import '../../../repositories/network_exception.dart';
import '../../common/evidencias/miniatura_evidencias.dart';

class EvidenciasVisitaBoton extends StatefulWidget {
  final int? idVisita;
  final VisitaEstado estado;

  const EvidenciasVisitaBoton({
    super.key,
    required this.idVisita,
    required this.estado,
  });

  @override
  State<EvidenciasVisitaBoton> createState() => _EvidenciasVisitaBotonState();
}

class _EvidenciasVisitaBotonState extends State<EvidenciasVisitaBoton> {
  bool _cargando = false;
  List<EvidenciaFotograficaModel> _fotos = const [];

  static const Set<VisitaEstado> _estadosConEvidencia = {
    VisitaEstado.visitado,
    VisitaEstado.completada,
    VisitaEstado.cancelada,
    VisitaEstado.noAsistio,
  };

  bool get _corresponde =>
      widget.idVisita != null && _estadosConEvidencia.contains(widget.estado);

  @override
  void initState() {
    super.initState();
    if (_corresponde) _cargar();
  }

  @override
  void didUpdateWidget(covariant EvidenciasVisitaBoton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.idVisita != widget.idVisita || oldWidget.estado != widget.estado) {
      _fotos = const [];
      if (_corresponde) {
        _cargar();
      } else {
        setState(() {});
      }
    }
  }

  Future<void> _cargar() async {
    final idVisita = widget.idVisita;
    if (idVisita == null) return;
    setState(() => _cargando = true);
    final apiClient = context.read<AuthProvider>().apiClient;
    try {
      final fotos = await EvidenciaRepository(apiClient).listarPorVisita(idVisita);
      if (!mounted) return;
      setState(() {
        _fotos = fotos.where((f) => f.urlAlmacenamiento.trim().isNotEmpty).toList()
          ..sort((a, b) {
            final fa = a.timestampCaptura ?? a.createdAt;
            final fb = b.timestampCaptura ?? b.createdAt;
            if (fa == null || fb == null) return (b.idFotografia ?? 0).compareTo(a.idFotografia ?? 0);
            return fb.compareTo(fa);
          });
        _cargando = false;
      });
    } on NetworkException {
      if (!mounted) return;
      setState(() => _cargando = false);
    } catch (_) {
      if (!mounted) return;
      setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_corresponde) return const SizedBox.shrink();
    return MiniaturaEvidencias(fotos: _fotos, cargando: _cargando);
  }
}
