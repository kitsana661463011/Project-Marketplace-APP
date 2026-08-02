import '../config/api_config.dart';
import '../models/item.dart';
import 'api_service.dart';

class ItemService {
  static Future<List<Item>> getItems() async {
    final response = await ApiService.get(ApiConfig.items);
    if (response['status'] == true && response['data'] is List) {
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

  static Future<Item?> updateItem(int id, Map<String, dynamic> body) async {
    try {
      final response = await ApiService.put('${ApiConfig.items}/$id', body);
      if (response['status'] == true && response['data'] != null) {
        return Item.fromJson(response['data']);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<bool> deleteItem(int id) async {
    try {
      final response = await ApiService.delete('${ApiConfig.items}/$id');
      return response['status'] == true;
    } catch (_) {
      return false;
    }
  }

  static Future<List<Item>> getItemsByShop(int shopId) async {
    try {
      final response = await ApiService.get(
        '${ApiConfig.items}?shop_id=$shopId',
      );
      if (response['status'] == true && response['data'] is List) {
        final items = (response['data'] as List)
            .map((json) => Item.fromJson(json))
            .toList();
        if (items.isNotEmpty) return items;
      }

      // Fallback: fetch all items and filter client-side if the filtered API
      // returned empty (some dev environments may not support query filtering).
      final all = await getItems();
      return all.where((i) => i.shopId == shopId).toList();
    } catch (_) {
      return [];
    }
  }
}
