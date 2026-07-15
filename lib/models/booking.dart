class Booking {
  final int? bookingId;
  final int? userId;
  final int? stallId;
  final String? bookingDate;
  final String? startDate;
  final String? endDate;
  final String status;
  // Joined fields from API
  final String? userName;
  final String? userEmail;
  final String? userPhone;
  final String? stallNumber;
  final String? stallSize;
  final String? stallStatus;
  final String? zoneName;
  final int? paymentId;
  final double? amount;
  final String? paymentDate;
  final String? paymentSlip;
  final String? paymentStatus;

  Booking({
    this.bookingId,
    this.userId,
    this.stallId,
    this.bookingDate,
    this.startDate,
    this.endDate,
    this.status = 'pending',
    this.userName,
    this.userEmail,
    this.userPhone,
    this.stallNumber,
    this.stallSize,
    this.stallStatus,
    this.zoneName,
    this.paymentId,
    this.amount,
    this.paymentDate,
    this.paymentSlip,
    this.paymentStatus,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      bookingId: json['booking_id'],
      userId: json['user_id'],
      stallId: json['stall_id'],
      bookingDate: json['booking_date'],
      startDate: json['start_date'],
      endDate: json['end_date'],
      status: json['status'] ?? 'pending',
      userName: json['user_name'],
      userEmail: json['user_email'],
      userPhone: json['user_phone'],
      stallNumber: json['stall_number'],
      stallSize: json['stall_size'],
      stallStatus: json['stall_status'],
      zoneName: json['zone_name'],
      paymentId: json['payment_id'],
      amount: json['amount'] != null ? (json['amount']).toDouble() : null,
      paymentDate: json['payment_date'],
      paymentSlip: json['payment_slip'],
      paymentStatus: json['payment_status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'stall_id': stallId,
      'booking_date': bookingDate,
      'start_date': startDate,
      'end_date': endDate,
      'status': status,
    };
  }
}
