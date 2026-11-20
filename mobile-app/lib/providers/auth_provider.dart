import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import '../core/api_client.dart';
import '../core/constants.dart';
import '../models/user.dart';

/// Outcome of an auth call. [fieldErrors] maps a form field name to the
/// message the API returned for it, so forms can mark the offending input
/// instead of only showing a banner.
class AuthResult {
  final bool success;
  final String message;
  final Map<String, String> fieldErrors;

  const AuthResult({
    required this.success,
    this.message = '',
    this.fieldErrors = const {},
  });
}

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

  /// Pulls a readable message and any per-field errors out of a Dio failure.
  AuthResult _failure(Object error, String fallback) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map) {
        return AuthResult(
          success: false,
          message: (data['message'] ?? fallback).toString(),
          fieldErrors: (data['errors'] is Map)
              ? (data['errors'] as Map).map(
                  (key, value) => MapEntry(key.toString(), value.toString()),
                )
              : const {},
        );
      }
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.connectionError) {
        return const AuthResult(
          success: false,
          message: 'Cannot reach Valley Express. Check your connection and try again.',
        );
      }
    }
    return AuthResult(success: false, message: fallback);
  }

  /// Stores the session. With [remember] false the token is kept in memory
  /// only, so closing the app signs the customer out.
  Future<void> _persistSession(
    Map<String, dynamic> data, {
    bool remember = true,
  }) async {
    _token = data['token'];
    _user = UserModel.fromJson(data['user']);
    if (!remember) {
      try {
        await _storage.deleteAll();
      } catch (_) {}
      return;
    }
    try {
      await _storage.write(key: AppConstants.tokenKey, value: _token);
      await _storage.write(key: AppConstants.userKey, value: jsonEncode(_user!.toJson()));
    } catch (_) {
      // Secure storage can be unavailable on some devices; the session still
      // works for the current run
    }
  }

  /// Creates a customer account. Email is the account identifier; a mobile
  /// number can be added later from the profile for SMS password resets.
  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
    bool rememberMe = true,
    String? phone,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final res = await _api.dio.post('/auth/register', data: {
        'name': name,
        'email': email.trim(),
        'password': password,
        if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
      });
      if (res.data['success'] == true) {
        await _persistSession(Map<String, dynamic>.from(res.data), remember: rememberMe);
        return AuthResult(success: true, message: res.data['message'] ?? 'Account created');
      }
      return AuthResult(success: false, message: res.data['message'] ?? 'Could not create account');
    } catch (e) {
      return _failure(e, 'Could not create your account. Please try again.');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Signs in with a password, using either a mobile number or an email.
  Future<AuthResult> loginWithPassword(String identifier, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      final res = await _api.dio.post('/auth/customer-login', data: {
        'identifier': identifier.trim(),
        'password': password,
      });
      if (res.data['success'] == true) {
        await _persistSession(Map<String, dynamic>.from(res.data));
        return AuthResult(success: true, message: res.data['message'] ?? 'Signed in');
      }
      return AuthResult(success: false, message: res.data['message'] ?? 'Sign in failed');
    } catch (e) {
      return _failure(e, 'Sign in failed. Please try again.');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Requests a password-reset code by SMS. Returns the dev-mode OTP in
  /// [AuthResult.message] context via [lastDevOtp] when the API supplies one.
  String? lastDevOtp;

  Future<AuthResult> forgotPassword(String phone) async {
    _isLoading = true;
    notifyListeners();
    try {
      final res = await _api.dio.post('/auth/forgot-password', data: {'phone': phone.trim()});
      lastDevOtp = res.data['devOtp']?.toString();
      return AuthResult(
        success: res.data['success'] == true,
        message: res.data['message'] ?? 'Reset code sent',
      );
    } catch (e) {
      return _failure(e, 'Could not send the reset code. Please try again.');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<AuthResult> resetPassword({
    required String phone,
    required String otp,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final res = await _api.dio.post('/auth/reset-password', data: {
        'phone': phone.trim(),
        'otp': otp.trim(),
        'password': password,
      });
      if (res.data['success'] == true) {
        await _persistSession(Map<String, dynamic>.from(res.data));
        return AuthResult(success: true, message: res.data['message'] ?? 'Password updated');
      }
      return AuthResult(success: false, message: res.data['message'] ?? 'Could not reset password');
    } catch (e) {
      return _failure(e, 'Could not reset your password. Please try again.');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Updates the signed-in customer's own details.
  Future<AuthResult> updateProfile({String? name, String? email}) async {
    _isLoading = true;
    notifyListeners();
    try {
      final res = await _api.dio.put('/auth/profile', data: {
        if (name != null) 'name': name.trim(),
        if (email != null) 'email': email.trim(),
      });
      if (res.data['success'] == true) {
        final updated = res.data['user'];
        if (updated != null && _user != null) {
          _user = UserModel(
            id: _user!.id,
            phone: updated['phone'] ?? _user!.phone,
            name: updated['name'] ?? _user!.name,
            email: updated['email'] ?? _user!.email,
            role: _user!.role,
            ageConfirmed: updated['ageConfirmed'] ?? _user!.ageConfirmed,
            isOnline: _user!.isOnline,
            vehicleNumber: _user!.vehicleNumber,
          );
          try {
            await _storage.write(
              key: AppConstants.userKey,
              value: jsonEncode(_user!.toJson()),
            );
          } catch (_) {}
        }
        return AuthResult(success: true, message: res.data['message'] ?? 'Profile updated');
      }
      return AuthResult(success: false, message: res.data['message'] ?? 'Could not update profile');
    } catch (e) {
      return _failure(e, 'Could not update your profile. Please try again.');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Changes the password for a signed-in customer.
  Future<AuthResult> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final res = await _api.dio.put('/auth/change-password', data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      });
      return AuthResult(
        success: res.data['success'] == true,
        message: res.data['message'] ?? 'Password updated',
      );
    } catch (e) {
      return _failure(e, 'Could not change your password. Please try again.');
    } finally {
      _isLoading = false;
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
