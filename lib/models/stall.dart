class Stall {
  final int? stallId;
  final String stallNumber;
  final String? size;
  final String status;
  final int? zoneId;
  final String? startDate;
  final String? endDate;
  final Map<String, dynamic>? zone;

  Stall({
    this.stallId,
    required this.stallNumber,
    this.size,
    this.status = 'available',
    this.zoneId,
    this.startDate,
    this.endDate,
    this.zone,
  });

  factory Stall.fromJson(Map<String, dynamic> json) {
    return Stall(
      stallId: json['stall_id'],
      stallNumber: json['stall_number'] ?? '',
      size: json['size'],
      status: json['status'] ?? 'available',
      zoneId: json['zone_id'],
      startDate: json['start_date'],
      endDate: json['end_date'],
      zone: json['zone'] != null
          ? Map<String, dynamic>.from(json['zone'])
          : null,
    );
  }

  String get zoneName => zone?['zone_name'] ?? 'ไม่ระบุโซน';
  double get zonePrice => (zone?['zone_price'] ?? 0).toDouble();
  bool get isAvailable => status == 'available';
}
