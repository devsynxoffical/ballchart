import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  // CONFIGURATION: Set your server IP here for physical devices
  // For Android Emulator: use '10.0.2.2'
  // For Web/iOS Simulator: use 'localhost'
  // For Physical Device: use your computer's LAN IP (e.g., '192.168.1.5')
  
  // Live backend (Railway)
  static const String baseUrl = 'https://ballchart-production.up.railway.app/api';
  
  final _storage = const FlutterSecureStorage();

  Future<Map<String, String>> _getHeaders() async {
    String? token = await _storage.read(key: 'jwt_token');
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
    ).timeout(const Duration(seconds: 15));
    return _processResponse(response);
  }

  Future<dynamic> get(String endpoint) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
    ).timeout(const Duration(seconds: 15));
    return _processResponse(response);
  }

  Future<dynamic> put(String endpoint, Map<String, dynamic> body) async {
    final headers = await _getHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 10));
    return _processResponse(response);
  }

  Future<dynamic> delete(String endpoint) async {
    final headers = await _getHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
    ).timeout(const Duration(seconds: 10));
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
      final body = response.body;

      // Try JSON error first
      try {
        final decoded = jsonDecode(body);
        throw Exception(decoded['message'] ?? 'Something went wrong');
      } on FormatException {
        // Non-JSON response (e.g. HTML error pages)
        if (body.contains('<html')) {
          final preMatch = RegExp(r'<pre>(.*?)</pre>').firstMatch(body);
          final titleMatch = RegExp(r'<title>(.*?)</title>').firstMatch(body);
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

  Future<String?> getToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  Future<void> clearToken() async {
    await _storage.delete(key: 'jwt_token');
  }
}
