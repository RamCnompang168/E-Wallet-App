import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class ApiException implements Exception {
  final String message;
  final int statusCode;
  final Map<String, dynamic>? errors;

  ApiException(this.message, {this.statusCode = 400, this.errors});

  @override
  String toString() {
    if (errors != null && errors!.isNotEmpty) {
      final details = errors!.entries
          .map((e) => '${e.key}: ${e.value is List ? (e.value as List).join(", ") : e.value}')
          .join('\n');
      return '$message\n$details';
    }
    return message;
  }
}

class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final int statusCode;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
    required this.statusCode,
  });
}

class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  static const String _prefAccessToken = 'novapay_access_token';
  static const String _prefRefreshToken = 'novapay_refresh_token';
  static const String _prefUserJson = 'novapay_user_profile';

  static String _resolveDefaultBaseUrl() {
    if (kIsWeb) return 'http://127.0.0.1:8000/api/v1';
    try {
      if (Platform.isAndroid) return 'http://10.0.2.2:8000/api/v1';
    } catch (_) {}
    return 'http://127.0.0.1:8000/api/v1';
  }

  String baseUrl = _resolveDefaultBaseUrl();
  final http.Client _client = http.Client();
  final Uuid _uuid = const Uuid();

  String? _accessToken;
  String? _refreshToken;
  bool _initialized = false;
  bool _isRefreshing = false;

  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  bool get isAuthenticated => _accessToken != null && _accessToken!.isNotEmpty;

  Future<void> init() async {
    if (_initialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      _accessToken = prefs.getString(_prefAccessToken);
      _refreshToken = prefs.getString(_prefRefreshToken);
    } catch (_) {
      // In-memory fallback if storage isn't available
    }
    _initialized = true;
  }

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefAccessToken, accessToken);
      await prefs.setString(_prefRefreshToken, refreshToken);
    } catch (_) {}
  }

  Future<void> saveUserProfile(Map<String, dynamic> userMap) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefUserJson, jsonEncode(userMap));
    } catch (_) {}
  }

  Future<Map<String, dynamic>?> getSavedUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString(_prefUserJson);
      if (str != null) return jsonDecode(str) as Map<String, dynamic>;
    } catch (_) {}
    return null;
  }

  Future<void> clearAuth() async {
    _accessToken = null;
    _refreshToken = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefAccessToken);
      await prefs.remove(_prefRefreshToken);
      await prefs.remove(_prefUserJson);
    } catch (_) {}
  }

  Map<String, String> _buildHeaders({
    bool requiresAuth = true,
    bool idempotent = false,
    String? idempotencyKey,
    String? pin,
  }) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (requiresAuth && _accessToken != null) {
      headers['Authorization'] = 'Bearer $_accessToken';
    }
    if (idempotent) {
      headers['Idempotency-Key'] = idempotencyKey ?? _uuid.v4();
    }
    if (pin != null && pin.isNotEmpty) {
      headers['x-transaction-pin'] = pin;
    }
    return headers;
  }

  Uri _buildUri(String path, [Map<String, String>? queryParams]) {
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    final urlStr = '$baseUrl/$cleanPath';
    final uri = Uri.parse(urlStr);
    if (queryParams != null && queryParams.isNotEmpty) {
      return uri.replace(queryParameters: queryParams);
    }
    return uri;
  }

  Future<ApiResponse<dynamic>> get(
    String path, {
    Map<String, String>? queryParams,
    bool requiresAuth = true,
  }) async {
    return _sendWithRetry(() async {
      final uri = _buildUri(path, queryParams);
      final headers = _buildHeaders(requiresAuth: requiresAuth);
      final response = await _client.get(uri, headers: headers);
      return _parseResponse(response);
    }, requiresAuth: requiresAuth);
  }

  Future<ApiResponse<dynamic>> post(
    String path, {
    dynamic body,
    bool requiresAuth = true,
    bool idempotent = false,
    String? idempotencyKey,
    String? pin,
  }) async {
    return _sendWithRetry(() async {
      final uri = _buildUri(path);
      final headers = _buildHeaders(
        requiresAuth: requiresAuth,
        idempotent: idempotent,
        idempotencyKey: idempotencyKey,
        pin: pin,
      );
      final response = await _client.post(
        uri,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );
      return _parseResponse(response);
    }, requiresAuth: requiresAuth);
  }

  Future<ApiResponse<dynamic>> patch(
    String path, {
    dynamic body,
    bool requiresAuth = true,
  }) async {
    return _sendWithRetry(() async {
      final uri = _buildUri(path);
      final headers = _buildHeaders(requiresAuth: requiresAuth);
      final response = await _client.patch(
        uri,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );
      return _parseResponse(response);
    }, requiresAuth: requiresAuth);
  }

  Future<ApiResponse<dynamic>> delete(
    String path, {
    bool requiresAuth = true,
  }) async {
    return _sendWithRetry(() async {
      final uri = _buildUri(path);
      final headers = _buildHeaders(requiresAuth: requiresAuth);
      final response = await _client.delete(uri, headers: headers);
      return _parseResponse(response);
    }, requiresAuth: requiresAuth);
  }

  Future<ApiResponse<dynamic>> uploadFile(
    String path, {
    required String fileField,
    String? filePath,
    List<int>? fileBytes,
    String? fileName,
    Map<String, String>? fields,
    bool requiresAuth = true,
  }) async {
    return _sendWithRetry(() async {
      final uri = _buildUri(path);
      final request = http.MultipartRequest('POST', uri);
      if (requiresAuth && _accessToken != null) {
        request.headers['Authorization'] = 'Bearer $_accessToken';
      }
      if (fields != null) {
        request.fields.addAll(fields);
      }
      if (fileBytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            fileField,
            fileBytes,
            filename: fileName ?? 'photo.jpg',
          ),
        );
      } else if (filePath != null && filePath.isNotEmpty) {
        request.files.add(await http.MultipartFile.fromPath(fileField, filePath));
      }
      final streamedResponse = await _client.send(request);
      final response = await http.Response.fromStream(streamedResponse);
      return _parseResponse(response);
    }, requiresAuth: requiresAuth);
  }

  Future<ApiResponse<dynamic>> _sendWithRetry(
    Future<ApiResponse<dynamic>> Function() requestFn, {
    required bool requiresAuth,
  }) async {
    try {
      return await requestFn();
    } on ApiException catch (e) {
      if (e.statusCode == 401 && requiresAuth && _refreshToken != null && !_isRefreshing) {
        final refreshed = await _refreshAccessToken();
        if (refreshed) {
          return await requestFn();
        }
      }
      rethrow;
    }
  }

  Future<bool> _refreshAccessToken() async {
    if (_refreshToken == null || _isRefreshing) return false;
    _isRefreshing = true;
    try {
      final uri = _buildUri('auth/refresh/');
      final res = await _client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh_token': _refreshToken}),
      );
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final data = decoded['data'] ?? decoded;
        final newAccess = data['access_token'] ?? data['access'];
        final newRefresh = data['refresh_token'] ?? data['refresh'] ?? _refreshToken;
        if (newAccess != null) {
          await saveTokens(accessToken: newAccess, refreshToken: newRefresh);
          _isRefreshing = false;
          return true;
        }
      }
    } catch (_) {}
    _isRefreshing = false;
    return false;
  }

  ApiResponse<dynamic> _parseResponse(http.Response response) {
    dynamic decodedBody;
    try {
      decodedBody = jsonDecode(utf8.decode(response.bodyBytes));
    } catch (_) {
      decodedBody = null;
    }

    final isSuccess = response.statusCode >= 200 && response.statusCode < 300;

    if (decodedBody is Map<String, dynamic>) {
      final bool backendSuccess = decodedBody['success'] ?? isSuccess;
      final String message = decodedBody['message'] ?? (isSuccess ? 'Success' : 'Request failed');
      final dynamic data = decodedBody.containsKey('data') ? decodedBody['data'] : decodedBody;

      if (!isSuccess || !backendSuccess) {
        final errors = decodedBody['errors'] is Map<String, dynamic>
            ? decodedBody['errors'] as Map<String, dynamic>
            : null;
        throw ApiException(message, statusCode: response.statusCode, errors: errors);
      }

      return ApiResponse(
        success: true,
        message: message,
        data: data,
        statusCode: response.statusCode,
      );
    }

    if (!isSuccess) {
      throw ApiException(
        'Request failed with status: ${response.statusCode}',
        statusCode: response.statusCode,
      );
    }

    return ApiResponse(
      success: true,
      message: 'Success',
      data: decodedBody,
      statusCode: response.statusCode,
    );
  }
}
