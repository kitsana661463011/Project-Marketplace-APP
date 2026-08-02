class Item {
  final int? itemId;
  final int? shopId;
  final String itemName;
  final double price;
  final String? description;
  final String? itemImage;
  final List<String> images;
  final int? categoryId;
  final String status;
  final Map<String, dynamic>? shop;
  final Map<String, dynamic>? category;

  Item({
    this.itemId,
    this.shopId,
    required this.itemName,
    required this.price,
    this.description,
    this.itemImage,
    this.images = const [],
    this.categoryId,
    this.status = 'เปิดขาย',
    this.shop,
    this.category,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    List<String> parsedImages = [];
    if (json['images'] != null) {
      if (json['images'] is List) {
        parsedImages = List<String>.from(json['images']);
      } else if (json['images'] is String) {
        parsedImages = (json['images'] as String)
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }
    }
    if (parsedImages.isEmpty &&
        json['item_image'] != null &&
        json['item_image'].toString().isNotEmpty) {
      parsedImages = [json['item_image'].toString()];
    }

    return Item(
      itemId: json['item_id'],
      shopId: json['shop_id'],
      itemName: json['item_name'] ?? '',
      price: (() {
        final raw = json['price'];
        if (raw == null) return 0.0;
        if (raw is num) return raw.toDouble();
        final parsed = double.tryParse(raw.toString());
        return parsed ?? 0.0;
      })(),
      description: json['description'],
      itemImage: json['item_image'],
      images: parsedImages,
      categoryId: json['category_id'],
      shop: json['shop'] != null
          ? Map<String, dynamic>.from(json['shop'])
          : null,
      category: json['category'] != null
          ? Map<String, dynamic>.from(json['category'])
          : null,
      status: json['status'] ?? 'เปิดขาย',
    );
  }

  String get categoryName => category?['category_name'] ?? 'ไม่ระบุ';
  String get shopName => shop?['shop_name'] ?? 'ไม่ทราบ';
  bool get isAvailable => status == 'เปิดขาย';

  List<String> get allImages {
    if (images.isNotEmpty) return images;
    if (itemImage != null && itemImage!.isNotEmpty) return [itemImage!];
    return [];
  }
}
