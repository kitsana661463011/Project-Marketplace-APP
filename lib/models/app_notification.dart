import 'package:flutter/material.dart';

class AppNotification {
  final int notificationId;
  final int userId;
  final String? title;
  final String message;
  final String type;
  final int? referenceId;
  final bool isRead;
  final DateTime? notifyDate;

  AppNotification({
    required this.notificationId,
    required this.userId,
    this.title,
    required this.message,
    this.type = 'other',
    this.referenceId,
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
      title: json['title']?.toString(),
      message: json['message']?.toString() ?? '',
      type: json['type']?.toString() ?? 'other',
      referenceId: int.tryParse(json['reference_id']?.toString() ?? ''),
      isRead: json['is_read'] == true || json['is_read'] == 1 || json['is_read'] == '1',
      notifyDate: parsedDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'notification_id': notificationId,
      'user_id': userId,
      'title': title,
      'message': message,
      'type': type,
      'reference_id': referenceId,
      'is_read': isRead,
      'notify_date': notifyDate?.toIso8601String(),
    };
  }

  AppNotification copyWith({
    int? notificationId,
    int? userId,
    String? title,
    String? message,
    String? type,
    int? referenceId,
    bool? isRead,
    DateTime? notifyDate,
  }) {
    return AppNotification(
      notificationId: notificationId ?? this.notificationId,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      referenceId: referenceId ?? this.referenceId,
      isRead: isRead ?? this.isRead,
      notifyDate: notifyDate ?? this.notifyDate,
    );
  }

  String get displayTitle {
    if (title != null && title!.trim().isNotEmpty) {
      return title!.trim();
    }
    return typeTitle;
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
      case 'announcement':
        return 'ประกาศจากตลาด';
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
      case 'announcement':
        return Icons.campaign_rounded;
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
      case 'announcement':
        return const Color(0xFF8B5CF6); // Purple
      default:
        return const Color(0xFF6366F1); // Indigo
    }
  }
}
