import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../storage/token_store.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;
  @override
  String toString() => message;
}

class ApiClient {
  ApiClient(this._tokens);
  final TokenStore _tokens;

  Future<dynamic> get(String path) => _send('GET', path);
  Future<dynamic> post(String path, [Map<String, dynamic>? body]) =>
      _send('POST', path, body);
  Future<dynamic> patch(String path, Map<String, dynamic> body) =>
      _send('PATCH', path, body);

  Future<dynamic> _send(
    String method,
    String path, [
    Map<String, dynamic>? body,
  ]) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl.replaceFirst(RegExp(r'/+$'), '')}/$path',
    );
    final token = await _tokens.read();
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    try {
      final request = http.Request(method, uri)..headers.addAll(headers);
      if (body != null) request.body = jsonEncode(body);
      final streamed = await request.send().timeout(ApiConfig.timeout);
      final response = await http.Response.fromStream(streamed)
          .timeout(ApiConfig.timeout);
      dynamic data;
      try {
        data = response.body.isEmpty
            ? <String, dynamic>{}
            : jsonDecode(response.body);
      } on FormatException {
        throw const ApiException('Respons server tidak dapat dibaca.');
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final message = _errorMessage(data, response.statusCode);
        throw ApiException(message, statusCode: response.statusCode);
      }
      return data;
    } on http.ClientException {
      throw const ApiException(
        'Server tidak dapat dijangkau. Pastikan Laravel aktif dan URL API '
        'sesuai perangkat (emulator atau HP fisik).',
      );
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw const ApiException('Server terlalu lama merespons. Coba lagi.');
    }
  }

  String _errorMessage(dynamic data, int statusCode) {
    if (data is Map) {
      final errors = data['errors'];
      if (errors is Map) {
        for (final value in errors.values) {
          if (value is List && value.isNotEmpty) {
            return value.first.toString();
          }
          if (value != null) return value.toString();
        }
      }
      final message = data['message']?.toString();
      if (message != null && message.isNotEmpty) return message;
    }
    return 'Permintaan gagal ($statusCode).';
  }
}
