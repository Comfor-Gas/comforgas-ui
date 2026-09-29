import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/control_comodato.dart';
import '../../../models/evidencia_fotografica_model.dart';
import '../../../models/evidencia_tipo.dart';
import '../../../providers/auth_provider.dart';
import '../../../repositories/evidencia_repository.dart';
import '../../common/evidencias/miniatura_evidencias.dart';

class FotoControlComodato extends StatefulWidget {
  final ControlComodato control;
  final double tamanio;

  const FotoControlComodato({super.key, required this.control, this.tamanio = 44});

  @override
  State<FotoControlComodato> createState() => _FotoControlComodatoState();
}

class _FotoControlComodatoState extends State<FotoControlComodato> {
  static final Map<int, List<EvidenciaFotograficaModel>> _cache = {};

  List<EvidenciaFotograficaModel> _fotos = const [];
  bool _cargando = false;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void didUpdateWidget(covariant FotoControlComodato oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.control.idVisita != widget.control.idVisita ||
        oldWidget.control.idEvidencia != widget.control.idEvidencia) {
      _fotos = const [];
      _cargar();
    }
  }

  List<EvidenciaFotograficaModel> _filtrar(List<EvidenciaFotograficaModel> todas) {
    final conUrl = todas.where((f) => f.urlAlmacenamiento.trim().isNotEmpty).toList();
    final idEvidencia = widget.control.idEvidencia;
    if (idEvidencia != null) {
      final exacta = conUrl.where((f) => f.idFotografia == idEvidencia).toList();
      if (exacta.isNotEmpty) return exacta;
    }
    return conUrl
        .where((f) => f.tipoEvidencia.trim().toUpperCase() == EvidenciaTipo.comodato)
        .toList();
  }

  Future<void> _cargar() async {
    final idVisita = widget.control.idVisita;
    if (idVisita == null) {
      if (mounted) setState(() => _cargando = false);
      return;
    }
    final enCache = _cache[idVisita];
    if (enCache != null) {
      setState(() => _fotos = _filtrar(enCache));
      return;
    }
    setState(() => _cargando = true);
    try {
      final todas = await EvidenciaRepository(context.read<AuthProvider>().apiClient).listarPorVisita(idVisita);
      if (_filtrar(todas).isNotEmpty) _cache[idVisita] = todas;
      if (!mounted || widget.control.idVisita != idVisita) return;
      setState(() {
        _fotos = _filtrar(todas);
        _cargando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MiniaturaEvidencias(
      fotos: _fotos,
      cargando: _cargando,
      tamanio: widget.tamanio,
      tituloGaleria: 'Foto del control de comodato',
      mostrarVacio: true,
      contadorSiempre: false,
    );
  }
}
