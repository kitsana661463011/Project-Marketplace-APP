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
  final String
  status; // 'available', 'occupied', 'approved', 'repair', 'maintenance', 'refund_requested', 'refunded'
  final Map<String, dynamic>? seller;

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
    required this.status,
    this.seller,
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
      status: json['status'] ?? 'available',
      seller: json['seller'] != null
          ? Map<String, dynamic>.from(json['seller'])
          : null,
    );
  }

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
