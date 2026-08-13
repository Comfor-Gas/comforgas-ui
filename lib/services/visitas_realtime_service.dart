import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../config/api_config.dart';
import '../utils/json_parsing.dart';

class VisitaRealtimeEvent {
  final int idVisita;
  final String? estadoVisita;
  final String? alertaTipo;
  final double? latitud;
  final double? longitud;
  final String? horaCheckIn;

  const VisitaRealtimeEvent({
    required this.idVisita,
    this.estadoVisita,
    this.alertaTipo,
    this.latitud,
    this.longitud,
    this.horaCheckIn,
  });

  factory VisitaRealtimeEvent.fromJson(Map<String, dynamic> json) {
    return VisitaRealtimeEvent(
      idVisita: parseInt(json['idVisita']) ?? 0,
      estadoVisita: json['estadoVisita'] as String?,
      alertaTipo: json['alertaTipo'] as String?,
      latitud: parseDouble(json['latitud']),
      longitud: parseDouble(json['longitud']),
      horaCheckIn: json['horaCheckIn'] as String?,
    );
  }
}

class VisitasRealtimeService {
  WebSocketChannel? _channel;
  StreamController<VisitaRealtimeEvent>? _controller;
  Timer? _reconnectTimer;
  bool _manuallyDisconnected = true;

  Stream<VisitaRealtimeEvent> get events =>
      (_controller ??= StreamController<VisitaRealtimeEvent>.broadcast())
          .stream;

  bool get isConnected => _channel != null;

  void connect() {
    _manuallyDisconnected = false;
    _openChannel();
  }

  void _openChannel() {
    final uri = Uri.parse(
      '${ApiConfig.wsBaseUrl}${ApiConfig.seguimientoWsPath}',
    );
    try {
      final channel = WebSocketChannel.connect(uri);
      _channel = channel;
      channel.stream.listen(
        _handleMessage,
        onError: (_) => _scheduleReconnect(),
        onDone: _scheduleReconnect,
        cancelOnError: true,
      );
    } catch (_) {
      _scheduleReconnect();
    }
  }

  void _handleMessage(dynamic raw) {
    try {
      final decoded = jsonDecode(raw as String);
      if (decoded is Map<String, dynamic>) {
        (_controller ??= StreamController<VisitaRealtimeEvent>.broadcast())
            .add(VisitaRealtimeEvent.fromJson(decoded));
      }
    } catch (_) {
    }
  }

  void _scheduleReconnect() {
    _channel = null;
    if (_manuallyDisconnected) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), _openChannel);
  }

  void disconnect() {
    _manuallyDisconnected = true;
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
  }

  void dispose() {
    disconnect();
    _controller?.close();
    _controller = null;
  }
}
