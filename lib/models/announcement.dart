class Announcement {
  final int? announcementId;
  final String title;
  final String? announcementType;
  final String? description;
  final String? image;
  final String? publishDate;
  final String? status;
  final int? userId;
  final String? userName;

  Announcement({
    this.announcementId,
    required this.title,
    this.announcementType,
    this.description,
    this.image,
    this.publishDate,
    this.status,
    this.userId,
    this.userName,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      announcementId: json['announcement_id'],
      title: json['title'] ?? '',
      announcementType: json['announcement_type'],
      description: json['description'],
      image: json['image'],
      publishDate: json['publish_date'],
      status: json['status'],
      userId: json['user_id'],
      userName: json['user_name'],
    );
  }

  bool get isUrgent => announcementType == 'urgent';
  bool get isActivity => announcementType == 'activity';
  bool get isGeneral =>
      announcementType == 'general' || (!isUrgent && !isActivity);

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
