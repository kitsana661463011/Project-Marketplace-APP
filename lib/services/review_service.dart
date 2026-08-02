import '../config/api_config.dart';
import 'api_service.dart';

class ReviewService {
  static Future<List<Map<String, dynamic>>> getReviewsByShop(int shopId) async {
    try {
      final response = await ApiService.get(
        '${ApiConfig.shopReviews}?shop_id=$shopId',
      );
      if (response['status'] == true && response['data'] is List) {
        return (response['data'] as List)
            .whereType<Map<String, dynamic>>()
            .toList();
      }
    } catch (e) {
      // Silently catch and return empty list on failure
    }
    return [];
  }

  static Future<Map<String, dynamic>?> createReview({
    required int userId,
    required int shopId,
    required int rating,
    required String comment,
    List<Map<String, dynamic>>? reviewImages,
  }) async {
    try {
      final response = reviewImages != null && reviewImages.isNotEmpty
          ? await ApiService.postMultipart(ApiConfig.shopReviews, {
              'user_id': userId.toString(),
              'shop_id': shopId.toString(),
              'rating': rating.toString(),
              'comment': comment,
            }, extraFiles: reviewImages)
          : await ApiService.post(ApiConfig.shopReviews, {
              'user_id': userId,
              'shop_id': shopId,
              'rating': rating,
              'comment': comment,
            });

      if (response['status'] == true && response['data'] != null) {
        return Map<String, dynamic>.from(response['data']);
      }
    } catch (e) {
      // Silently catch and return null on failure
    }
    return null;
  }

  static Future<Map<String, dynamic>?> createReviewReport({
    required int reviewId,
    required int userId,
    required String reportReason,
  }) async {
    try {
      final response = await ApiService.post(ApiConfig.reviewReports, {
        'review_id': reviewId,
        'user_id': userId,
        'report_reason': reportReason,
      });
      if (response['status'] == true && response['data'] != null) {
        return Map<String, dynamic>.from(response['data']);
      }
    } catch (e) {
      // Silently catch and return null on failure
    }
    return null;
  }
}
