import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../models/app_notification.dart';
import 'api_service.dart';

class NotificationApiService {
  static Future<List<AppNotification>> getNotifications({int? userId}) async {
    try {
      final endpoint = userId != null
          ? '${ApiConfig.notifications}?user_id=$userId'
          : ApiConfig.notifications;

      final response = await ApiService.get(endpoint);

      if (response['status'] == true && response['data'] != null) {
        final List raw = response['data'] as List;
        return raw.map((json) => AppNotification.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error getting notifications: $e');
      return [];
    }
  }

  static Future<int> getUnreadCount({int? userId}) async {
    try {
      final endpoint = userId != null
          ? '${ApiConfig.notifications}/unread-count?user_id=$userId'
          : '${ApiConfig.notifications}/unread-count';

      final response = await ApiService.get(endpoint);

      if (response['status'] == true) {
        return (response['unread_count'] ?? response['data']?['unread_count'] ?? 0) as int;
      }
      return 0;
    } catch (e) {
      debugPrint('Error getting notification unread count: $e');
      return 0;
    }
  }

  static Future<bool> markAsRead(int notificationId) async {
    try {
      final response = await ApiService.post(
        '${ApiConfig.notifications}/$notificationId/read',
        {},
      );
      return response['status'] == true;
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
      return false;
    }
  }

  static Future<bool> markAllAsRead(int userId) async {
    try {
      final response = await ApiService.post(
        '${ApiConfig.notifications}/read-all',
        {'user_id': userId},
      );
      return response['status'] == true;
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
      return false;
    }
  }

  static Future<bool> deleteNotification(int notificationId) async {
    try {
      final response = await ApiService.delete(
        '${ApiConfig.notifications}/$notificationId',
      );
      return response['status'] == true;
    } catch (e) {
      debugPrint('Error deleting notification: $e');
      return false;
    }
  }
}
