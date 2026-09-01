class Booking {
  final int? bookingId;
  final int? userId;
  final int? stallId;
  final String? rentalType;
  final double? dailyPrice;
  final double? monthlyPrice;
  final double? entryFee;
  final double? securityDeposit;
  final double? totalAmount;
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
  final String? rejectReason;
  final String? refundReason;
  final String? refundBankName;
  final String? refundAccountNumber;
  final String? refundAccountName;
  final String? refundSlip;
  final String? refundedAt;
  final bool hasElectricity;
  final bool hasWater;

  Booking({
    this.bookingId,
    this.userId,
    this.stallId,
    this.rentalType,
    this.dailyPrice,
    this.monthlyPrice,
    this.entryFee,
    this.securityDeposit,
    this.totalAmount,
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
    this.rejectReason,
    this.refundReason,
    this.refundBankName,
    this.refundAccountNumber,
    this.refundAccountName,
    this.refundSlip,
    this.refundedAt,
    this.hasElectricity = true,
    this.hasWater = true,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    double? parseDouble(dynamic val) {
      if (val == null) return null;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString());
    }

    int? parseInt(dynamic val) {
      if (val == null) return null;
      if (val is int) return val;
      return int.tryParse(val.toString());
    }

    bool parseBool(dynamic val, [bool fallback = true]) {
      if (val == null) return fallback;
      if (val is bool) return val;
      if (val is num) return val == 1;
      final str = val.toString().toLowerCase().trim();
      return str == '1' || str == 'true';
    }

    return Booking(
      bookingId: parseInt(json['booking_id']),
      userId: parseInt(json['user_id']),
      stallId: parseInt(json['stall_id']),
      rentalType: json['rental_type'] ?? json['stall_rental_type'] ?? 'daily',
      dailyPrice: parseDouble(json['daily_price']) ?? parseDouble(json['stall_daily_price']),
      monthlyPrice: parseDouble(json['monthly_price']) ?? parseDouble(json['stall_monthly_price']),
      entryFee: parseDouble(json['entry_fee']) ?? parseDouble(json['stall_entry_fee']),
      securityDeposit: parseDouble(json['security_deposit']) ?? parseDouble(json['stall_security_deposit']),
      totalAmount: parseDouble(json['total_amount']) ?? parseDouble(json['amount']),
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
      paymentId: parseInt(json['payment_id']),
      amount: parseDouble(json['amount']),
      paymentDate: json['payment_date'],
      paymentSlip: json['payment_slip'],
      paymentStatus: json['payment_status'],
      rejectReason: json['reject_reason'],
      refundReason: json['refund_reason'],
      refundBankName: json['refund_bank_name'],
      refundAccountNumber: json['refund_account_number'],
      refundAccountName: json['refund_account_name'],
      refundSlip: json['refund_slip'],
      refundedAt: json['refunded_at'],
      hasElectricity: parseBool(json['stall_has_electricity'] ?? json['has_electricity'], true),
      hasWater: parseBool(json['stall_has_water'] ?? json['has_water'], true),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'stall_id': stallId,
      'rental_type': rentalType,
      'daily_price': dailyPrice,
      'monthly_price': monthlyPrice,
      'entry_fee': entryFee,
      'security_deposit': securityDeposit,
      'total_amount': totalAmount,
      'booking_date': bookingDate,
      'start_date': startDate,
      'end_date': endDate,
      'status': status,
    };
  }

  bool get isApproved => status == 'approved';
  bool get isPending => status == 'pending' || status == 'pending_review';
  bool get isRenewalPending => status == 'renewal_pending';
  bool get isRefundRequested => status == 'refund_requested';
  bool get isRefunded => status == 'refunded';
  bool get isRejected => status == 'rejected' || status == 'cancelled';
  bool get isMonthly => rentalType == 'monthly';
}
