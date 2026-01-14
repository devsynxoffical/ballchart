import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  // Production Railway URL
  static const String baseUrl = 'https://hoopstar-production.up.railway.app/api';
  
  final _storage = const FlutterSecureStorage();

  Future<Map<String, String>> _getHeaders() async {
    String?token = await _storage.read(key: 'jwt_token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: jsonEncode(body),
    );
    return _processResponse(response);
  }

  Future<dynamic> get(String endpoint) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
    );
    return _processResponse(response);
  }

  Future<dynamic> put(String endpoint, Map<String, dynamic> body) async {
    final headers = await _getHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: jsonEncode(body),
    );
    return _processResponse(response);
  }

  dynamic _processResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return {};
      try {
        return jsonDecode(response.body);
      } catch (e) {
        throw Exception('Failed to parse response: ${response.body}');
      }
    } else {
      // Error handling
      try {
        final body = jsonDecode(response.body);
        throw Exception(body['message'] ?? 'Something went wrong');
      } catch (e) {
        // Fallback for non-JSON errors (like HTML)
        final body = response.body;
        if (body.contains('<html')) {
             // Try to extract title or pre tag for cleaner error
             final titleMatch = RegExp(r'<title>(.*?)</title>').firstMatch(body);
             final preMatch = RegExp(r'<pre>(.*?)</pre>').firstMatch(body);
             if (preMatch != null) throw Exception('Server Error: ${preMatch.group(1)}');
             if (titleMatch != null) throw Exception('Server Error: ${titleMatch.group(1)}');
             throw Exception('Server returned HTML Error Page (${response.statusCode})');
        }
        throw Exception('Server Error (${response.statusCode}): $body');
      }
    }
  }

  Future<void> saveToken(String token) async {
    await _storage.write(key: 'jwt_token', value: token);
  }

  Future<void> clearToken() async {
    await _storage.delete(key: 'jwt_token');
  }
}
