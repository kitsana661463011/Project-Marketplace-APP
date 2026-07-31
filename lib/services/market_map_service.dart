import '../models/market_map_item.dart';
import 'api_service.dart';

class MarketMapService {
  static Future<MarketMap?> getMap(int mapId) async {
    try {
      final response = await ApiService.get('/v1/maps/$mapId');
      if (response['status'] == true && response['data'] != null) {
        return MarketMap.fromJson(Map<String, dynamic>.from(response['data']));
      }
    } catch (e) {
      // ignore
    }
    return null;
  }

  static Future<MarketMap?> getMainMap() async {
    return getMap(1);
  }
}
