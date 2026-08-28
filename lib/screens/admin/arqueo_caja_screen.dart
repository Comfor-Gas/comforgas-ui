import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/responsive.dart';
import '../../data/mock_cobranza_data.dart';
import '../../models/arqueo_caja.dart';
import '../../models/usuario_model.dart';
import '../../providers/auth_provider.dart';
import '../../repositories/catalogo_repository.dart';
import '../../repositories/cobranza_repository.dart';
import '../../repositories/network_exception.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/date_format_utils.dart';
import '../../utils/formato.dart';
import '../../widgets/admin/cobranza/arqueo_resumen_card.dart';
import '../../widgets/admin/cobranza/arqueo_tabla.dart';
import '../../widgets/admin/flota/flota_form_controls.dart';

class ArqueoCajaScreen extends StatefulWidget {
  const ArqueoCajaScreen({super.key});

  @override
  State<ArqueoCajaScreen> createState() => _ArqueoCajaScreenState();
}

class _ArqueoCajaScreenState extends State<ArqueoCajaScreen> {
  late final CobranzaRepository _repo;
  late final CatalogoRepository _catalogoRepo;

  List<UsuarioModel> _choferes = [];
  String? _choferId;
  DateTime _fecha = DateTime.now();

  ArqueoCaja? _arqueo;
  bool _loading = false;
  bool _modoEjemplo = false;
  String? _aviso;
  bool _cerrando = false;
  bool _cerrado = false;

  @override
  void initState() {
    super.initState();
    final apiClient = context.read<AuthProvider>().apiClient;
    _repo = CobranzaRepository(apiClient);
    _catalogoRepo = CatalogoRepository(apiClient);
    _cargarChoferes();
  }

  Future<void> _cargarChoferes() async {
    try {
      final choferes = await _catalogoRepo.listarUsuarios(rol: 'CHOFER');
      if (!mounted) return;
      setState(() {
        _choferes = choferes;
        if (choferes.isNotEmpty && _choferId == null) {
          _choferId = choferes.first.id;
        }
      });
      if (_choferId != null) _cargarArqueo();
    } catch (_) {
      if (!mounted) return;
      setState(() => _choferes = const []);
    }
  }

  String get _nombreChofer {
    for (final c in _choferes) {
      if (c.id == _choferId) return c.fullName.isNotEmpty ? c.fullName : c.email;
    }
    return 'Chofer';
  }

  Future<void> _cargarArqueo() async {
    final idUsuario = _choferId;
    if (idUsuario == null) return;
    setState(() {
      _loading = true;
      _aviso = null;
      _cerrado = false;
    });
    try {
      final arqueo = await _repo.getArqueo(idUsuario: idUsuario, fecha: _fecha);
      if (!mounted) return;
      setState(() {
        _arqueo = arqueo;
        _modoEjemplo = false;
        _loading = false;
        // Refleja el estado real que devuelve el backend: si ya estaba cerrado,
        // la pantalla lo muestra como cerrado aunque recién entremos.
        _cerrado = arqueo.cerrado;
      });
    } on NetworkException {
      _usarEjemplo('No se pudo conectar con el servidor: mostrando datos de ejemplo.');
    } on CobranzaRepositoryException catch (e) {
      if (e.endpointNoDisponible) {
        _usarEjemplo('El endpoint de arqueo aún no está disponible: mostrando datos de ejemplo.');
      } else {
        _usarEjemplo(e.message);
      }
    } catch (_) {
      _usarEjemplo('Ocurrió un problema al cargar el arqueo: mostrando datos de ejemplo.');
    }
  }

  void _usarEjemplo(String mensaje) {
    if (!mounted) return;
    setState(() {
      _arqueo = arqueoDeEjemplo(
        idUsuario: _choferId ?? 'demo',
        nombre: _nombreChofer,
        fecha: _fecha,
      );
      _modoEjemplo = true;
      _aviso = mensaje;
      _loading = false;
    });
  }

  Future<void> _elegirFecha() async {
    final elegida = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(2023),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.orange,
            onPrimary: AppColors.white,
            onSurface: AppColors.steelBlue,
          ),
        ),
        child: child!,
      ),
    );
    if (elegida != null) {
      setState(() => _fecha = elegida);
      _cargarArqueo();
    }
  }

  int _totalSistema(String metodo) {
    for (final m in _arqueo?.totalesPorMetodo ?? const <ArqueoMetodoTotal>[]) {
      if (m.metodoPago == metodo) return m.total;
    }
    return 0;
  }

  Future<void> _cerrarArqueo() async {
    final idUsuario = _choferId;
    if (idUsuario == null || _cerrando) return;

    // El cierre exige los montos declarados (arqueo auditado). Los pedimos
    // prellenados con lo que calculó el sistema, para que el admin confirme
    // o ajuste según lo contado físicamente.
    final declarado = await showDialog<_MontosDeclarados>(
      context: context,
      builder: (_) => _CierreArqueoDialog(
        efectivoSistema: _totalSistema('EFECTIVO'),
        chequeSistema: _totalSistema('CHEQUE'),
        transferenciaSistema: _totalSistema('TRANSFERENCIA'),
      ),
    );
    if (declarado == null || !mounted) return;

    setState(() => _cerrando = true);
    try {
      if (!_modoEjemplo) {
        await _repo.cerrarArqueo(
          idUsuario: idUsuario,
          fecha: _fecha,
          efectivoDeclarado: declarado.efectivo,
          chequeDeclarado: declarado.cheque,
          transferenciaDeclarada: declarado.transferencia,
          observacion: declarado.observacion,
        );
      }
      if (!mounted) return;
      setState(() {
        _cerrado = true;
        _cerrando = false;
      });
      _snack('Arqueo cerrado y auditado.');
    } on CobranzaRepositoryException catch (e) {
      if (!mounted) return;
      setState(() {
        _cerrando = false;
        _cerrado = e.endpointNoDisponible;
      });
      _snack(
        e.endpointNoDisponible
            ? 'Cierre local: el endpoint de cierre todavía no está en el backend.'
            : e.message,
        error: !e.endpointNoDisponible,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _cerrando = false);
      _snack('No se pudo cerrar el arqueo.', error: true);
    }
  }

  void _snack(String mensaje, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: error ? AppColors.error : AppColors.badgeGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = Responsive.isDesktop(constraints);
        final dosColumnas = constraints.maxWidth >= 1200;
        final padding = EdgeInsets.all(isDesktop ? 28 : 16);
        return SingleChildScrollView(
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Cabecera(nombreChofer: _nombreChofer),
              const SizedBox(height: 20),
              _Filtros(
                choferes: _choferes,
                choferId: _choferId,
                fecha: _fecha,
                onChofer: (id) {
                  setState(() => _choferId = id);
                  _cargarArqueo();
                },
                onFecha: _elegirFecha,
              ),
              if (_aviso != null) ...[
                const SizedBox(height: 16),
                _AvisoBanner(mensaje: _aviso!, esEjemplo: _modoEjemplo),
              ],
              const SizedBox(height: 20),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 70),
                  child: Center(child: CircularProgressIndicator(color: AppColors.orange)),
                )
              else if (_arqueo == null)
                _Placeholder()
              else if (dosColumnas)
                _contenidoDosColumnas()
              else
                _contenidoApilado(),
            ],
          ),
        );
      },
    );
  }

  Widget _contenidoDosColumnas() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _tarjetaTabla()),
        const SizedBox(width: 20),
        SizedBox(width: 320, child: _resumen()),
      ],
    );
  }

  Widget _contenidoApilado() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _tarjetaTabla(),
        const SizedBox(height: 20),
        _resumen(),
      ],
    );
  }

  Widget _tarjetaTabla() {
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
            child: Text(
              'Liquidación Diaria: $_nombreChofer',
              style: AppTextStyles.label.copyWith(fontSize: 15),
            ),
          ),
          ArqueoTabla(movimientos: _arqueo!.movimientos),
        ],
      ),
    );
  }

  Widget _resumen() {
    final arqueo = _arqueo!;
    return ArqueoResumenCard(
      totales: arqueo.totalesPorMetodo,
      totalGeneral: arqueo.totalGeneral,
      cerrado: _cerrado,
      cerrando: _cerrando,
      onCerrar: _cerrarArqueo,
    );
  }
}

class _Cabecera extends StatelessWidget {
  final String nombreChofer;

  const _Cabecera({required this.nombreChofer});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Arqueo de Caja', style: AppTextStyles.desktopTitle),
        const SizedBox(height: 4),
        Text(
          'Conciliación diaria de fondos por chofer, auditando hora física del cobro vs. hora de sincronización.',
          style: AppTextStyles.desktopSubtitle,
        ),
      ],
    );
  }
}

class _Filtros extends StatelessWidget {
  final List<UsuarioModel> choferes;
  final String? choferId;
  final DateTime fecha;
  final ValueChanged<String> onChofer;
  final VoidCallback onFecha;

  const _Filtros({
    required this.choferes,
    required this.choferId,
    required this.fecha,
    required this.onChofer,
    required this.onFecha,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 260,
          child: FlotaDropdown<String>(
            value: choferId,
            hint: 'Seleccionar chofer',
            prefijo: Icons.person_outline,
            items: [
              for (final c in choferes)
                DropdownMenuItem(
                  value: c.id,
                  child: Text(c.fullName.isNotEmpty ? c.fullName : c.email),
                ),
            ],
            onChanged: (id) {
              if (id != null) onChofer(id);
            },
          ),
        ),
        _BotonFecha(fecha: fecha, onTap: onFecha),
      ],
    );
  }
}

class _BotonFecha extends StatelessWidget {
  final DateTime fecha;
  final VoidCallback onTap;

  const _BotonFecha({required this.fecha, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.inputBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.inputHint),
            const SizedBox(width: 10),
            Text(
              formatFechaCorta(fecha),
              style: AppTextStyles.input,
            ),
          ],
        ),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Center(
        child: Text(
          'Elegí un chofer y una fecha para ver la liquidación.',
          style: AppTextStyles.link,
          textAlign: TextAlign.center,
        ),
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

/// Resultado del diálogo de cierre: los montos que el admin declara haber
/// contado físicamente, más una observación opcional.
class _MontosDeclarados {
  final int efectivo;
  final int cheque;
  final int transferencia;
  final String? observacion;

  const _MontosDeclarados({
    required this.efectivo,
    required this.cheque,
    required this.transferencia,
    this.observacion,
  });
}

class _CierreArqueoDialog extends StatefulWidget {
  final int efectivoSistema;
  final int chequeSistema;
  final int transferenciaSistema;

  const _CierreArqueoDialog({
    required this.efectivoSistema,
    required this.chequeSistema,
    required this.transferenciaSistema,
  });

  @override
  State<_CierreArqueoDialog> createState() => _CierreArqueoDialogState();
}

class _CierreArqueoDialogState extends State<_CierreArqueoDialog> {
  late final TextEditingController _efectivo;
  late final TextEditingController _cheque;
  late final TextEditingController _transferencia;
  final _observacion = TextEditingController();

  @override
  void initState() {
    super.initState();
    _efectivo = TextEditingController(text: '${widget.efectivoSistema}');
    _cheque = TextEditingController(text: '${widget.chequeSistema}');
    _transferencia = TextEditingController(text: '${widget.transferenciaSistema}');
  }

  @override
  void dispose() {
    _efectivo.dispose();
    _cheque.dispose();
    _transferencia.dispose();
    _observacion.dispose();
    super.dispose();
  }

  int _leer(TextEditingController c) => int.tryParse(c.text.trim()) ?? 0;

  void _confirmar() {
    Navigator.of(context).pop(_MontosDeclarados(
      efectivo: _leer(_efectivo),
      cheque: _leer(_cheque),
      transferencia: _leer(_transferencia),
      observacion: _observacion.text,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Cerrar arqueo auditado', style: AppTextStyles.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Ingresá los montos contados físicamente. Vienen prellenados con '
              'lo que registró el sistema; ajustalos si hay diferencia.',
              style: AppTextStyles.link.copyWith(fontSize: 12.5),
            ),
            const SizedBox(height: 16),
            _campo('Efectivo', _efectivo, widget.efectivoSistema),
            const SizedBox(height: 14),
            _campo('Cheque', _cheque, widget.chequeSistema),
            const SizedBox(height: 14),
            _campo('Transferencia', _transferencia, widget.transferenciaSistema),
            const SizedBox(height: 16),
            TextField(
              controller: _observacion,
              maxLines: 2,
              cursorColor: AppColors.orange,
              decoration: InputDecoration(
                labelText: 'Observación (opcional)',
                isDense: true,
                enabledBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.inputBorder),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.orange),
                ),
                floatingLabelStyle: const TextStyle(color: AppColors.orange),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancelar',
            style: AppTextStyles.button.copyWith(color: AppColors.graphiteGray),
          ),
        ),
        TextButton(
          onPressed: _confirmar,
          child: Text(
            'Cerrar arqueo',
            style: AppTextStyles.button.copyWith(color: AppColors.orange),
          ),
        ),
      ],
    );
  }

  Widget _campo(String label, TextEditingController controller, int sistema) {
    final declarado = _leer(controller);
    final dif = declarado - sistema;
    final Color colorDif = dif == 0
        ? AppColors.badgeGreen
        : (dif > 0 ? AppColors.steelBlue : AppColors.error);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.label.copyWith(fontSize: 13)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (_) => setState(() {}),
          cursorColor: AppColors.orange,
          decoration: const InputDecoration(
            prefixText: '\$ ',
            isDense: true,
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.inputBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.orange),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Sistema: ${formatMoneda(sistema)}  ·  Diferencia: ${formatMoneda(dif)}',
          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: colorDif),
        ),
      ],
    );
  }
}
