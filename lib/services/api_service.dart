import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class ApiService {
  static String get baseUrl {
    if (kIsWeb) {
      return ApiConfig.webBaseUrl;
    }
    return ApiConfig.baseUrl;
  }

  static String get imageUrl {
    if (kIsWeb) {
      return ApiConfig.webImageBaseUrl;
    }
    return ApiConfig.imageBaseUrl;
  }

  static String getImagePath(String? filename) {
    if (filename == null || filename.isEmpty) return '';
    if (filename.startsWith('http://') ||
        filename.startsWith('https://') ||
        filename.startsWith('data:')) {
      return filename;
    }
    final clean = filename
        .replaceFirst(RegExp(r'^/?storage/images/'), '')
        .replaceFirst(RegExp(r'^/?storage/'), '')
        .replaceFirst(RegExp(r'^/?api/images/'), '');
    return '$imageUrl/$clean';
  }

  static Future<Map<String, dynamic>> get(String endpoint) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl$endpoint'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 8));
      // Debug logging to help diagnose empty responses from API
      try {
        debugPrint('ApiService GET: $baseUrl$endpoint');
        debugPrint('ApiService Response status: ${response.statusCode}');
        debugPrint('ApiService Response body: ${response.body}');
      } catch (_) {}
      return _handleResponse(response);
    } catch (e) {
      return {'status': false, 'message': 'Connection error: $e', 'data': null};
    }
  }

  static Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl$endpoint'),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 8));
      return _handleResponse(response);
    } catch (e) {
      return {'status': false, 'message': 'Connection error: $e', 'data': null};
    }
  }

  static Future<Map<String, dynamic>> put(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await http
          .put(
            Uri.parse('$baseUrl$endpoint'),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 8));
      return _handleResponse(response);
    } catch (e) {
      return {'status': false, 'message': 'Connection error: $e', 'data': null};
    }
  }

  static Future<Map<String, dynamic>> delete(String endpoint) async {
    try {
      final response = await http
          .delete(
            Uri.parse('$baseUrl$endpoint'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 8));
      return _handleResponse(response);
    } catch (e) {
      return {'status': false, 'message': 'Connection error: $e', 'data': null};
    }
  }

  static Future<Map<String, dynamic>> postMultipart(
    String endpoint,
    Map<String, String> fields, {
    String? fileKey,
    String? filePath,
    List<int>? fileBytes,
    String? fileName,
    List<Map<String, dynamic>>? extraFiles,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl$endpoint'),
      );
      request.headers.addAll({'Accept': 'application/json'});
      request.fields.addAll(fields);

      if (fileKey != null) {
        if (filePath != null && filePath.isNotEmpty) {
          request.files.add(
            await http.MultipartFile.fromPath(fileKey, filePath),
          );
        } else if (fileBytes != null && fileBytes.isNotEmpty) {
          request.files.add(
            http.MultipartFile.fromBytes(
              fileKey,
              fileBytes,
              filename: fileName ?? 'upload.png',
            ),
          );
        }
      }

      if (extraFiles != null) {
        for (final extraFile in extraFiles) {
          final key = extraFile['key'] as String? ?? 'images';
          final extraBytes = extraFile['bytes'] as List<int>?;
          final extraName = extraFile['fileName'] as String? ?? 'upload.png';

          if (extraBytes != null && extraBytes.isNotEmpty) {
            request.files.add(
              http.MultipartFile.fromBytes(
                key,
                extraBytes,
                filename: extraName,
              ),
            );
          }
        }
      }

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 15),
      );
      final response = await http.Response.fromStream(streamedResponse);
      return _handleResponse(response);
    } catch (e) {
      return {'status': false, 'message': 'Connection error: $e', 'data': null};
    }
  }

  static Map<String, dynamic> _handleResponse(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      return body;
    } catch (e) {
      return {
        'status': false,
        'message': 'Failed to parse response',
        'data': null,
      };
    }
  }
}
