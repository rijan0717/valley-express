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

  /// The token for the current run, held in memory.
  ///
  /// Declining "remember me" deliberately keeps the session out of secure
  /// storage, but the request interceptor read the token from storage alone,
  /// so every authenticated call went out unsigned and came back 401 for the
  /// rest of that run. Holding it here keeps the session working without
  /// writing anything that would survive a restart.
  static String? sessionToken;

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
          final token =
              sessionToken ?? await storage.read(key: AppConstants.tokenKey);
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) {
          return handler.next(e);
        },
      ),
    );
  }
}
