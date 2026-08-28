import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/responsive.dart';
import '../../data/mock_cobranza_data.dart';
import '../../models/cuenta_corriente_resumen.dart';
import '../../providers/auth_provider.dart';
import '../../repositories/cobranza_repository.dart';
import '../../repositories/network_exception.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/formato.dart';
import '../../widgets/admin/cobranza/cuentas_corrientes_tabla.dart';
import '../../widgets/admin/flota/flota_form_controls.dart';
import '../../widgets/admin/flota/flota_stat_card.dart';

class CuentasCorrientesScreen extends StatefulWidget {
  const CuentasCorrientesScreen({super.key});

  @override
  State<CuentasCorrientesScreen> createState() => _CuentasCorrientesScreenState();
}

class _CuentasCorrientesScreenState extends State<CuentasCorrientesScreen> {
  late final CobranzaRepository _repo;
  final _searchCtrl = TextEditingController();

  ReporteCuentasCorrientes _reporte = const ReporteCuentasCorrientes();
  bool _loading = true;
  bool _modoEjemplo = false;
  bool _soloMorosos = false;
  String? _aviso;

  @override
  void initState() {
    super.initState();
    _repo = CobranzaRepository(context.read<AuthProvider>().apiClient);
    _searchCtrl.addListener(() => setState(() {}));
    _cargar();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() {
      _loading = true;
      _aviso = null;
    });
    try {
      final reporte = await _repo.getReporteCuentasCorrientes(soloMorosos: _soloMorosos);
      if (!mounted) return;
      setState(() {
        _reporte = reporte;
        _modoEjemplo = false;
        _loading = false;
      });
    } on NetworkException {
      _usarEjemplo('No se pudo conectar con el servidor: mostrando datos de ejemplo.');
    } on CobranzaRepositoryException catch (e) {
      if (e.endpointNoDisponible) {
        _usarEjemplo('El reporte de cuentas corrientes aún no está en el backend: mostrando datos de ejemplo.');
      } else {
        _usarEjemplo(e.message);
      }
    } catch (_) {
      _usarEjemplo('Ocurrió un problema al cargar el reporte: mostrando datos de ejemplo.');
    }
  }

  void _usarEjemplo(String mensaje) {
    if (!mounted) return;
    setState(() {
      _reporte = reporteCuentasDeEjemplo();
      _modoEjemplo = true;
      _aviso = mensaje;
      _loading = false;
    });
  }

  List<CuentaCorrienteResumen> get _clientesFiltrados {
    final query = _searchCtrl.text.trim().toLowerCase();
    return _reporte.clientes.where((c) {
      if (_soloMorosos && !c.moroso) return false;
      if (query.isNotEmpty && !c.nombreCliente.toLowerCase().contains(query)) return false;
      return true;
    }).toList();
  }

  void _verDetalle(CuentaCorrienteResumen cliente) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _DetalleSheet(cliente: cliente),
    );
  }

  void _generarPdf() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Exportación a PDF: pendiente de habilitar en el backend.'),
        backgroundColor: AppColors.badgeAmber,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = Responsive.isDesktop(constraints);
        final padding = EdgeInsets.all(isDesktop ? 28 : 16);
        return SingleChildScrollView(
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Cabecera(onPdf: _generarPdf),
              const SizedBox(height: 20),
              _Stats(reporte: _reporte),
              const SizedBox(height: 16),
              _Filtros(
                searchCtrl: _searchCtrl,
                soloMorosos: _soloMorosos,
                onToggleMorosos: (v) {
                  setState(() => _soloMorosos = v);
                  _cargar();
                },
              ),
              if (_aviso != null) ...[
                const SizedBox(height: 16),
                _AvisoBanner(mensaje: _aviso!, esEjemplo: _modoEjemplo),
              ],
              const SizedBox(height: 20),
              _TarjetaTabla(
                cantidad: _clientesFiltrados.length,
                child: _loading
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 60),
                        child: Center(child: CircularProgressIndicator(color: AppColors.orange)),
                      )
                    : CuentasCorrientesTabla(
                        clientes: _clientesFiltrados,
                        onVerDetalle: _verDetalle,
                        mensajeVacio: _reporte.clientes.isEmpty
                            ? 'No hay clientes con cuenta corriente.'
                            : 'No hay clientes que coincidan con los filtros.',
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Cabecera extends StatelessWidget {
  final VoidCallback onPdf;

  const _Cabecera({required this.onPdf});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Reporte de Cuentas Corrientes', style: AppTextStyles.desktopTitle),
              const SizedBox(height: 4),
              Text(
                'Saldos y deuda pendiente por cliente comercial.',
                style: AppTextStyles.desktopSubtitle,
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        SizedBox(
          width: 190,
          child: FlotaBotonPrimario(
            texto: 'Generar Reporte PDF',
            icono: Icons.picture_as_pdf_outlined,
            onTap: onPdf,
          ),
        ),
      ],
    );
  }
}

class _Stats extends StatelessWidget {
  final ReporteCuentasCorrientes reporte;

  const _Stats({required this.reporte});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final fila = constraints.maxWidth >= 560;
        final cards = [
          FlotaStatCard(
            icon: Icons.account_balance_wallet_outlined,
            etiqueta: 'Total Deuda Clientes',
            valor: formatMoneda(reporte.totalDeuda),
            acento: AppColors.orange,
          ),
          FlotaStatCard(
            icon: Icons.person_off_outlined,
            etiqueta: 'Clientes Morosos',
            valor: '${reporte.clientesMorosos}',
            acento: AppColors.error,
          ),
        ];
        if (fila) {
          return Row(
            children: [
              Expanded(child: cards[0]),
              const SizedBox(width: 16),
              Expanded(child: cards[1]),
            ],
          );
        }
        return Column(
          children: [cards[0], const SizedBox(height: 12), cards[1]],
        );
      },
    );
  }
}

class _Filtros extends StatelessWidget {
  final TextEditingController searchCtrl;
  final bool soloMorosos;
  final ValueChanged<bool> onToggleMorosos;

  const _Filtros({
    required this.searchCtrl,
    required this.soloMorosos,
    required this.onToggleMorosos,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 280,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.inputBorder),
            ),
            child: TextField(
              controller: searchCtrl,
              style: AppTextStyles.input,
              decoration: InputDecoration(
                hintText: 'Buscar cliente',
                hintStyle: AppTextStyles.hint,
                prefixIcon: const Icon(Icons.search, color: AppColors.inputHint, size: 20),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ),
        _ToggleMorosos(activo: soloMorosos, onTap: () => onToggleMorosos(!soloMorosos)),
      ],
    );
  }
}

class _ToggleMorosos extends StatelessWidget {
  final bool activo;
  final VoidCallback onTap;

  const _ToggleMorosos({required this.activo, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = activo ? AppColors.error : AppColors.inputBorder;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: activo ? AppColors.error.withOpacity(0.08) : AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color, width: activo ? 1.5 : 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              activo ? Icons.check_box_outlined : Icons.check_box_outline_blank,
              size: 18,
              color: activo ? AppColors.error : AppColors.graphiteGray,
            ),
            const SizedBox(width: 8),
            Text(
              'Solo morosos',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: activo ? AppColors.error : AppColors.graphiteGray,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TarjetaTabla extends StatelessWidget {
  final int cantidad;
  final Widget child;

  const _TarjetaTabla({required this.cantidad, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
            child: Row(
              children: [
                const Text('Clientes', style: AppTextStyles.label),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.steelBlue.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$cantidad',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.steelBlue),
                  ),
                ),
              ],
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _DetalleSheet extends StatelessWidget {
  final CuentaCorrienteResumen cliente;

  const _DetalleSheet({required this.cliente});

  @override
  Widget build(BuildContext context) {
    final disponible = cliente.limiteCredito - cliente.saldoUsado;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 14, 20, 24 + MediaQuery.of(context).padding.bottom),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.inputBorder,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(cliente.nombreCliente, style: AppTextStyles.title.copyWith(fontSize: 20)),
          const SizedBox(height: 14),
          _LineaDetalle(etiqueta: 'Límite de crédito', valor: formatMoneda(cliente.limiteCredito)),
          _LineaDetalle(etiqueta: 'Saldo usado', valor: formatMoneda(cliente.saldoUsado)),
          _LineaDetalle(
            etiqueta: 'Disponible',
            valor: formatMoneda(disponible),
            acento: disponible < 0 ? AppColors.error : AppColors.badgeGreen,
          ),
          _LineaDetalle(
            etiqueta: 'Vencido',
            valor: cliente.tieneVencido ? formatMoneda(cliente.montoVencido) : '—',
            acento: cliente.tieneVencido ? AppColors.error : null,
          ),
        ],
      ),
    );
  }
}

class _LineaDetalle extends StatelessWidget {
  final String etiqueta;
  final String valor;
  final Color? acento;

  const _LineaDetalle({required this.etiqueta, required this.valor, this.acento});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(etiqueta, style: AppTextStyles.link.copyWith(fontSize: 13.5))),
          Text(
            valor,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              color: acento ?? AppColors.steelBlue,
            ),
          ),
        ],
      ),
    );
  }
}

class _AvisoBanner extends StatelessWidget {
  final String mensaje;
  final bool esEjemplo;

  const _AvisoBanner({required this.mensaje, required this.esEjemplo});

  @override
  Widget build(BuildContext context) {
    final color = esEjemplo ? AppColors.badgeAmber : AppColors.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          Icon(esEjemplo ? Icons.info_outline : Icons.error_outline, size: 19, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              mensaje,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color),
            ),
          ),
        ],
      ),
    );
  }
}
