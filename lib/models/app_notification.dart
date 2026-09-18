import 'package:flutter/material.dart';

class AppNotification {
  final int notificationId;
  final int userId;
  final String message;
  final String type;
  final bool isRead;
  final DateTime? notifyDate;

  AppNotification({
    required this.notificationId,
    required this.userId,
    required this.message,
    this.type = 'other',
    this.isRead = false,
    this.notifyDate,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    DateTime? parsedDate;
    if (json['notify_date'] != null) {
      try {
        parsedDate = DateTime.parse(json['notify_date'].toString());
      } catch (_) {}
    }

    return AppNotification(
      notificationId: int.tryParse(json['notification_id']?.toString() ?? json['id']?.toString() ?? '0') ?? 0,
      userId: int.tryParse(json['user_id']?.toString() ?? '0') ?? 0,
      message: json['message']?.toString() ?? '',
      type: json['type']?.toString() ?? 'other',
      isRead: json['is_read'] == true || json['is_read'] == 1 || json['is_read'] == '1',
      notifyDate: parsedDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'notification_id': notificationId,
      'user_id': userId,
      'message': message,
      'type': type,
      'is_read': isRead,
      'notify_date': notifyDate?.toIso8601String(),
    };
  }

  AppNotification copyWith({
    int? notificationId,
    int? userId,
    String? message,
    String? type,
    bool? isRead,
    DateTime? notifyDate,
  }) {
    return AppNotification(
      notificationId: notificationId ?? this.notificationId,
      userId: userId ?? this.userId,
      message: message ?? this.message,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      notifyDate: notifyDate ?? this.notifyDate,
    );
  }

  String get typeTitle {
    switch (type) {
      case 'seller':
        return 'ผลการสมัครผู้ค้า';
      case 'booking':
        return 'การจองแผงค้า';
      case 'refund':
        return 'การโอนเงินคืน';
      case 'problem':
        return 'การตอบกลับปัญหา';
      default:
        return 'การแจ้งเตือน';
    }
  }

  IconData get iconData {
    switch (type) {
      case 'seller':
        return Icons.storefront_rounded;
      case 'booking':
        return Icons.store_rounded;
      case 'refund':
        return Icons.account_balance_wallet_rounded;
      case 'problem':
        return Icons.report_problem_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color get categoryColor {
    switch (type) {
      case 'seller':
        return const Color(0xFF0284C7); // Sky blue
      case 'booking':
        return const Color(0xFF0D9488); // Teal
      case 'refund':
        return const Color(0xFF16A34A); // Green
      case 'problem':
        return const Color(0xFFEA580C); // Orange
      default:
        return const Color(0xFF6366F1); // Indigo
    }
  }
}
