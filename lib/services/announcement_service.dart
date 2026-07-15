import '../config/api_config.dart';
import '../models/announcement.dart';
import 'api_service.dart';

class AnnouncementService {
  static Future<List<Announcement>> getAnnouncements() async {
    final response = await ApiService.get(ApiConfig.announcements);
    if (response['status'] == true && response['data'] != null) {
      return (response['data'] as List)
          .map((json) => Announcement.fromJson(json))
          .toList();
    }
    return [];
  }

  static Future<List<Announcement>> getActiveAnnouncements() async {
    final announcements = await getAnnouncements();
    return announcements.where((a) => a.status == 'active').toList();
  }
}
