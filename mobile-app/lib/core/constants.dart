import 'package:flutter/foundation.dart' show kIsWeb;

class AppConstants {
  static const String appName = 'Valley Express';
  static const String appTagline = 'Fast Drinks, Snacks & Essentials Across Kathmandu Valley';

  // Base API configuration
  // On Web: connect to localhost:5000
  // On Android emulator: connect to 10.0.2.2:5000
  static String get baseUrl => kIsWeb ? 'http://localhost:5000/api' : 'http://10.0.2.2:5000/api';
  static String get socketUrl => kIsWeb ? 'http://localhost:5000' : 'http://10.0.2.2:5000';

  // Local storage keys
  static const String tokenKey = 'valley_jwt_token';
  static const String userKey = 'valley_user_profile';
  static const String ageConfirmedKey = 'valley_age_confirmed';

  // Pricing rules
  static const int defaultDeliveryFee = 100;
  static const int freeDeliveryThreshold = 1500;

  // Kathmandu defaults
  static const double defaultLat = 27.7172;
  static const double defaultLng = 85.3240;
}
