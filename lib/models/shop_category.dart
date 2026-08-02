class ShopCategory {
  final int? categoryId;
  final String categoryName;
  final String? description;

  ShopCategory({this.categoryId, required this.categoryName, this.description});

  factory ShopCategory.fromJson(Map<String, dynamic> json) {
    return ShopCategory(
      categoryId: json['category_id'],
      categoryName: json['category_name'] ?? 'ไม่ระบุหมวดหมู่',
      description: json['description'],
    );
  }
}
