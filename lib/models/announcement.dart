class Announcement {
  final int? announcementId;
  final String title;
  final String? announcementType;
  final String? description;
  final String? image;
  final String? publishDate;
  final String? endDate;
  final String? status;
  final int? userId;
  final String? userName;
  final bool? isActiveField;
  final bool? isExpiredField;
  final bool? isScheduledField;
  final bool? isReadField;

  Announcement({
    this.announcementId,
    required this.title,
    this.announcementType,
    this.description,
    this.image,
    this.publishDate,
    this.endDate,
    this.status,
    this.userId,
    this.userName,
    this.isActiveField,
    this.isExpiredField,
    this.isScheduledField,
    this.isReadField,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      announcementId: json['announcement_id'],
      title: json['title'] ?? '',
      announcementType: json['announcement_type'],
      description: json['description'],
      image: json['image'],
      publishDate: json['publish_date'],
      endDate: json['end_date'],
      status: json['status'],
      userId: json['user_id'],
      userName: json['user_name'],
      isActiveField: json['is_active'],
      isExpiredField: json['is_expired'],
      isScheduledField: json['is_scheduled'],
      isReadField: json['is_read'],
    );
  }

  bool get isUrgent => announcementType == 'urgent';
  bool get isActivity => announcementType == 'activity';
  bool get isGeneral =>
      announcementType == 'general' || (!isUrgent && !isActivity);

  bool get isExpired {
    if (isExpiredField != null) return isExpiredField!;
    if (endDate == null || endDate!.isEmpty) return false;
    final end = DateTime.tryParse(endDate!);
    return end != null && DateTime.now().isAfter(end);
  }

  bool get isScheduled {
    if (isScheduledField != null) return isScheduledField!;
    if (publishDate == null || publishDate!.isEmpty) return false;
    final start = DateTime.tryParse(publishDate!);
    return start != null && DateTime.now().isBefore(start);
  }

  bool get isCurrentlyActive {
    if (status != 'active') return false;
    if (isActiveField != null) return isActiveField!;
    return !isExpired && !isScheduled;
  }

  String get dateRangeText {
    final start = publishDate != null ? publishDate!.split('T')[0] : '';
    final end = endDate != null ? endDate!.split('T')[0] : '';
    if (start.isNotEmpty && end.isNotEmpty) {
      return '$start ถึง $end';
    } else if (start.isNotEmpty) {
      return 'เริ่ม $start';
    }
    return '';
  }

  /// กรองประกาศตามบทบาทผู้ใช้:
  /// - ลูกค้า (buyer): แสดงเฉพาะประกาศทั่วไป (general)
  /// - ผู้ค้า (seller/vendor/admin): แสดงประกาศทุกประเภท
  static List<Announcement> filterByRole(
    List<Announcement> list,
    String? userRole,
  ) {
    final role = (userRole ?? 'buyer').toLowerCase();
    final isVendor = role == 'seller' || role == 'vendor' || role == 'admin';

    if (isVendor) {
      return list;
    }

    return list.where((item) => item.isGeneral).toList();
  }
}
