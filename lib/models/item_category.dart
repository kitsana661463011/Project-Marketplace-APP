class ItemCategory {
  final int? categoryId;
  final String categoryName;
  final int? shopId;
  final int itemCount;

  ItemCategory({
    this.categoryId,
    required this.categoryName,
    this.shopId,
    this.itemCount = 0,
  });

  factory ItemCategory.fromJson(Map<String, dynamic> json) {
    return ItemCategory(
      categoryId: json['category_id'] is int
          ? json['category_id']
          : int.tryParse(json['category_id']?.toString() ?? ''),
      categoryName: json['category_name']?.toString() ?? 'ไม่ระบุประเภท',
      shopId: json['shop_id'] is int
          ? json['shop_id']
          : int.tryParse(json['shop_id']?.toString() ?? ''),
      itemCount: json['items_count'] is int
          ? json['items_count']
          : (int.tryParse(json['items_count']?.toString() ?? '') ?? 0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category_id': categoryId,
      'category_name': categoryName,
      'shop_id': shopId,
    };
  }
}
