class ApiConfig {
  static const String baseUrl = 'http://10.0.2.2:8000/api';
  static const String webBaseUrl = 'http://localhost:8000/api';
  static const String imageBaseUrl = 'http://10.0.2.2:8000/api/images';
  static const String webImageBaseUrl = 'http://localhost:8000/api/images';

  static String get apiBaseUrl {
    return const bool.fromEnvironment('dart.library.html')
        ? webBaseUrl
        : baseUrl;
  }

  static String get apiImageUrl {
    return const bool.fromEnvironment('dart.library.html')
        ? webImageBaseUrl
        : imageBaseUrl;
  }

  static const String users = '/v1/users';
  static const String shops = '/v1/shops';
  static const String items = '/v1/items';
  static const String stalls = '/v1/stalls';
  static const String bookings = '/v1/bookings';
  static const String announcements = '/v1/admin/announcements';
  static const String shopReviews = '/v1/shop-reviews';
  static const String reviewReports = '/v1/review-reports';
}
