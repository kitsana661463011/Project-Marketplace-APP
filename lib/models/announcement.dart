class Announcement {
  final int? announcementId;
  final String title;
  final String? announcementType;
  final String? description;
  final String? publishDate;
  final String? status;
  final int? userId;
  final String? userName;

  Announcement({
    this.announcementId,
    required this.title,
    this.announcementType,
    this.description,
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
      publishDate: json['publish_date'],
      status: json['status'],
      userId: json['user_id'],
      userName: json['user_name'],
    );
  }

  bool get isUrgent => announcementType == 'urgent';
  bool get isActivity => announcementType == 'activity';
}
