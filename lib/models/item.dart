class Item {
  final int? itemId;
  final int? shopId;
  final String itemName;
  final double price;
  final String? description;
  final String? itemImage;
  final int? categoryId;
  final Map<String, dynamic>? shop;
  final Map<String, dynamic>? category;

  Item({
    this.itemId,
    this.shopId,
    required this.itemName,
    required this.price,
    this.description,
    this.itemImage,
    this.categoryId,
    this.shop,
    this.category,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      itemId: json['item_id'],
      shopId: json['shop_id'],
      itemName: json['item_name'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      description: json['description'],
      itemImage: json['item_image'],
      categoryId: json['category_id'],
      shop: json['shop'] != null
          ? Map<String, dynamic>.from(json['shop'])
          : null,
      category: json['category'] != null
          ? Map<String, dynamic>.from(json['category'])
          : null,
    );
  }

  String get categoryName => category?['category_name'] ?? 'ไม่ระบุ';
  String get shopName => shop?['shop_name'] ?? 'ไม่ทราบ';
}
