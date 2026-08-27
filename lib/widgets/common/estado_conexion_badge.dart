import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/connectivity_service.dart';
import '../../theme/app_colors.dart';

class EstadoConexionBadge extends StatefulWidget {
  final bool compacto;
  final bool claro;

  const EstadoConexionBadge({
    super.key,
    this.compacto = false,
    this.claro = false,
  });

  @override
  State<EstadoConexionBadge> createState() => _EstadoConexionBadgeState();
}

class _EstadoConexionBadgeState extends State<EstadoConexionBadge> {
  StreamSubscription<bool>? _sub;
  bool? _online;

  @override
  void initState() {
    super.initState();
    ConnectivityService.instance.tieneConexion().then((valor) {
      if (mounted) setState(() => _online = valor);
    });
    _sub = ConnectivityService.instance.observarConexion().listen((valor) {
      if (mounted) setState(() => _online = valor);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final online = _online ?? true;
    final color = online ? AppColors.badgeGreen : AppColors.badgeGray;
    final texto = online ? 'Online' : 'Offline';
    final icono = online ? Icons.wifi : Icons.wifi_off;

    final fondo = widget.claro
        ? AppColors.white.withOpacity(0.16)
        : color.withOpacity(0.12);
    final colorContenido = widget.claro ? AppColors.white : color;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: widget.compacto ? 8 : 10,
        vertical: widget.compacto ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: widget.claro
              ? AppColors.white.withOpacity(0.4)
              : color.withOpacity(0.45),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: colorContenido,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: widget.compacto ? 5 : 6),
          Icon(icono, size: widget.compacto ? 12 : 14, color: colorContenido),
          SizedBox(width: widget.compacto ? 4 : 6),
          Text(
            texto,
            style: TextStyle(
              fontSize: widget.compacto ? 11 : 12.5,
              fontWeight: FontWeight.w700,
              color: colorContenido,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
