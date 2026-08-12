import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/announcement.dart';
import '../models/user.dart';
import 'api_service.dart';

class AnnouncementService {
  static const String _readKey = 'read_announcements';

  static Future<String> _getUserRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataStr = prefs.getString('user_data');
      if (userDataStr != null) {
        final Map<String, dynamic> userMap = jsonDecode(userDataStr);
        final user = UserModel.fromJson(userMap);
        return user.role;
      }
    } catch (_) {}
    return 'buyer';
  }

  static Future<List<Announcement>> getAnnouncements() async {
    final response = await ApiService.get(ApiConfig.announcements);
    if (response['status'] == true && response['data'] is List) {
      final list = (response['data'] as List)
          .map((json) => Announcement.fromJson(json))
          .toList();

      final role = await _getUserRole();
      return Announcement.filterByRole(list, role);
    }
    return [];
  }

  static Future<List<Announcement>> getActiveAnnouncements() async {
    final announcements = await getAnnouncements();
    return announcements.where((a) => a.status == 'active').toList();
  }

  static String getAnnouncementKey(Announcement item) {
    return item.announcementId?.toString() ?? item.title;
  }

  static Future<Set<String>> getReadAnnouncementIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String>? list = prefs.getStringList(_readKey);
      return list?.toSet() ?? <String>{};
    } catch (_) {
      return <String>{};
    }
  }

  static Future<void> markAsRead(Announcement item) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final readSet = await getReadAnnouncementIds();
      final key = getAnnouncementKey(item);
      if (!readSet.contains(key)) {
        readSet.add(key);
        await prefs.setStringList(_readKey, readSet.toList());
      }
    } catch (_) {}
  }

  static Future<int> getUnreadCount() async {
    try {
      final active = await getActiveAnnouncements();
      final readSet = await getReadAnnouncementIds();
      int count = 0;
      for (final item in active) {
        final key = getAnnouncementKey(item);
        if (!readSet.contains(key)) {
          count++;
        }
      }
      return count;
    } catch (_) {
      return 0;
    }
  }
}

