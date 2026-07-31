class Stall {
  final int? stallId;
  final String stallNumber;
  final String? size;
  final double? price;
  final String rentalType;
  final double dailyPrice;
  final double monthlyPrice;
  final double entryFee;
  final double securityDeposit;
  final String status;
  final int? zoneId;
  final String? startDate;
  final String? endDate;
  final Map<String, dynamic>? zone;

  Stall({
    this.stallId,
    required this.stallNumber,
    this.size,
    this.price,
    this.rentalType = 'daily',
    this.dailyPrice = 500.0,
    this.monthlyPrice = 5000.0,
    this.entryFee = 1000.0,
    this.securityDeposit = 2000.0,
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
      price: json['price'] != null ? double.tryParse(json['price'].toString()) : null,
      rentalType: json['rental_type'] ?? 'daily',
      dailyPrice: json['daily_price'] != null
          ? (double.tryParse(json['daily_price'].toString()) ?? 500.0)
          : (json['price'] != null ? (double.tryParse(json['price'].toString()) ?? 500.0) : 500.0),
      monthlyPrice: json['monthly_price'] != null
          ? (double.tryParse(json['monthly_price'].toString()) ?? 5000.0)
          : 5000.0,
      entryFee: json['entry_fee'] != null
          ? (double.tryParse(json['entry_fee'].toString()) ?? 1000.0)
          : 1000.0,
      securityDeposit: json['security_deposit'] != null
          ? (double.tryParse(json['security_deposit'].toString()) ?? 2000.0)
          : 2000.0,
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
  double get zonePrice => (zone?['zone_price'] ?? (isDaily ? dailyPrice : monthlyPrice)).toDouble();
  bool get isAvailable => status == 'available';

  bool get isDaily => rentalType == 'daily';
  bool get isMonthly => rentalType == 'monthly';
  bool get supportsDaily => rentalType == 'daily';
  bool get supportsMonthly => rentalType == 'monthly';
}
