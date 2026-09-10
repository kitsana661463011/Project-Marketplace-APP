class MarketMapItem {
  final String mapItemId;
  final String itemType; // 'zone', 'block', 'road', 'entrance'
  final int? stallId;
  final int? zoneId;
  final String label;
  final double x;
  final double y;
  final double width;
  final double height;
  final String fillColor;
  final int rotation;
  final int zIndex;
  final String size;
  final double price;
  final String rentalType; // 'daily' | 'monthly'
  final double? dailyPrice;
  final double? monthlyPrice;
  final double? entryFee;
  final double? securityDeposit;
  final bool hasElectricity;
  final bool hasWater;
  final String? image1;
  final String? image2;
  final List<String> images;
  final String
  status; // 'available', 'occupied', 'approved', 'repair', 'maintenance', 'refund_requested', 'refunded'
  final Map<String, dynamic>? seller;
  final bool hasShop;
  final bool isShopOpen;
  final String? shopStatus;

  MarketMapItem({
    required this.mapItemId,
    required this.itemType,
    this.stallId,
    this.zoneId,
    required this.label,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.fillColor,
    required this.rotation,
    required this.zIndex,
    required this.size,
    required this.price,
    this.rentalType = 'daily',
    this.dailyPrice,
    this.monthlyPrice,
    this.entryFee,
    this.securityDeposit,
    this.hasElectricity = true,
    this.hasWater = true,
    this.image1,
    this.image2,
    this.images = const [],
    required this.status,
    this.seller,
    this.hasShop = false,
    this.isShopOpen = false,
    this.shopStatus,
  });

  factory MarketMapItem.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic val, [double fallback = 0.0]) {
      if (val == null) return fallback;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? fallback;
    }

    double? parseNullableDouble(dynamic val) {
      if (val == null) return null;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString());
    }

    bool parseBool(dynamic val, [bool fallback = true]) {
      if (val == null) return fallback;
      if (val is bool) return val;
      if (val is num) return val == 1;
      final str = val.toString().toLowerCase().trim();
      return str == '1' || str == 'true';
    }

    final String rType = json['rental_type'] ?? 'daily';
    final double mainPrice = parseDouble(json['price'], 500.0);

    final String? img1 = json['image1'] as String?;
    final String? img2 = json['image2'] as String?;
    List<String> imgList = [];
    if (json['images'] is List) {
      imgList = (json['images'] as List)
          .map((e) => e?.toString() ?? '')
          .where((e) => e.isNotEmpty)
          .toList();
    } else {
      if (img1 != null && img1.isNotEmpty) imgList.add(img1);
      if (img2 != null && img2.isNotEmpty) imgList.add(img2);
    }

    return MarketMapItem(
      mapItemId: json['map_item_id']?.toString() ?? '',
      itemType: json['item_type'] ?? 'block',
      stallId: json['stall_id'] != null
          ? int.tryParse(json['stall_id'].toString())
          : null,
      zoneId: json['zone_id'] != null
          ? int.tryParse(json['zone_id'].toString())
          : null,
      label: json['label'] ?? '',
      x: parseDouble(json['x']),
      y: parseDouble(json['y']),
      width: parseDouble(json['width'], 80.0),
      height: parseDouble(json['height'], 80.0),
      fillColor: json['fill_color'] ?? '#64748B',
      rotation: (json['rotation'] ?? 0).toInt(),
      zIndex: (json['z_index'] ?? 0).toInt(),
      size: json['size'] ?? '3x3 เมตร',
      price: mainPrice,
      rentalType: rType,
      dailyPrice:
          parseNullableDouble(json['daily_price']) ??
          (rType == 'daily' ? mainPrice : 500.0),
      monthlyPrice:
          parseNullableDouble(json['monthly_price']) ??
          (rType == 'monthly' ? mainPrice : null),
      entryFee: parseNullableDouble(json['entry_fee']),
      securityDeposit: parseNullableDouble(json['security_deposit']),
      hasElectricity: parseBool(json['has_electricity'], true),
      hasWater: parseBool(json['has_water'], true),
      image1: img1,
      image2: img2,
      images: imgList,
      status: json['status'] ?? 'available',
      seller: json['seller'] != null
          ? Map<String, dynamic>.from(json['seller'])
          : null,
      hasShop: json['has_shop'] == true ||
          (json['seller'] != null &&
           json['seller']['shop_name'] != null &&
           json['seller']['shop_name'].toString().trim().isNotEmpty),
      isShopOpen: json['is_shop_open'] == true ||
          json['seller']?['is_open'] == true ||
          json['shop_status'] == 'เปิดบริการอยู่' ||
          json['seller']?['shop_status'] == 'เปิดบริการอยู่' ||
          json['shop_status']?.toString().toLowerCase() == 'open' ||
          json['seller']?['shop_status']?.toString().toLowerCase() == 'open',
      shopStatus: json['shop_status']?.toString() ??
          json['seller']?['shop_status']?.toString() ??
          (json['has_shop'] == true || json['seller']?['shop_name'] != null ? 'เปิดบริการอยู่' : null),
    );
  }

  String get stallNum => label;

  bool get hasImages => images.isNotEmpty;

  bool get isBlock => itemType == 'block';
  bool get isZone => itemType == 'zone';
  bool get isRoad => itemType == 'road';
  bool get isEntrance => itemType == 'entrance';
  bool get isToilet => itemType == 'toilet';
  bool get isExit => itemType == 'exit';
  bool get isDining => itemType == 'dining';
  bool get isParking => itemType == 'parking';
  bool get isInfo => itemType == 'info';
  bool get isTrash => itemType == 'trash';
  bool get isSpecialFacility =>
      isToilet || isExit || isDining || isParking || isInfo || isTrash;
  bool get isAvailable => status == 'available';
  bool get isPending => status == 'occupied' || status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isOccupied => status == 'approved' || status == 'occupied';
  bool get isRepair => status == 'repair' || status == 'maintenance';
  bool get isRefundRequested => status == 'refund_requested';
  bool get isRefunded => status == 'refunded';
  bool get isDaily => rentalType == 'daily';
  bool get isMonthly => rentalType == 'monthly';

  // Customer Shop Status Getters
  bool get isShopClosed => hasShop && !isShopOpen;
}

class MarketMap {
  final int mapId;
  final String mapName;
  final double mapWidth;
  final double mapHeight;
  final List<MarketMapItem> items;

  MarketMap({
    required this.mapId,
    required this.mapName,
    required this.mapWidth,
    required this.mapHeight,
    required this.items,
  });

  factory MarketMap.fromJson(Map<String, dynamic> json) {
    final itemsList = (json['items'] as List? ?? [])
        .map((item) => MarketMapItem.fromJson(Map<String, dynamic>.from(item)))
        .toList();
    // Sort by z_index so zones render behind blocks
    itemsList.sort((a, b) => a.zIndex.compareTo(b.zIndex));
    return MarketMap(
      mapId: json['map_id'] ?? 1,
      mapName: json['map_name'] ?? 'แผนที่ตลาด',
      mapWidth: (json['map_width'] ?? 5000).toDouble(),
      mapHeight: (json['map_height'] ?? 5000).toDouble(),
      items: itemsList,
    );
  }
}
