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
  final String? rejectReason;
  final String? refundReason;
  final String? refundBankName;
  final String? refundAccountNumber;
  final String? refundAccountName;
  final String? refundSlip;
  final String? refundedAt;

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
    this.rejectReason,
    this.refundReason,
    this.refundBankName,
    this.refundAccountNumber,
    this.refundAccountName,
    this.refundSlip,
    this.refundedAt,
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
      rejectReason: json['reject_reason'],
      refundReason: json['refund_reason'],
      refundBankName: json['refund_bank_name'],
      refundAccountNumber: json['refund_account_number'],
      refundAccountName: json['refund_account_name'],
      refundSlip: json['refund_slip'],
      refundedAt: json['refunded_at'],
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

  bool get isApproved => status == 'approved';
  bool get isPending => status == 'pending' || status == 'pending_review';
  bool get isRenewalPending => status == 'renewal_pending';
  bool get isRefundRequested => status == 'refund_requested';
  bool get isRefunded => status == 'refunded';
  bool get isRejected => status == 'rejected' || status == 'cancelled';
}
