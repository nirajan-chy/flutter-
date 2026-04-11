import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../network/api_client.dart';

class AuthService {
  final Dio _dio = ApiClient.instance;

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    final response = await _dio.post(
      '/auth/register',
      data: {
        'name': name,
        'email': email,
        'password': password,
        'phone': phone,
      },
    );

    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post(
      '/auth/login',
      data: {'email': email, 'password': password},
    );

    final payload = Map<String, dynamic>.from(response.data as Map);
    final token = payload['token']?.toString();
    final user = payload['data'] is Map
        ? Map<String, dynamic>.from(payload['data'] as Map)
        : <String, dynamic>{};

    if (token != null && token.isNotEmpty) {
      await ApiClient.setAuthToken(token);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('name', user['name']?.toString() ?? '');
    await prefs.setString('userEmail', user['email']?.toString() ?? '');
    await prefs.setString('userId', user['id']?.toString() ?? '');

    return payload;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('name');
    await prefs.remove('userEmail');
    await prefs.remove('userId');
    await ApiClient.clearAuthToken();
  }
}
