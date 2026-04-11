import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  ApiClient._();

  static Dio? _dio;

  static String get _baseUrl {
    if (kIsWeb) {
      return 'http://localhost:5000';
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:5000';
    }

    return 'http://localhost:5000';
  }

  static Dio get instance {
    _dio ??= Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    return _dio!;
  }

  static Future<void> setAuthToken(String token) async {
    instance.options.headers['Authorization'] = 'Bearer $token';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  static Future<void> clearAuthToken() async {
    instance.options.headers.remove('Authorization');
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  static Future<void> hydrateTokenFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token != null && token.isNotEmpty) {
      instance.options.headers['Authorization'] = 'Bearer $token';
    }
  }
}
