import '../config/api_config.dart';
import '../models/shop.dart';
import 'api_service.dart';

class ShopService {
  static Future<List<Shop>> getShops({int? userId}) async {
    final endpoint = userId != null ? '${ApiConfig.shops}?user_id=$userId' : ApiConfig.shops;
    final response = await ApiService.get(endpoint);
    if (response['status'] == true && response['data'] != null) {
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
  }) async {
    try {
      final fields = {
        'shop_name': shopName,
        'category_id': categoryId.toString(),
        'description': description ?? '',
        'shop_phone': shopPhone ?? '',
        'user_id': userId.toString(),
      };

      if (fileName != null) {
        fields['shop_image'] = fileName;
      }

      final response = await ApiService.postMultipart(
        '/v1/shops',
        fields,
      );

      if (response['status'] == true && response['data'] != null) {
        return Map<String, dynamic>.from(response['data']);
      }
    } catch (e) {
      // Catch exceptions
    }
    return null;
  }
}
