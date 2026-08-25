class Shop {
  final int? shopId;
  final String shopName;
  final int? categoryId;
  final String? description;
  final String? shopPhone;
  final String? socialLinks;
  final String? shopImage;
  final int? userId;
  final Map<String, dynamic>? category;
  final Map<String, dynamic>? owner;
  final int followerCount;
  final double? avgRating;
  final int reviewCount;
  final String? stallNumber;
  final String? zoneName;
  final String status;
  final List<String> tags;

  Shop({
    this.shopId,
    required this.shopName,
    this.categoryId,
    this.description,
    this.shopPhone,
    this.socialLinks,
    this.shopImage,
    this.userId,
    this.category,
    this.owner,
    this.followerCount = 0,
    this.avgRating,
    this.reviewCount = 0,
    this.stallNumber,
    this.zoneName,
    this.status = 'เปิดบริการอยู่',
    this.tags = const [],
  });

  factory Shop.fromJson(Map<String, dynamic> json) {
    final rawStatus = json['status']?.toString();
    final parsedStatus =
        (rawStatus != null && rawStatus.trim().isNotEmpty)
            ? rawStatus.trim()
            : (json['is_open'] == false || json['is_open'] == 0
                ? 'ปิดบริการชั่วคราว'
                : 'เปิดบริการอยู่');

    final rawTags = json['tags'];
    final List<String> parsedTags = [];
    if (rawTags is List) {
      for (var t in rawTags) {
        if (t != null && t.toString().trim().isNotEmpty) {
          parsedTags.add(t.toString().trim());
        }
      }
    } else if (rawTags is String && rawTags.trim().isNotEmpty) {
      parsedTags.addAll(
        rawTags.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty),
      );
    }

    return Shop(
      shopId: json['shop_id'],
      shopName: json['shop_name'] ?? '',
      categoryId: json['category_id'],
      description: json['description'],
      shopPhone: json['shop_phone'],
      socialLinks: json['social_links'],
      shopImage: json['shop_image'],
      userId: json['user_id'],
      category:
          json['category'] != null
              ? Map<String, dynamic>.from(json['category'])
              : null,
      owner:
          json['owner'] != null
              ? Map<String, dynamic>.from(json['owner'])
              : null,
      followerCount:
          json['follows_count'] is int
              ? json['follows_count'] as int
              : int.tryParse(json['follows_count']?.toString() ?? '') ?? 0,
      avgRating:
          json['avg_rating'] != null
              ? (double.tryParse(json['avg_rating'].toString()) ?? 0.0)
              : null,
      reviewCount:
          json['review_count'] is int
              ? json['review_count'] as int
              : int.tryParse(json['review_count']?.toString() ?? '') ?? 0,
      stallNumber: json['stall_number']?.toString(),
      zoneName: json['zone_name']?.toString(),
      status: parsedStatus,
      tags: parsedTags,
    );
  }

  String get categoryName => category?['category_name'] ?? 'ไม่ระบุหมวดหมู่';
  String get ownerName => owner?['username'] ?? 'ไม่ทราบ';

  bool get isOpen {
    final s = status.trim().toLowerCase();
    if (s == 'ปิดบริการชั่วคราว' || s == 'closed' || s == 'inactive') {
      return false;
    }
    return true;
  }
}
