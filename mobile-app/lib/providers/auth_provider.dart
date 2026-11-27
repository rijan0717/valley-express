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
    ApiClient.sessionToken = _token;
    final userJson = await _storage.read(key: AppConstants.userKey);
    if (userJson != null) {
      try {
        _user = UserModel.fromJson(jsonDecode(userJson));
        notifyListeners();
      } catch (_) {}
    }
    if (_token != null) {
      try {
        final res = await _api.dio.get('/auth/me');
        if (res.data is Map && res.data['success'] == true && res.data['user'] != null) {
          _user = UserModel.fromJson(res.data['user']);
          await _storage.write(key: AppConstants.userKey, value: jsonEncode(_user!.toJson()));
          notifyListeners();
        }
      } on DioException catch (e) {
        if (e.response?.statusCode == 401) {
          await logout();
        }
      } catch (_) {}
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
    // Held for this run even when the session is not persisted, so requests
    // stay signed after declining "remember me".
    ApiClient.sessionToken = _token;
    _user = UserModel.fromJson(data['user']);
    if (!remember) {
      try {
        await _storage.deleteAll();
      } catch (_) {}
      return;
    }
    try {
      await _storage.write(key: AppConstants.tokenKey, value: _token);
      if (data['refreshToken'] != null) {
        await _storage.write(
          key: AppConstants.refreshTokenKey,
          value: data['refreshToken'].toString(),
        );
      }
      await _storage.write(key: AppConstants.userKey, value: jsonEncode(_user!.toJson()));
    } catch (_) {
      // Secure storage can be unavailable on some devices; the session still
      // works for the current run
    }
  }

  /// Creates a customer account, identified by a mobile number or an email —
  /// the sign-up form collects a mobile, and an email can be added later from
  /// the profile. [ageConfirmed] records the 18+ declaration, which the API
  /// requires before it will open an account.
  Future<AuthResult> register({
    required String name,
    required String password,
    required bool ageConfirmed,
    bool rememberMe = true,
    String? email,
    String? phone,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final res = await _api.dio.post('/auth/register', data: {
        'name': name,
        'password': password,
        'ageConfirmed': ageConfirmed,
        if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
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
  Future<AuthResult> loginWithPassword(
    String identifier,
    String password, {
    bool rememberMe = true,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final res = await _api.dio.post('/auth/customer-login', data: {
        'identifier': identifier.trim(),
        'password': password,
      });
      if (res.data['success'] == true) {
        await _persistSession(Map<String, dynamic>.from(res.data), remember: rememberMe);
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
            avatarUrl: updated['avatarUrl'] ?? _user!.avatarUrl,
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

  /// Sets the profile photo and saves it to the account.
  ///
  /// The local copy is updated first so the new picture shows immediately,
  /// then it is persisted server-side — it used to be written only to device
  /// storage, so a reinstall or a second device lost it.
  Future<AuthResult> updateAvatar(String url) async {
    if (_user == null) {
      return const AuthResult(success: false, message: 'Sign in to change your photo');
    }

    final previous = _user;
    _user = _user!.copyWith(avatarUrl: url);
    notifyListeners();

    try {
      await _storage.write(
        key: AppConstants.userKey,
        value: jsonEncode(_user!.toJson()),
      );
    } catch (_) {}

    try {
      final res = await _api.dio.put('/auth/profile', data: {'avatarUrl': url});
      if (res.data['success'] == true) {
        return AuthResult(success: true, message: res.data['message'] ?? 'Photo updated');
      }
      // Put the old picture back rather than showing one the server rejected.
      _user = previous;
      notifyListeners();
      return AuthResult(success: false, message: res.data['message'] ?? 'Could not save your photo');
    } catch (e) {
      _user = previous;
      notifyListeners();
      return _failure(e, 'Could not save your photo. Please try again.');
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
          if (res.data['refreshToken'] != null) {
            await _storage.write(
              key: AppConstants.refreshTokenKey,
              value: res.data['refreshToken'].toString(),
            );
          }
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

  Future<bool> riderPasswordLogin(
    String loginId,
    String password, {
    bool rememberMe = true,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final res = await _api.dio.post('/auth/rider-login', data: {
        'loginId': loginId.trim(),
        'password': password,
      });

      if (res.data['success'] == true) {
        await _persistSession(Map<String, dynamic>.from(res.data), remember: rememberMe);
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('[riderPasswordLogin Error] $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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
        // copyWith rather than rebuilding field by field: the old version
        // listed the fields it knew about, so anything added later (the
        // profile photo, for one) was dropped on every duty toggle.
        _user = _user!.copyWith(isOnline: nextStatus);
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> logout() async {
    _user = null;
    _token = null;
    // Revoke the refresh token on the server so it cannot be reused, before it
    // is wiped from device storage below. Fire-and-forget — logout proceeds
    // locally regardless of whether the call succeeds.
    try {
      final refreshToken = await _storage.read(key: AppConstants.refreshTokenKey);
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await _api.dio.post('/auth/logout', data: {'refreshToken': refreshToken});
      }
    } catch (_) {}
    ApiClient.sessionToken = null;
    // deleteAll would take the remembered credentials with the session, so
    // they are read back and rewritten when "remember me" is still set.
    String? remembered;
    String? identifier;
    String? password;
    try {
      remembered = await _storage.read(key: AppConstants.rememberMeKey);
      if (remembered == 'true') {
        identifier = await _storage.read(key: AppConstants.rememberedIdentifierKey);
        password = await _storage.read(key: AppConstants.rememberedPasswordKey);
      }
    } catch (_) {}
    await _storage.deleteAll();
    if (remembered == 'true') {
      try {
        await _storage.write(key: AppConstants.rememberMeKey, value: 'true');
        if (identifier != null) {
          await _storage.write(key: AppConstants.rememberedIdentifierKey, value: identifier);
        }
        if (password != null) {
          await _storage.write(key: AppConstants.rememberedPasswordKey, value: password);
        }
      } catch (_) {}
    }
    notifyListeners();
  }
}
