import '../config/api_config.dart';
import '../models/item.dart';
import 'api_service.dart';

class ItemService {
  static Future<List<Item>> getItems() async {
    final response = await ApiService.get(ApiConfig.items);
    if (response['status'] == true && response['data'] != null) {
      return (response['data'] as List)
          .map((json) => Item.fromJson(json))
          .toList();
    }
    return [];
  }

  static Future<Item?> getItem(int id) async {
    final response = await ApiService.get('${ApiConfig.items}/$id');
    if (response['status'] == true && response['data'] != null) {
      return Item.fromJson(response['data']);
    }
    return null;
  }

  static Future<List<Item>> getItemsByShop(int shopId) async {
    final allItems = await getItems();
    return allItems.where((item) => item.shopId == shopId).toList();
  }
}
