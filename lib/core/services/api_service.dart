import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class ApiService {
  // CONFIGURATION: Set your server IP here for physical devices
  // For Android Emulator: use '10.0.2.2'
  // For Web/iOS Simulator: use 'localhost'
  // For Physical Device: use your computer's LAN IP (e.g., '192.168.1.5')
  
  // Live backend (Railway) - Production ready
  static const String baseUrl = 'https://ballchart-production.up.railway.app/api';
  static const String socketUrl = 'https://ballchart-production.up.railway.app';

  /// Origin without `/api` — for `/uploads/...` paths returned by the API.
  static String get originUrl => baseUrl.replaceFirst(RegExp(r'/api/?$'), '');

  /// Build a loadable image URL for team logos and media paths from the server.
  static String resolveMediaUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    final t = path.trim();
    if (t.startsWith('data:') || t.startsWith('http://') || t.startsWith('https://')) return t;
    if (t.startsWith('/')) return '$originUrl$t';
    return '$originUrl/$t';
  }
  
  // Local backend for development - comment out for production
  // static const String baseUrl = 'http://localhost:5000/api';
  // static const String socketUrl = 'http://localhost:5000';
  
  final _storage = const FlutterSecureStorage();
  IO.Socket? socket;

  Future<Map<String, String>> _getHeaders() async {
    String? token = await _storage.read(key: 'jwt_token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .post(
            Uri.parse('$baseUrl$endpoint'),
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));
      return _processResponse(response);
    } on TimeoutException {
      throw Exception('Request timeout. Please check internet/server and try again.');
    }
  }

  Future<dynamic> get(String endpoint, {Duration timeout = const Duration(seconds: 60)}) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(
            Uri.parse('$baseUrl$endpoint'),
            headers: headers,
          )
          .timeout(timeout);
      return _processResponse(response);
    } on TimeoutException {
      throw Exception('Request timeout. Please check internet/server and try again.');
    }
  }

  /// Raw bytes (e.g. PDF). Does not JSON-decode the body.
  Future<Uint8List> getBytes(String endpoint) async {
    final headers = await _getHeaders();
    final response = await http
        .get(
          Uri.parse('$baseUrl$endpoint'),
          headers: headers,
        )
        .timeout(const Duration(seconds: 60));
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response.bodyBytes;
    }
    try {
      final decoded = jsonDecode(response.body);
      throw Exception(decoded['message'] ?? 'Download failed');
    } on FormatException {
      throw Exception('SERVER_ERROR_${response.statusCode}');
    }
  }

  Future<dynamic> patch(String endpoint, Map<String, dynamic> body) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .patch(
            Uri.parse('$baseUrl$endpoint'),
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));
      return _processResponse(response);
    } on TimeoutException {
      throw Exception('Request timeout. Please check internet/server and try again.');
    }
  }

  Future<dynamic> put(String endpoint, Map<String, dynamic> body) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .put(
            Uri.parse('$baseUrl$endpoint'),
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));
      return _processResponse(response);
    } on TimeoutException {
      throw Exception('Request timeout. Please check internet/server and try again.');
    }
  }

  Future<dynamic> delete(String endpoint) async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .delete(
            Uri.parse('$baseUrl$endpoint'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 30));
      return _processResponse(response);
    } on TimeoutException {
      throw Exception('Request timeout. Please check internet/server and try again.');
    }
  }

  dynamic _processResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return {};
      try {
        return jsonDecode(response.body);
      } catch (_) {
        throw Exception('SERVER_ERROR_PARSE');
      }
    } else {
      final body = response.body;

      // Try JSON error first
      try {
        final decoded = jsonDecode(body);
        throw Exception(decoded['message'] ?? 'Something went wrong');
      } on FormatException {
        // Non-JSON response (e.g. HTML error pages) — never surface raw HTML/URLs to UI.
        if (body.contains('<html')) {
          throw Exception('SERVER_ERROR_${response.statusCode}');
        }
        throw Exception('SERVER_ERROR_${response.statusCode}');
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
    disconnectSocket();
  }

  void connectSocket() async {
    String? token = await getToken();
    if (token == null) return;

    if (socket?.connected == true) return;

    socket = IO.io(socketUrl, IO.OptionBuilder()
      .setTransports(['websocket'])
      .setAuth({'token': token})
      .disableAutoConnect()
      .build());

    socket!.connect();

    socket!.onConnect((_) {
      print('Socket connected: ${socket!.id}');
    });

    socket!.onConnectError((error) {
      print('Socket connection error: $error');
    });

    socket!.onDisconnect((_) {
      print('Socket disconnected');
    });
  }

  void disconnectSocket() {
    socket?.disconnect();
    socket = null;
  }

  /// Gallery picks without this often send `application/octet-stream`, which many servers reject.
  static MediaType _imageMediaTypeForPath(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return MediaType('image', 'png');
    if (lower.endsWith('.gif')) return MediaType('image', 'gif');
    if (lower.endsWith('.webp')) return MediaType('image', 'webp');
    if (lower.endsWith('.heic') || lower.endsWith('.heif')) {
      return MediaType('image', 'heic');
    }
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      return MediaType('image', 'jpeg');
    }
    return MediaType('image', 'jpeg');
  }

  static MediaType _audioMediaTypeForPath(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.mp3')) return MediaType('audio', 'mpeg');
    if (lower.endsWith('.wav')) return MediaType('audio', 'wav');
    if (lower.endsWith('.ogg')) return MediaType('audio', 'ogg');
    if (lower.endsWith('.webm')) return MediaType('audio', 'webm');
    if (lower.endsWith('.caf')) return MediaType('audio', 'x-caf');
    return MediaType('audio', 'mp4');
  }

  Future<Map<String, dynamic>> uploadAudio(File file) async {
    return uploadFile('/upload/audio', file, fieldName: 'audio');
  }

  Future<Map<String, dynamic>> uploadFile(
    String endpoint,
    File file, {
    String fieldName = 'image',
  }) async {
    try {
      String? token = await _storage.read(key: 'jwt_token');
      
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl$endpoint'),
      );
      
      // Add headers
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      
      var rawName = file.path.replaceAll(r'\', '/').split('/').last;
      if (!rawName.contains('.')) {
        rawName = 'upload.jpg';
      }
      final contentType = fieldName == 'audio'
          ? _audioMediaTypeForPath(rawName)
          : _imageMediaTypeForPath(rawName);

      var fileStream = file.openRead();
      var length = await file.length();
      var multipartFile = http.MultipartFile(
        fieldName,
        fileStream,
        length,
        filename: rawName,
        contentType: contentType,
      );
      request.files.add(multipartFile);
      
      var response = await request.send().timeout(const Duration(seconds: 30));
      var responseBody = await response.stream.bytesToString();
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(responseBody);
      } else {
        throw Exception('Upload failed: ${response.statusCode} - $responseBody');
      }
    } on TimeoutException {
      throw Exception('Upload timeout. Please check internet/server and try again.');
    } catch (e) {
      throw Exception('Upload error: $e');
    }
  }

  Future<Map<String, dynamic>> parseVoiceCommand(String command) async {
    final response = await post('/tactical/parse-command', {'command': command});
    if (response is Map) {
      return Map<String, dynamic>.from(response);
    }
    throw Exception('Invalid response format from parser');
  }
}
