import '../config/api_config.dart';
import 'api_service.dart';

class ReviewService {
  static Future<List<Map<String, dynamic>>> getReviewsByShop(
    int shopId, {
    int? userId,
  }) async {
    try {
      final userQuery = userId != null ? '&user_id=$userId' : '';
      final response = await ApiService.get(
        '${ApiConfig.shopReviews}?shop_id=$shopId$userQuery',
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

  static Future<Map<String, dynamic>?> toggleReviewReaction({
    required int reviewId,
    required int userId,
    required String reactionType,
  }) async {
    try {
      final response = await ApiService.post(ApiConfig.reviewReactions, {
        'review_id': reviewId,
        'user_id': userId,
        'reaction_type': reactionType,
      });
      if (response['status'] == true && response['data'] != null) {
        return Map<String, dynamic>.from(response['data']);
      }
    } catch (e) {
      // Silently catch and return null on failure
    }
    return null;
  }

  static Future<Map<String, dynamic>?> createReview({
    required int userId,
    required int shopId,
    required double rating,
    required String comment,
    List<Map<String, dynamic>>? reviewImages,
  }) async {
    try {
      final ratingValue = rating % 1 == 0 ? rating.toInt() : rating;
      final response = reviewImages != null && reviewImages.isNotEmpty
          ? await ApiService.postMultipart(ApiConfig.shopReviews, {
              'user_id': userId.toString(),
              'shop_id': shopId.toString(),
              'rating': ratingValue.toString(),
              'comment': comment,
            }, extraFiles: reviewImages)
          : await ApiService.post(ApiConfig.shopReviews, {
              'user_id': userId,
              'shop_id': shopId,
              'rating': ratingValue,
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
