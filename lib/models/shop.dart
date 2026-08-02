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
  });

  factory Shop.fromJson(Map<String, dynamic> json) {
    return Shop(
      shopId: json['shop_id'],
      shopName: json['shop_name'] ?? '',
      categoryId: json['category_id'],
      description: json['description'],
      shopPhone: json['shop_phone'],
      socialLinks: json['social_links'],
      shopImage: json['shop_image'],
      userId: json['user_id'],
      category: json['category'] != null
          ? Map<String, dynamic>.from(json['category'])
          : null,
      owner: json['owner'] != null
          ? Map<String, dynamic>.from(json['owner'])
          : null,
      followerCount: json['follows_count'] is int
          ? json['follows_count'] as int
          : int.tryParse(json['follows_count']?.toString() ?? '') ?? 0,
    );
  }

  String get categoryName => category?['category_name'] ?? 'ไม่ระบุหมวดหมู่';
  String get ownerName => owner?['username'] ?? 'ไม่ทราบ';
}
