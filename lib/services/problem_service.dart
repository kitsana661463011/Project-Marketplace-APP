import 'package:flutter/foundation.dart';
import 'api_service.dart';

class ProblemService {
  static Future<Map<String, dynamic>?> submitProblemReport({
    required int userId,
    required String location,
    required String description,
    required String category,
    int? stallId,
    String? filePath,
    Uint8List? fileBytes,
    String? fileName,
  }) async {
    try {
      final fields = {
        'user_id': userId.toString(),
        'location': location,
        'description': description,
        'category': category,
      };

      if (stallId != null) {
        fields['stall_id'] = stallId.toString();
      }

      if (fileName != null && filePath == null && fileBytes == null) {
        fields['image'] = fileName;
      }

      final response = await ApiService.postMultipart(
        '/v1/problem-reports',
        fields,
        fileKey: 'image',
        filePath: filePath,
        fileBytes: fileBytes,
        fileName: fileName,
      );

      if (response['status'] == true && response['data'] != null) {
        return Map<String, dynamic>.from(response['data']);
      }
    } catch (e) {
      debugPrint('ProblemService.submitProblemReport error: $e');
    }
    return null;
  }

  static Future<List<Map<String, dynamic>>> getUserProblemReports(int userId) async {
    try {
      final response = await ApiService.get('/v1/problem-reports?user_id=$userId');
      if (response['status'] == true && response['data'] != null) {
        return List<Map<String, dynamic>>.from(response['data']);
      }
    } catch (e) {
      debugPrint('ProblemService.getUserProblemReports error: $e');
    }
    return [];
  }
}
