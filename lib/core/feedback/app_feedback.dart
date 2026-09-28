import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

enum AppFeedbackTipo { exito, error, advertencia, info }

class AppFeedback {
  AppFeedback._();

  static final GlobalKey<OverlayState> overlayKey = GlobalKey<OverlayState>();

  static const Duration duracionMaxima = Duration(seconds: 5);
  static const double _anchoEscritorio = 700;

  static void exito(String mensaje, {String titulo = 'Listo', Duration? duracion}) =>
      mostrar(AppFeedbackTipo.exito, mensaje, titulo: titulo, duracion: duracion);

  static void error(String mensaje, {String titulo = 'Ocurrió un error', Duration? duracion}) =>
      mostrar(AppFeedbackTipo.error, mensaje, titulo: titulo, duracion: duracion);

  static void advertencia(String mensaje, {String titulo = 'Atención', Duration? duracion}) =>
      mostrar(AppFeedbackTipo.advertencia, mensaje, titulo: titulo, duracion: duracion);

  static void info(String mensaje, {String titulo = 'Información', Duration? duracion}) =>
      mostrar(AppFeedbackTipo.info, mensaje, titulo: titulo, duracion: duracion);

  static void guardadoSinSenal(String mensaje, {Duration? duracion}) => mostrar(
        AppFeedbackTipo.info,
        mensaje,
        titulo: 'Guardado en el dispositivo',
        icono: Icons.cloud_off_outlined,
        duracion: duracion,
      );

  static void mostrar(
    AppFeedbackTipo tipo,
    String mensaje, {
    required String titulo,
    IconData? icono,
    Duration? duracion,
  }) {
    final overlay = overlayKey.currentState;
    if (overlay == null) return;

    final ancho = MediaQuery.maybeSizeOf(overlay.context)?.width ?? 0;
    final esEscritorio = ancho >= _anchoEscritorio;
    final efectiva = (duracion == null || duracion > duracionMaxima) ? duracionMaxima : duracion;

    toastification.show(
      overlayState: overlay,
      type: _tipo(tipo),
      style: ToastificationStyle.flatColored,
      alignment: kIsWeb || esEscritorio ? Alignment.bottomRight : Alignment.topCenter,
      autoCloseDuration: efectiva,
      title: Text(
        titulo,
        style: const TextStyle(fontWeight: FontWeight.w700),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      description: mensaje.trim().isEmpty || mensaje.trim() == titulo
          ? null
          : Text(mensaje, maxLines: 6, overflow: TextOverflow.ellipsis),
      icon: icono != null ? Icon(icono) : null,
      showProgressBar: false,
      closeOnClick: false,
      dragToClose: true,
      pauseOnHover: false,
      applyBlurEffect: false,
    );
  }

  static ToastificationType _tipo(AppFeedbackTipo tipo) {
    switch (tipo) {
      case AppFeedbackTipo.exito:
        return ToastificationType.success;
      case AppFeedbackTipo.error:
        return ToastificationType.error;
      case AppFeedbackTipo.advertencia:
        return ToastificationType.warning;
      case AppFeedbackTipo.info:
        return ToastificationType.info;
    }
  }
}
