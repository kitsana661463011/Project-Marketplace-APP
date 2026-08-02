import '../config/api_config.dart';
import '../models/shop_category.dart';
import 'api_service.dart';

class CategoryService {
  static Future<List<ShopCategory>> getShopCategories() async {
    final response = await ApiService.get(ApiConfig.categories);
    if (response['status'] == true && response['data'] is List) {
      return (response['data'] as List)
          .map((json) => ShopCategory.fromJson(json))
          .toList();
    }
    return [];
  }
}
