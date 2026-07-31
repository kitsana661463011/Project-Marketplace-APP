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
  final String status; // 'available', 'occupied', 'repair'
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
    required this.status,
    this.seller,
  });

  factory MarketMapItem.fromJson(Map<String, dynamic> json) {
    return MarketMapItem(
      mapItemId: json['map_item_id']?.toString() ?? '',
      itemType: json['item_type'] ?? 'block',
      stallId: json['stall_id'],
      zoneId: json['zone_id'],
      label: json['label'] ?? '',
      x: (json['x'] ?? 0).toDouble(),
      y: (json['y'] ?? 0).toDouble(),
      width: (json['width'] ?? 80).toDouble(),
      height: (json['height'] ?? 80).toDouble(),
      fillColor: json['fill_color'] ?? '#64748B',
      rotation: (json['rotation'] ?? 0).toInt(),
      zIndex: (json['z_index'] ?? 0).toInt(),
      size: json['size'] ?? '3x3 เมตร',
      price: (json['price'] ?? 500).toDouble(),
      status: json['status'] ?? 'available',
      seller: json['seller'] != null ? Map<String, dynamic>.from(json['seller']) : null,
    );
  }

  bool get isBlock => itemType == 'block';
  bool get isZone => itemType == 'zone';
  bool get isRoad => itemType == 'road';
  bool get isEntrance => itemType == 'entrance';
  bool get isAvailable => status == 'available';
  bool get isOccupied => status == 'occupied';
  bool get isRepair => status == 'repair';
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
