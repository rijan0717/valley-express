import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import '../core/api_client.dart';
import '../core/constants.dart';
import '../models/user.dart';

class AuthProvider with ChangeNotifier {
  final ApiClient _api = ApiClient();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  UserModel? _user;
  String? _token;
  bool _isLoading = false;

  UserModel? get user => _user;
  String? get token => _token;
  bool get isAuthenticated => _user != null && _token != null;
  bool get isLoading => _isLoading;

  Future<void> init() async {
    _token = await _storage.read(key: AppConstants.tokenKey);
    final userJson = await _storage.read(key: AppConstants.userKey);
    if (userJson != null) {
      _user = UserModel.fromJson(jsonDecode(userJson));
      notifyListeners();
    }
  }

  Future<bool> sendOtp(String phone) async {
    _isLoading = true;
    notifyListeners();
    try {
      final res = await _api.dio.post('/auth/send-otp', data: {'phone': phone});
      _isLoading = false;
      notifyListeners();
      return res.data['success'] == true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifyOtp(String phone, String otp, {String role = 'customer'}) async {
    _isLoading = true;
    notifyListeners();
    try {
      final res = await _api.dio.post('/auth/verify-otp', data: {
        'phone': phone,
        'otp': otp,
        'role': role,
      });

      if (res.data['success'] == true) {
        _token = res.data['token'];
        _user = UserModel.fromJson(res.data['user']);
        try {
          await _storage.write(key: AppConstants.tokenKey, value: _token);
          await _storage.write(key: AppConstants.userKey, value: jsonEncode(_user!.toJson()));
        } catch (_) {}
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('[verifyOtp Error] $e');
    }
    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> riderPasswordLogin(String loginId, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      final res = await _api.dio.post('/auth/rider-login', data: {
        'loginId': loginId,
        'password': password,
      });

      if (res.data['success'] == true) {
        _token = res.data['token'];
        _user = UserModel.fromJson(res.data['user']);
        try {
          await _storage.write(key: AppConstants.tokenKey, value: _token);
          await _storage.write(key: AppConstants.userKey, value: jsonEncode(_user!.toJson()));
        } catch (_) {}
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('[verifyOtp Error] $e');
    }
    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> confirmAge() async {
    if (_user == null) return;
    try {
      await _api.dio.put('/auth/profile', data: {'ageConfirmed': true});
      _user = UserModel(
        id: _user!.id,
        phone: _user!.phone,
        name: _user!.name,
        email: _user!.email,
        role: _user!.role,
        ageConfirmed: true,
        isOnline: _user!.isOnline,
        vehicleNumber: _user!.vehicleNumber,
      );
      await _storage.write(key: AppConstants.userKey, value: jsonEncode(_user!.toJson()));
      notifyListeners();
    } catch (_) {}
  }

  Future<void> toggleRiderOnline() async {
    if (_user == null || _user!.role != 'rider') return;
    try {
      final nextStatus = !_user!.isOnline;
      final res = await _api.dio.patch('/auth/rider/status', data: {'isOnline': nextStatus});
      if (res.data['success'] == true) {
        _user = UserModel(
          id: _user!.id,
          phone: _user!.phone,
          name: _user!.name,
          email: _user!.email,
          role: _user!.role,
          ageConfirmed: _user!.ageConfirmed,
          isOnline: nextStatus,
          vehicleNumber: _user!.vehicleNumber,
        );
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> logout() async {
    _user = null;
    _token = null;
    await _storage.deleteAll();
    notifyListeners();
  }
}
