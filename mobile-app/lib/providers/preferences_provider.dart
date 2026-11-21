import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// On-device customer preferences. These are deliberately local: none of them
/// need to follow the account across devices, and keeping them off the server
/// means no extra round trip when the profile screen opens.
class PreferencesProvider extends ChangeNotifier {
  static const _locationKey = 'valley_pref_location_sharing';
  static const _notificationsKey = 'valley_pref_order_notifications';
  static const _nepaliNamesKey = 'valley_pref_nepali_names';
  static const _darkModeKey = 'valley_pref_dark_mode';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  bool _locationSharing = true;
  bool _orderNotifications = true;
  bool _showNepaliNames = true;
  bool _darkMode = false;
  bool _loaded = false;

  bool get locationSharing => _locationSharing;
  bool get orderNotifications => _orderNotifications;
  bool get showNepaliNames => _showNepaliNames;
  bool get isDarkMode => _darkMode;
  bool get isLoaded => _loaded;

  Future<void> load() async {
    try {
      final location = await _storage.read(key: _locationKey);
      final notifications = await _storage.read(key: _notificationsKey);
      final nepali = await _storage.read(key: _nepaliNamesKey);
      final dark = await _storage.read(key: _darkModeKey);
      _locationSharing = location != 'false';
      _orderNotifications = notifications != 'false';
      _showNepaliNames = nepali != 'false';
      _darkMode = dark == 'true';
    } catch (_) {
      // Secure storage can be unavailable; fall back to the defaults above
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> _write(String key, bool value) async {
    try {
      await _storage.write(key: key, value: value.toString());
    } catch (_) {
      // Preference is still applied for this run
    }
  }

  Future<void> setLocationSharing(bool value) async {
    _locationSharing = value;
    notifyListeners();
    await _write(_locationKey, value);
  }

  Future<void> setOrderNotifications(bool value) async {
    _orderNotifications = value;
    notifyListeners();
    await _write(_notificationsKey, value);
  }

  Future<void> setShowNepaliNames(bool value) async {
    _showNepaliNames = value;
    notifyListeners();
    await _write(_nepaliNamesKey, value);
  }

  Future<void> setDarkMode(bool value) async {
    _darkMode = value;
    notifyListeners();
    await _write(_darkModeKey, value);
  }
}
