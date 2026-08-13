import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import '../config/api_config.dart';
import '../models/visita_alerta.dart';
import '../utils/json_parsing.dart';

sealed class VisitaRealtimeMessage {}
class VisitaEstadoActualizadoMessage extends VisitaRealtimeMessage {
  final int idVisita;
  final String idChofer;
  final String? nombreChofer;
  final String estadoNuevo;
  final DateTime? timestampInicio;
  final DateTime? timestampFin;
  final double? latitud;
  final double? longitud;
  final bool? geolocalizacionValida;

  VisitaEstadoActualizadoMessage({
    required this.idVisita,
    required this.idChofer,
    this.nombreChofer,
    required this.estadoNuevo,
    this.timestampInicio,
    this.timestampFin,
    this.latitud,
    this.longitud,
    this.geolocalizacionValida,
  });

  factory VisitaEstadoActualizadoMessage.fromJson(Map<String, dynamic> json) {
    return VisitaEstadoActualizadoMessage(
      idVisita: parseInt(json['idVisita']) ?? 0,
      idChofer: (json['idChofer'] ?? '').toString(),
      nombreChofer: json['nombreChofer'] as String?,
      estadoNuevo: (json['estadoNuevo'] ?? '').toString(),
      timestampInicio: parseDate(json['timestampInicio']),
      timestampFin: parseDate(json['timestampFin']),
      latitud: parseDouble(json['latitud']),
      longitud: parseDouble(json['longitud']),
      geolocalizacionValida: json['geolocalizacionValida'] as bool?,
    );
  }
}

class AlertaCreadaMessage extends VisitaRealtimeMessage {
  final int idAlerta;
  final int idVisita;
  final String idChofer;
  final VisitaAlertaTipo? tipo;
  final VisitaAlertaEstado estado;
  final String? descripcion;

  AlertaCreadaMessage({
    required this.idAlerta,
    required this.idVisita,
    required this.idChofer,
    this.tipo,
    this.estado = VisitaAlertaEstado.abierta,
    this.descripcion,
  });

  factory AlertaCreadaMessage.fromJson(Map<String, dynamic> json) {
    return AlertaCreadaMessage(
      idAlerta: parseInt(json['idAlerta']) ?? 0,
      idVisita: parseInt(json['idVisita']) ?? 0,
      idChofer: (json['idChofer'] ?? '').toString(),
      tipo: VisitaAlertaMapper.fromValue(json['tipo']),
      estado: VisitaAlertaMapper.estadoFromValue(json['estado']),
      descripcion: json['descripcion'] as String?,
    );
  }
}

class VisitasRealtimeService {
  static const String _destination = '/topic/admin/visitas';

  StompClient? _client;
  final StreamController<VisitaRealtimeMessage> _messagesController =
      StreamController<VisitaRealtimeMessage>.broadcast();
  final StreamController<bool> _connectionController =
      StreamController<bool>.broadcast();

  Stream<VisitaRealtimeMessage> get messages => _messagesController.stream;
  Stream<bool> get connectionState => _connectionController.stream;

  void connect(String accessToken) {
    final url = '${ApiConfig.wsBaseUrl}${ApiConfig.seguimientoWsPath}';
    if (kDebugMode) {
      debugPrint('[VisitasRealtimeService] conectando a $url');
    }
    _client = StompClient(
      config: StompConfig(
        url: url,
        stompConnectHeaders: {'Authorization': 'Bearer $accessToken'},
        reconnectDelay: const Duration(seconds: 5),
        onConnect: _onConnect,
        onWebSocketError: (dynamic error) {
          if (kDebugMode) {
            debugPrint('[VisitasRealtimeService] onWebSocketError: $error');
          }
          _connectionController.add(false);
        },
        onStompError: (frame) {
          if (kDebugMode) {
            debugPrint(
              '[VisitasRealtimeService] onStompError: ${frame.headers['message']} · ${frame.body}',
            );
          }
          _connectionController.add(false);
        },
        onDisconnect: (frame) {
          if (kDebugMode) {
            debugPrint('[VisitasRealtimeService] onDisconnect');
          }
          _connectionController.add(false);
        },
        onDebugMessage: (message) {
          if (kDebugMode) {
            debugPrint('[VisitasRealtimeService][debug] $message');
          }
        },
      ),
    );
    _client!.activate();
  }

  void _onConnect(StompFrame connectFrame) {
    _connectionController.add(true);
    _client!.subscribe(destination: _destination, callback: _handleFrame);
  }

  void _handleFrame(StompFrame frame) {
    final body = frame.body;
    if (body == null || body.isEmpty) return;
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) return;
      switch (decoded['eventType']) {
        case 'VISITA_ESTADO_ACTUALIZADO':
          _messagesController.add(VisitaEstadoActualizadoMessage.fromJson(decoded));
        case 'ALERTA_CREADA':
          _messagesController.add(AlertaCreadaMessage.fromJson(decoded));
      }
    } catch (_) {
      return;
    }
  }

  void disconnect() {
    _client?.deactivate();
    _client = null;
  }

  void dispose() {
    disconnect();
    _messagesController.close();
    _connectionController.close();
  }
}
