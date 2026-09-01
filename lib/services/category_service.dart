import '../config/api_config.dart';
import '../models/shop_category.dart';
import '../models/item_category.dart';
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

  static Future<List<ItemCategory>> getItemCategories({int? shopId}) async {
    try {
      final url = shopId != null
          ? '${ApiConfig.itemCategories}?shop_id=$shopId'
          : ApiConfig.itemCategories;
      final response = await ApiService.get(url);
      if (response['status'] == true && response['data'] is List) {
        return (response['data'] as List)
            .map((json) => ItemCategory.fromJson(json))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<Map<String, dynamic>> createItemCategory({
    required String categoryName,
    int? shopId,
    List<int>? itemIds,
  }) async {
    final body = <String, dynamic>{
      'category_name': categoryName,
    };
    if (shopId != null) {
      body['shop_id'] = shopId;
    }
    if (itemIds != null && itemIds.isNotEmpty) {
      body['item_ids'] = itemIds;
    }

    return await ApiService.post(ApiConfig.itemCategories, body);
  }

  static Future<Map<String, dynamic>> updateItemCategory(
    int categoryId,
    String newCategoryName, {
    int? shopId,
  }) async {
    try {
      final body = <String, dynamic>{
        'category_name': newCategoryName,
      };
      if (shopId != null) {
        body['shop_id'] = shopId;
      }
      return await ApiService.put(
        '${ApiConfig.itemCategories}/$categoryId',
        body,
      );
    } catch (e) {
      return {'status': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> assignItemsToCategory(
    int categoryId,
    List<int> itemIds, {
    int? shopId,
  }) async {
    try {
      final body = <String, dynamic>{
        'item_ids': itemIds,
      };
      if (shopId != null) {
        body['shop_id'] = shopId;
      }
      return await ApiService.post(
        '${ApiConfig.itemCategories}/$categoryId/assign-items',
        body,
      );
    } catch (e) {
      return {'status': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> removeItemsFromCategory(
    int categoryId,
    List<int> itemIds, {
    int? shopId,
  }) async {
    try {
      final body = <String, dynamic>{
        'item_ids': itemIds,
      };
      if (shopId != null) {
        body['shop_id'] = shopId;
      }
      return await ApiService.post(
        '${ApiConfig.itemCategories}/$categoryId/remove-items',
        body,
      );
    } catch (e) {
      return {'status': false, 'message': e.toString()};
    }
  }

  static Future<bool> deleteItemCategory(int categoryId, {int? shopId}) async {
    try {
      final url = shopId != null
          ? '${ApiConfig.itemCategories}/$categoryId?shop_id=$shopId'
          : '${ApiConfig.itemCategories}/$categoryId';
      final response = await ApiService.delete(url);
      return response['status'] == true;
    } catch (_) {
      return false;
    }
  }
}
