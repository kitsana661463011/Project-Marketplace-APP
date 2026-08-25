import '../config/api_config.dart';
import '../models/shop.dart';
import 'api_service.dart';

class ShopService {
  static Future<List<Shop>> getShops({int? userId}) async {
    final endpoint = userId != null
        ? '${ApiConfig.shops}?user_id=$userId'
        : ApiConfig.shops;
    final response = await ApiService.get(endpoint);
    if (response['status'] == true && response['data'] is List) {
      return (response['data'] as List)
          .map((json) => Shop.fromJson(json))
          .toList();
    }
    return [];
  }

  static Future<Shop?> getShop(int id) async {
    final response = await ApiService.get('${ApiConfig.shops}/$id');
    if (response['status'] == true && response['data'] != null) {
      return Shop.fromJson(response['data']);
    }
    return null;
  }

  static Future<Map<String, dynamic>?> createShop({
    required String shopName,
    required int categoryId,
    String? description,
    String? shopPhone,
    required int userId,
    String? fileName,
    dynamic fileBytes,
    List<String>? tags,
  }) async {
    try {
      final fields = {
        'shop_name': shopName,
        'category_id': categoryId.toString(),
        'description': description ?? '',
        'shop_phone': shopPhone ?? '',
        'user_id': userId.toString(),
      };

      if (tags != null && tags.isNotEmpty) {
        fields['tags'] = tags.join(',');
      }

      if (fileName != null) {
        fields['shop_image'] = fileName;
      }

      final response = await ApiService.postMultipart(
        '/v1/shops',
        fields,
        fileKey: fileBytes != null ? 'shop_image' : null,
        fileBytes: fileBytes,
        fileName: fileName ?? 'shop.png',
      );

      if (response['status'] == true && response['data'] != null) {
        return Map<String, dynamic>.from(response['data']);
      }
    } catch (e) {
      // Catch exceptions
    }
    return null;
  }

  static Future<Shop?> updateShop({
    required int shopId,
    required String shopName,
    int? categoryId,
    String? description,
    String? shopPhone,
    String? status,
    String? fileName,
    dynamic fileBytes,
    List<String>? tags,
  }) async {
    try {
      final fields = {
        'shop_name': shopName,
        'description': description ?? '',
        'shop_phone': shopPhone ?? '',
      };

      if (tags != null) {
        fields['tags'] = tags.join(',');
      }

      if (categoryId != null) {
        fields['category_id'] = categoryId.toString();
      }

      if (status != null) {
        fields['status'] = status;
      }

      if (fileName != null) {
        fields['shop_image'] = fileName;
      }

      final response = await ApiService.postMultipart(
        '/v1/shops/$shopId?_method=PUT',
        fields,
        fileKey: fileBytes != null ? 'shop_image_file' : null,
        fileBytes: fileBytes,
        fileName: fileName ?? 'shop.png',
      );

      if (response['status'] == true && response['data'] != null) {
        return Shop.fromJson(response['data']);
      }
    } catch (e) {
      // Catch exceptions
    }
    return null;
  }

  static Future<Shop?> updateShopStatus(int shopId, String status) async {
    try {
      final response = await ApiService.put('/v1/shops/$shopId', {
        'status': status,
      });
      if (response['status'] == true && response['data'] != null) {
        return Shop.fromJson(response['data']);
      }
    } catch (_) {}

    // Fallback: try multipart PUT endpoint if PUT JSON is not supported
    try {
      final response = await ApiService.postMultipart(
        '/v1/shops/$shopId?_method=PUT',
        {'status': status},
      );
      if (response['status'] == true && response['data'] != null) {
        return Shop.fromJson(response['data']);
      }
    } catch (_) {}

    return null;
  }

  static Future<List<Shop>> getFollowedShops(int userId) async {
    try {
      final response = await ApiService.get(
        '/v1/followed-shops?user_id=$userId',
      );
      if (response['status'] == true && response['data'] is List) {
        return (response['data'] as List)
            .map((json) => Shop.fromJson(json))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<Map<String, dynamic>> toggleFollowShop({
    required int userId,
    required int shopId,
  }) async {
    try {
      final response = await ApiService.post('/v1/followed-shops/toggle', {
        'user_id': userId,
        'shop_id': shopId,
      });
      return response;
    } catch (e) {
      return {'status': false, 'message': e.toString()};
    }
  }

  static Future<bool> isShopFollowed({
    required int userId,
    required int shopId,
  }) async {
    try {
      final response = await ApiService.get(
        '/v1/followed-shops/check?user_id=$userId&shop_id=$shopId',
      );
      return response['is_following'] == true;
    } catch (_) {
      return false;
    }
  }
}
