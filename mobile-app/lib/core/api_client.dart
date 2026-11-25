import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'constants.dart';

/// Turns a Dio failure into something worth showing a customer.
///
/// Interpolating the exception itself leaks the whole Dio diagnostic — for a
/// connection error on web that is a paragraph of CORS boilerplate, which is
/// both alarming and wrong: the browser cannot tell a refused connection from
/// a blocked one, so it reports the latter either way.
String friendlyApiError(Object error, String fallback) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map && data['message'] != null) {
      return data['message'].toString();
    }
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError) {
      return 'Cannot reach Valley Express. Check your connection and try again.';
    }
  }
  return fallback;
}

class ApiClient {
  late Dio dio;
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  ApiClient() {
    dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await storage.read(key: AppConstants.tokenKey);
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          // On a 401 the short-lived access token has likely expired. Try once
          // to renew it silently with the stored refresh token and replay the
          // original request, so the customer is not kicked back to the login
          // screen every hour. Only a failed refresh ends the session.
          final isAuthEndpoint =
              e.requestOptions.path.contains('/auth/refresh') ||
              e.requestOptions.path.contains('/auth/login') ||
              e.requestOptions.path.contains('/auth/verify-otp');
          final alreadyRetried = e.requestOptions.extra['__retried'] == true;

          if (e.response?.statusCode == 401 && !isAuthEndpoint && !alreadyRetried) {
            final newToken = await _refreshAccessToken();
            if (newToken != null) {
              try {
                final opts = e.requestOptions;
                opts.extra['__retried'] = true;
                opts.headers['Authorization'] = 'Bearer $newToken';
                final clone = await dio.fetch(opts);
                return handler.resolve(clone);
              } catch (_) {
                // fall through to the original error
              }
            }
          }
          return handler.next(e);
        },
      ),
    );
  }

  // Guards against several concurrent 401s each firing their own refresh.
  Future<String?>? _refreshing;

  Future<String?> _refreshAccessToken() {
    return _refreshing ??= _doRefresh().whenComplete(() => _refreshing = null);
  }

  Future<String?> _doRefresh() async {
    try {
      final refreshToken = await storage.read(key: AppConstants.refreshTokenKey);
      if (refreshToken == null || refreshToken.isEmpty) return null;
      // A bare Dio so this request does not re-enter the interceptor.
      final plain = Dio(BaseOptions(baseUrl: AppConstants.baseUrl));
      final res = await plain.post('/auth/refresh', data: {'refreshToken': refreshToken});
      if (res.data is Map && res.data['success'] == true && res.data['token'] != null) {
        await storage.write(key: AppConstants.tokenKey, value: res.data['token']);
        if (res.data['refreshToken'] != null) {
          await storage.write(
            key: AppConstants.refreshTokenKey,
            value: res.data['refreshToken'],
          );
        }
        return res.data['token'] as String;
      }
    } catch (_) {}
    return null;
  }
}
