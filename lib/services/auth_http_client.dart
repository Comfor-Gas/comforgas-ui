import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'secure_storage_service.dart';


class AuthHttpClient extends http.BaseClient {
  final http.Client _inner;
  final http.Client _refreshInner;
  final SecureStorageService _storage;

  final Future<void> Function() onSessionExpired;

  AuthHttpClient({
    required this.onSessionExpired,
    http.Client? inner,
    http.Client? refreshInner,
    SecureStorageService? storage,
  })  : _inner = inner ?? http.Client(),
        _refreshInner = refreshInner ?? http.Client(),
        _storage = storage ?? SecureStorageService();

  Future<bool>? _refreshInFlight;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final token = await _storage.readAccessToken();
    final response = await _inner.send(await _copy(request, token));

    if (response.statusCode != 401) {
      return response;
    }

    // libera el body y renoueva el token (una sola vez, compartido).
    await response.stream.drain<void>();
    final refreshed = await _refreshOnce();

    if (!refreshed) {
      // el refresh inválido, enonces cerrar sesion y redirige.
      await onSessionExpired();
      return _unauthorized(request);
    }

    // Reintenta la petición original UNA vez con el token nuevo.
    final newToken = await _storage.readAccessToken();
    return _inner.send(await _copy(request, newToken));
  }

  /// Ejecuta el refresh una sola vez aunque varias peticiones lo pidan a la vez.
  Future<bool> _refreshOnce() {
    _refreshInFlight ??=
        _doRefresh().whenComplete(() => _refreshInFlight = null);
    return _refreshInFlight!;
  }

  Future<bool> _doRefresh() async {
    final refreshToken = await _storage.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return false;

    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.refreshPath}');
      final res = await _refreshInner
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'refreshToken': refreshToken}),
          )
          .timeout(const Duration(seconds: 20));

      if (res.statusCode != 200 && res.statusCode != 201) return false;

      final decoded = jsonDecode(res.body);
      if (decoded is! Map<String, dynamic>) return false;

      final access =
          (decoded['accessToken'] ?? decoded['access_token'] ?? '').toString();
      final refresh =
          (decoded['refreshToken'] ?? decoded['refresh_token'] ?? '').toString();
      if (access.isEmpty) return false;

      await _storage.saveTokens(accessToken: access, refreshToken: refresh);
      return true;
    } catch (_) {
      return false;
    }
  }


  Future<http.BaseRequest> _copy(http.BaseRequest original, String? token) async {
    http.BaseRequest out;

    if (original is http.Request) {
      out = http.Request(original.method, original.url)
        ..headers.addAll(original.headers)
        ..followRedirects = original.followRedirects
        ..maxRedirects = original.maxRedirects
        ..persistentConnection = original.persistentConnection
        ..bodyBytes = original.bodyBytes;
    } else {
      out = original;
    }

    if (token != null && token.isNotEmpty) {
      out.headers['Authorization'] = 'Bearer $token';
    }
    return out;
  }

  http.StreamedResponse _unauthorized(http.BaseRequest request) {
    return http.StreamedResponse(
      const Stream<List<int>>.empty(),
      401,
      request: request,
      reasonPhrase: 'Unauthorized',
    );
  }

  @override
  void close() {
    _inner.close();
    _refreshInner.close();
    super.close();
  }
}
