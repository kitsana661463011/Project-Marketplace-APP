import '../config/api_config.dart';
import '../models/booking.dart';
import 'api_service.dart';

class BookingService {
  static Future<List<Booking>> getBookings() async {
    try {
      final response = await ApiService.get(ApiConfig.bookings);
      if (response['status'] == true && response['data'] != null && response['data'] is List) {
        return (response['data'] as List)
            .map((json) => Booking.fromJson(json))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<List<Booking>> getMyBookings(int userId) async {
    try {
      // Try direct filter first (most efficient)
      final response = await ApiService.get('${ApiConfig.bookings}?user_id=$userId');
      if (response['status'] == true && response['data'] != null && response['data'] is List) {
        final list = (response['data'] as List)
            .map((json) => Booking.fromJson(json))
            .toList();
        if (list.isNotEmpty) return list;
      }
    } catch (_) {}

    // Fallback: fetch all and filter client-side
    try {
      final bookings = await getBookings();
      return bookings.where((b) => b.userId == userId).toList();
    } catch (_) {}

    return [];
  }

  static Future<Map<String, dynamic>> createBooking({
    required int userId,
    required int stallId,
    required String startDate,
    required String endDate,
    String? rentalType,
    double? dailyPrice,
    double? monthlyPrice,
    double? entryFee,
    double? securityDeposit,
    double? totalAmount,
  }) async {
    final payload = {
      'user_id': userId,
      'stall_id': stallId,
      'booking_date': DateTime.now().toIso8601String().split('T')[0],
      'start_date': startDate,
      'end_date': endDate,
      'status': 'pending',
    };
    if (rentalType != null) payload['rental_type'] = rentalType;
    if (dailyPrice != null) payload['daily_price'] = dailyPrice;
    if (monthlyPrice != null) payload['monthly_price'] = monthlyPrice;
    if (entryFee != null) payload['entry_fee'] = entryFee;
    if (securityDeposit != null) payload['security_deposit'] = securityDeposit;
    if (totalAmount != null) payload['total_amount'] = totalAmount;

    return await ApiService.post(ApiConfig.bookings, payload);
  }

  static Future<Booking?> getBooking(int id) async {
    try {
      final response = await ApiService.get('${ApiConfig.bookings}/$id');
      if (response['status'] == true && response['data'] != null) {
        return Booking.fromJson(response['data']);
      }
    } catch (_) {}
    return null;
  }

  static Future<Map<String, dynamic>> requestRefund({
    required int bookingId,
    required String refundReason,
    required String bankName,
    required String accountNumber,
    required String accountName,
  }) async {
    return await ApiService.put('${ApiConfig.bookings}/$bookingId/request-refund', {
      'refund_reason': refundReason,
      'refund_bank_name': bankName,
      'refund_account_number': accountNumber,
      'refund_account_name': accountName,
    });
  }
}
