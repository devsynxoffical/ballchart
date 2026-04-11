import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';

class StaffService {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> createStaff({
    required String name,
    required String email,
    required String password,
    required String role,
    Map<String, bool>? permissions,
    String? teamId,
  }) async {
    try {
      final response = await _apiService.post('/auth/staff/create', {
        'username': name,
        'email': email,
        'password': password,
        'role': role,
        if (permissions != null) 'permissions': permissions,
        if (teamId != null) 'teamId': teamId,
      });
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<String?> uploadImage(File imageFile) async {
    try {
      final response = await _apiService.uploadFile('/upload/image', imageFile);
      return response['url'] as String?;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  Future<Map<String, dynamic>> createPlayer({
    required String name,
    required String email,
    required String password,
    String? teamId,
    String? number,
    String? position,
    String? ageRange,
    String? height,
    String? weight,
    String? profileImageUrl,
  }) async {
    try {
      final response = await _apiService.post('/auth/player/create', {
        'username': name,
        'email': email,
        'password': password,
        if (teamId != null && teamId.isNotEmpty) 'teamId': teamId,
        'number': number,
        'position': position,
        if (ageRange != null && ageRange.isNotEmpty) 'ageRange': ageRange,
        'height': height,
        'weight': weight,
        if (profileImageUrl != null) 'profileImageUrl': profileImageUrl,
      });
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<dynamic>> getStaffCredentials() async {
    try {
      final response = await _apiService.get('/auth/staff/credentials');
      return response as List<dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updatePlayer({
    required String playerId,
    String? name,
    String? email,
    String? password,
    String? position,
    String? ageRange,
  }) async {
    try {
      final payload = <String, dynamic>{};
      if (name != null) payload['username'] = name;
      if (email != null) payload['email'] = email;
      if (password != null && password.isNotEmpty) payload['password'] = password;
      if (position != null) payload['position'] = position;
      if (ageRange != null) payload['ageRange'] = ageRange;
      final response = await _apiService.put('/auth/player/$playerId', payload);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deletePlayer(String playerId) async {
    try {
      await _apiService.delete('/auth/player/$playerId');
    } catch (e) {
      rethrow;
    }
  }
}
