import '../config/api_config.dart';
import '../models/stall.dart';
import 'api_service.dart';

class StallService {
  static Future<List<Stall>> getStalls() async {
    final response = await ApiService.get(ApiConfig.stalls);
    if (response['status'] == true && response['data'] != null) {
      return (response['data'] as List)
          .map((json) => Stall.fromJson(json))
          .toList();
    }
    return [];
  }

  static Future<Stall?> getStall(int id) async {
    final response = await ApiService.get('${ApiConfig.stalls}/$id');
    if (response['status'] == true && response['data'] != null) {
      return Stall.fromJson(response['data']);
    }
    return null;
  }

  static Future<List<Stall>> getAvailableStalls() async {
    final stalls = await getStalls();
    return stalls.where((s) => s.isAvailable).toList();
  }
}
