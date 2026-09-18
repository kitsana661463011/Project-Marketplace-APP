import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_api_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings settings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notificationsPlugin.initialize(
        settings: settings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('Notification clicked with payload: ${response.payload}');
        },
      );

      // Request notification permission for Android 13+
      if (!kIsWeb) {
        final androidImplementation = _notificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        if (androidImplementation != null) {
          await androidImplementation.requestNotificationsPermission();
        }
      }

      _initialized = true;
      debugPrint('NotificationService initialized successfully');
    } catch (e) {
      debugPrint('NotificationService initialization error: $e');
    }
  }

  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      if (!_initialized) {
        await initialize();
      }

      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'marketplace_channel',
        'การแจ้งเตือนตลาด',
        channelDescription: 'แจ้งเตือนประกาศ ข่าวสาร และการหมดอายุสัญญาเช่าแผงค้า',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notificationsPlugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: platformDetails,
        payload: payload,
      );
    } catch (e) {
      debugPrint('Failed to show notification: $e');
    }
  }

  /// แสดงการแจ้งเตือนสัญญาแผงค้าใกล้หมดอายุ (ภายใน 5 วัน)
  static Future<void> showStallExpiringNotification({
    required String stallNumber,
    required int daysLeft,
    int? bookingId,
  }) async {
    final title = '⚠️ แผงค้า $stallNumber ใกล้หมดสัญญา!';
    final body = daysLeft == 0
        ? 'สัญญาเช่าแผงค้า $stallNumber หมดอายุวันนี้ กรุณากดต่อสัญญาเพื่อรักษาสิทธิ์'
        : 'สัญญาเช่าแผงค้า $stallNumber จะหมดอายุในอีก $daysLeft วัน กรุณากดต่อสัญญาล่วงหน้า';

    await showNotification(
      id: bookingId ?? (stallNumber.hashCode & 0x7FFFFFFF),
      title: title,
      body: body,
      payload: 'booking_renewal_${bookingId ?? stallNumber}',
    );
  }

  /// แสดงการแจ้งเตือนประกาศใหม่จากตลาด
  static Future<void> showNewAnnouncementNotification({
    required String title,
    required String type,
    int? announcementId,
  }) async {
    final prefix = type == 'urgent' ? '🚨 [ด่วน] ' : '📢 ';
    await showNotification(
      id: announcementId ?? (title.hashCode & 0x7FFFFFFF),
      title: '$prefixประกาศใหม่จากตลาด',
      body: title,
      payload: 'announcement_${announcementId ?? 0}',
    );
  }

  /// Callback when a new notification arrives to display in-app banner on all platforms (including Web)
  static void Function(String title, String message)? onNotificationReceived;

  /// ตรวจสอบและยิงแจ้งเตือนส่วนบุคคลใหม่ (ผลสมัครผู้ค้า, การจองแผง, การคืนเงิน, การตอบกลับปัญหา)
  static Future<void> checkAndTriggerNewNotifications(int userId) async {
    try {
      final notifications = await NotificationApiService.getNotifications(userId: userId);
      if (notifications.isEmpty) return;

      final prefs = await SharedPreferences.getInstance();
      final shownIds = (prefs.getStringList('shown_notif_ids_$userId') ?? []).toSet();

      final newUnread = notifications.where((n) => !n.isRead && !shownIds.contains(n.notificationId.toString())).toList();

      for (final notif in newUnread) {
        await showNotification(
          id: notif.notificationId,
          title: '📢 ${notif.typeTitle}',
          body: notif.message,
          payload: 'notification_${notif.notificationId}',
        );
        onNotificationReceived?.call('📢 ${notif.typeTitle}', notif.message);
        shownIds.add(notif.notificationId.toString());
      }

      await prefs.setStringList('shown_notif_ids_$userId', shownIds.toList());
    } catch (e) {
      debugPrint('Error checking and triggering notifications: $e');
    }
  }
}
