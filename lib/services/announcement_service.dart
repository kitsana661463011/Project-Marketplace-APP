import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/announcement.dart';
import '../models/user.dart';
import 'api_service.dart';

class AnnouncementService {
  static Future<int?> _getCurrentUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataStr = prefs.getString('user_data');
      if (userDataStr != null) {
        final Map<String, dynamic> userMap = jsonDecode(userDataStr);
        final user = UserModel.fromJson(userMap);
        return user.userId;
      }
    } catch (_) {}
    return null;
  }

  static Future<String> _getReadKey() async {
    final userId = await _getCurrentUserId();
    return userId != null ? 'read_announcements_user_$userId' : 'read_announcements_guest';
  }

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
    final userId = await _getCurrentUserId();
    final url = userId != null
        ? '${ApiConfig.announcements}?user_id=$userId'
        : ApiConfig.announcements;

    final response = await ApiService.get(url);
    if (response['status'] == true && response['data'] is List) {
      final list = (response['data'] as List)
          .map((json) => Announcement.fromJson(json))
          .toList();

      // Sync backend is_read with local read set
      try {
        final prefs = await SharedPreferences.getInstance();
        final key = await _getReadKey();
        final localReadSet = await getReadAnnouncementIds();
        bool changed = false;
        for (final item in list) {
          if (item.isReadField == true) {
            final itemKey = getAnnouncementKey(item);
            if (!localReadSet.contains(itemKey)) {
              localReadSet.add(itemKey);
              changed = true;
            }
          }
        }
        if (changed) {
          await prefs.setStringList(key, localReadSet.toList());
        }
      } catch (_) {}

      final role = await _getUserRole();
      return Announcement.filterByRole(list, role);
    }
    return [];
  }

  static Future<List<Announcement>> getActiveAnnouncements() async {
    final announcements = await getAnnouncements();
    return announcements.where((a) => a.isCurrentlyActive).toList();
  }

  static Future<List<Announcement>> getHistoryAnnouncements() async {
    final announcements = await getAnnouncements();
    return announcements.where((a) => a.isExpired).toList();
  }

  static String getAnnouncementKey(Announcement item) {
    return item.announcementId?.toString() ?? item.title.trim();
  }

  static Future<Set<String>> getReadAnnouncementIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = await _getReadKey();
      final List<String>? list = prefs.getStringList(key);
      return list?.toSet() ?? <String>{};
    } catch (_) {
      return <String>{};
    }
  }

  static Future<void> markAsRead(Announcement item) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = await _getReadKey();
      final readSet = await getReadAnnouncementIds();
      final itemKey = getAnnouncementKey(item);
      if (!readSet.contains(itemKey)) {
        readSet.add(itemKey);
        await prefs.setStringList(key, readSet.toList());
      }

      // Backend sync
      final userId = await _getCurrentUserId();
      if (userId != null && item.announcementId != null) {
        await ApiService.post(
          '${ApiConfig.announcements}/${item.announcementId}/read',
          {'user_id': userId},
        );
      }
    } catch (_) {}
  }

  static Future<void> markAllAsRead() async {
    try {
      final active = await getActiveAnnouncements();
      final prefs = await SharedPreferences.getInstance();
      final key = await _getReadKey();
      final readSet = await getReadAnnouncementIds();
      for (final item in active) {
        readSet.add(getAnnouncementKey(item));
      }
      await prefs.setStringList(key, readSet.toList());

      // Backend sync
      final userId = await _getCurrentUserId();
      if (userId != null) {
        await ApiService.post(
          '${ApiConfig.announcements}/read-all',
          {'user_id': userId},
        );
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
