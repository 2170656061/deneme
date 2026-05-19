import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kIsWeb;

class ApiService {
  static const String _configuredBaseUrl = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    if (_configuredBaseUrl.isNotEmpty) {
      return _configuredBaseUrl;
    }

    if (kIsWeb) return 'http://127.0.0.1:8000';

    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000';
    }

    return 'http://127.0.0.1:8000';
  }

  static Map<String, String> _getHeaders({String? token}) {
    final headers = {'Content-Type': 'application/json'};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // ============ COURSES ============
  static Future<List<Map<String, dynamic>>> getCourses() async {
    final response = await http
        .get(Uri.parse('$baseUrl/courses'))
        .timeout(const Duration(seconds: 10));
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    }
    throw Exception('Failed to load courses (${response.statusCode})');
  }

  static Future<Map<String, dynamic>> getCourse(int courseId) async {
    final response = await http
        .get(Uri.parse('$baseUrl/courses/$courseId'))
        .timeout(const Duration(seconds: 10));
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to load course (${response.statusCode})');
  }

  static Future<Map<String, dynamic>> createCourse(
    String name, {
    String? description,
    double? distanceKm,
    String? token,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/courses'),
          headers: _getHeaders(token: token),
          body: jsonEncode({
            'name': name,
            'description': description,
            'distance_km': distanceKm,
          }),
        )
        .timeout(const Duration(seconds: 10));
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to create course (${response.statusCode})');
  }

  static Future<void> deleteCourse(int courseId, {String? token}) async {
    final response = await http
        .delete(
          Uri.parse('$baseUrl/courses/$courseId'),
          headers: _getHeaders(token: token),
        )
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw Exception('Failed to delete course (${response.statusCode})');
    }
  }

  // ============ CHECKPOINTS ============
  static Future<List<Map<String, dynamic>>> getCheckpoints(
      int courseId) async {
    final response = await http
        .get(Uri.parse('$baseUrl/courses/$courseId/checkpoints'))
        .timeout(const Duration(seconds: 10));
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    }
    throw Exception('Failed to load checkpoints (${response.statusCode})');
  }

  static Future<Map<String, dynamic>> createCheckpoint(
    int courseId,
    int order,
    double latitude,
    double longitude,
    {String? token}
  ) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/checkpoints'),
          headers: _getHeaders(token: token),
          body: jsonEncode({
            'order': order,
            'latitude': latitude,
            'longitude': longitude,
            'course_id': courseId,
          }),
        )
        .timeout(const Duration(seconds: 10));
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to create checkpoint (${response.statusCode})');
  }

  // ============ USERS (requires admin token) ============
  static Future<List<Map<String, dynamic>>> getUsers({String? token}) async {
    final response = await http
        .get(
          Uri.parse('$baseUrl/users'),
          headers: _getHeaders(token: token),
        )
        .timeout(const Duration(seconds: 10));
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    }
    throw Exception('Failed to load users (${response.statusCode})');
  }

  static Future<Map<String, dynamic>> createUser(
    String username,
    String email,
    String password,
    String role, {
    String? token,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/users'),
          headers: _getHeaders(token: token),
          body: jsonEncode({
            'username': username,
            'email': email,
            'password': password,
            'role': role,
          }),
        )
        .timeout(const Duration(seconds: 10));
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to create user (${response.statusCode})');
  }

  // ============ RESULTS ============
  static Future<List<Map<String, dynamic>>> getResults() async {
    final response = await http
        .get(Uri.parse('$baseUrl/results'))
        .timeout(const Duration(seconds: 10));
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    }
    throw Exception('Failed to load results (${response.statusCode})');
  }

  static Future<Map<String, dynamic>> syncResult(
    int userId,
    int courseId,
    double totalTimeSeconds,
    {String? token}
  ) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/sync-result'),
          headers: _getHeaders(token: token),
          body: jsonEncode({
            'user_id': userId,
            'course_id': courseId,
            'total_time_seconds': totalTimeSeconds,
          }),
        )
        .timeout(const Duration(seconds: 10));
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to sync result (${response.statusCode})');
  }

  // ============ AUTH ============
  static Future<Map<String, dynamic>> login(
      String username, String password) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/auth/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'username': username,
            'password': password,
          }),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) return jsonDecode(response.body);

    // Try to extract the detail message from the JSON error body
    try {
      final body = jsonDecode(response.body);
      final detail = body['detail'] ?? 'Giriş başarısız';
      throw Exception(detail);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Login failed (${response.statusCode})');
    }
  }

  static Future<Map<String, dynamic>> register(
    String username,
    String email,
    String password,
    String role,  // kept for API compatibility but backend ignores it
  ) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/auth/register'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'username': username,
            'email': email,
            'password': password,
            // role intentionally omitted — backend always sets admin
          }),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) return jsonDecode(response.body);

    try {
      final body = jsonDecode(response.body);
      final detail = body['detail'] ?? 'Kayıt başarısız';
      throw Exception(detail);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Registration failed (${response.statusCode})');
    }
  }

  static Future<Map<String, dynamic>> getMe(String token) async {
    final response = await http
        .get(
          Uri.parse('$baseUrl/auth/me'),
          headers: _getHeaders(token: token),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to get user info (${response.statusCode})');
  }

  // ============ KML UPLOAD ============
  static Future<Map<String, dynamic>> uploadKML(String filePath, {String? token}) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/upload-kml'),
    )..files.add(await http.MultipartFile.fromPath('file', filePath));

    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    final streamed =
        await request.send().timeout(const Duration(seconds: 30));
    final responseData = await streamed.stream.bytesToString();

    if (streamed.statusCode == 200) return jsonDecode(responseData);
    throw Exception('Failed to upload KML: $responseData');
  }

  static Future<Map<String, dynamic>> uploadKMLFromBytes(
      String fileName, Uint8List fileBytes, {String? token}) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/upload-kml'),
    )..files.add(http.MultipartFile.fromBytes('file', fileBytes,
        filename: fileName));

    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    final streamed =
        await request.send().timeout(const Duration(seconds: 30));
    final responseData = await streamed.stream.bytesToString();

    if (streamed.statusCode == 200) return jsonDecode(responseData);
    throw Exception('Failed to upload KML: $responseData');
  }
}
