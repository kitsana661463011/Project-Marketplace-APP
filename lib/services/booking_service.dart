import '../config/api_config.dart';
import '../models/booking.dart';
import 'api_service.dart';

class BookingService {
  static Future<List<Booking>> getBookings() async {
    final response = await ApiService.get(ApiConfig.bookings);
    if (response['status'] == true && response['data'] != null) {
      return (response['data'] as List)
          .map((json) => Booking.fromJson(json))
          .toList();
    }
    return [];
  }

  static Future<List<Booking>> getMyBookings(int userId) async {
    final bookings = await getBookings();
    return bookings.where((b) => b.userId == userId).toList();
  }

  static Future<Map<String, dynamic>> createBooking({
    required int userId,
    required int stallId,
    required String startDate,
    required String endDate,
  }) async {
    return await ApiService.post(ApiConfig.bookings, {
      'user_id': userId,
      'stall_id': stallId,
      'booking_date': DateTime.now().toIso8601String().split('T')[0],
      'start_date': startDate,
      'end_date': endDate,
      'status': 'pending',
    });
  }

  static Future<Booking?> getBooking(int id) async {
    final response = await ApiService.get('${ApiConfig.bookings}/$id');
    if (response['status'] == true && response['data'] != null) {
      return Booking.fromJson(response['data']);
    }
    return null;
  }
}
