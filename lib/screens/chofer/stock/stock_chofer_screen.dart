import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/stock_rodante_chofer.dart';
import '../../../providers/auth_provider.dart';
import '../../../repositories/network_exception.dart';
import '../../../repositories/stock_rodante_repository.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../widgets/chofer/stock/desglose_tipo_card.dart';
import '../../../widgets/chofer/stock/stock_disponible_card.dart';

class StockChoferScreen extends StatefulWidget {
  const StockChoferScreen({super.key});

  @override
  State<StockChoferScreen> createState() => _StockChoferScreenState();
}

class _StockChoferScreenState extends State<StockChoferScreen> {
  bool _loading = true;
  String? _error;
  bool _sinCarga = false;
  StockRodanteChofer? _stock;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final auth = context.read<AuthProvider>();
    final idUsuario = auth.user?.id;
    if (idUsuario == null || idUsuario.isEmpty) {
      setState(() {
        _error = 'No pudimos identificar tu usuario. Volvé a iniciar sesión.';
        _loading = false;
      });
      return;
    }
    try {
      final stock = await StockRodanteRepository(auth.apiClient).getMiStock(idUsuario: idUsuario);
      if (!mounted) return;
      setState(() {
        _stock = stock;
        _sinCarga = stock == null;
        _loading = false;
      });
    } on NetworkException {
      if (!mounted) return;
      setState(() {
        _error = 'Sin conexión. No pudimos actualizar el stock de tu camión.';
        _loading = false;
      });
    } on StockRodanteRepositoryException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudo cargar el stock de tu camión.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _Encabezado(),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.orange,
              onRefresh: _cargar,
              child: _cuerpo(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cuerpo() {
    if (_loading && _stock == null) {
      return const Center(child: CircularProgressIndicator(color: AppColors.orange));
    }

    final stock = _stock;
    final productos = stock?.ordenados ?? const <StockRodanteProducto>[];

    final cargaInicial = [
      for (final p in productos)
        if (p.llenosSalida > 0) DesgloseTipoItem(etiqueta: p.etiqueta, cantidad: p.llenosSalida),
    ];
    final recargas = [
      for (final p in productos)
        if (p.recargasLlenos > 0) DesgloseTipoItem(etiqueta: p.etiqueta, cantidad: p.recargasLlenos),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        if (_error != null) ...[
          _AvisoError(mensaje: _error!),
          const SizedBox(height: 16),
        ],
        if (_sinCarga && _error == null)
          _VacioCard()
        else ...[
          StockDisponibleCard(productos: productos),
          const SizedBox(height: 22),
          _TituloSeccion(icono: Icons.assignment_turned_in_outlined, texto: 'Carga inicial'),
          const SizedBox(height: 10),
          DesgloseTipoCard(
            items: cargaInicial,
            total: stock?.totalCargaInicial ?? 0,
            mensajeVacio: 'Todavía no hay una carga inicial publicada para hoy.',
          ),
          const SizedBox(height: 22),
          _TituloSeccion(icono: Icons.add_road_outlined, texto: 'Recargas recibidas'),
          const SizedBox(height: 10),
          DesgloseTipoCard(
            items: recargas,
            total: stock?.totalRecargas ?? 0,
            mensajeVacio: 'No recibiste recargas en ruta hoy.',
          ),
        ],
      ],
    );
  }
}

class _Encabezado extends StatelessWidget {
  const _Encabezado();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
      child: Text('Stock de mi camión', style: AppTextStyles.title.copyWith(fontSize: 20)),
    );
  }
}

class _TituloSeccion extends StatelessWidget {
  final IconData icono;
  final String texto;

  const _TituloSeccion({required this.icono, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icono, size: 18, color: AppColors.orange),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            texto,
            style: AppTextStyles.label.copyWith(fontSize: 14.5, color: AppColors.orange),
          ),
        ),
      ],
    );
  }
}

class _VacioCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Column(
        children: [
          const Icon(Icons.inventory_2_outlined, size: 44, color: AppColors.inputHint),
          const SizedBox(height: 12),
          Text(
            'Todavía no tenés una carga asignada para hoy.',
            textAlign: TextAlign.center,
            style: AppTextStyles.input.copyWith(color: AppColors.graphiteGray),
          ),
        ],
      ),
    );
  }
}

class _AvisoError extends StatelessWidget {
  final String mensaje;

  const _AvisoError({required this.mensaje});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.badgeAmber.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.badgeAmber.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 18, color: AppColors.badgeAmber),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              mensaje,
              style: AppTextStyles.footer.copyWith(color: AppColors.graphiteGray),
            ),
          ),
        ],
      ),
    );
  }
}
