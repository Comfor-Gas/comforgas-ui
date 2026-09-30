import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/credito_cliente.dart';

class CreditoClienteRepository {
  final http.Client _client;

  CreditoClienteRepository(this._client);

  Future<CreditoCliente?> obtener(int idClienteExt, {Duration espera = const Duration(seconds: 4)}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.choferCreditoClientePath(idClienteExt)}');
    try {
      final response = await _client.get(uri).timeout(espera);
      if (response.statusCode != 200) return null;
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map<String, dynamic>) return null;
      final credito = CreditoCliente.fromSnapshot(decoded);
      return credito.tieneDatos ? credito : null;
    } catch (_) {
      return null;
    }
  }
}
