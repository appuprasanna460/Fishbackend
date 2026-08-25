import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../constants/api_constants.dart';
import '../utils/secure_storage.dart';

/// Global notifier — fires `true` whenever the backend responds with
/// SUBSCRIPTION_EXPIRED (403). The root widget listens and redirects.
final subscriptionExpiredNotifier = ValueNotifier<bool>(false);

class DioClient {
  late final Dio dio;

  DioClient() {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(
          milliseconds: ApiConstants.connectTimeout,
        ),
        receiveTimeout: const Duration(
          milliseconds: ApiConstants.receiveTimeout,
        ),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        validateStatus: (status) {
          return status != null && status >= 200 && status < 300;
        },
      ),
    );

    // Add interceptors
    dio.interceptors.add(_TokenInterceptor());

    // ✅ Enable detailed logging
    dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        error: true,
        logPrint: (obj) => debugPrint('🔵 DIO: $obj'),
      ),
    );

    // Add error handling interceptor
    dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) {
          debugPrint('🔴 DIO Error: ${error.message}');
          debugPrint('🔴 Response: ${error.response?.data}');
          debugPrint('🔴 Status: ${error.response?.statusCode}');

          // ── Subscription Expired ──────────────────────────────────────────
          // Backend returns 403 + { code: 'SUBSCRIPTION_EXPIRED' } from
          // the auth middleware when the subscription has lapsed.
          // Subscription-related routes are whitelisted in the middleware so
          // renewal flow still works — we only intercept non-subscription urls.
          if (error.response?.statusCode == 403) {
            final code = error.response?.data?['code'];
            final url = error.requestOptions.path;
            final isSubscriptionRoute = url.contains('/api/subscription');
            if (code == 'SUBSCRIPTION_EXPIRED' && !isSubscriptionRoute) {
              // Fire global notifier — the app router listener will navigate
              subscriptionExpiredNotifier.value =
                  !subscriptionExpiredNotifier.value;
            }
          }

          // ── Connection Timeouts ───────────────────────────────────────────
          if (error.type == DioExceptionType.connectionTimeout ||
              error.type == DioExceptionType.sendTimeout ||
              error.type == DioExceptionType.receiveTimeout) {
            return handler.reject(
              DioException(
                requestOptions: error.requestOptions,
                error: 'Connection timeout. Please check your network.',
              ),
            );
          }

          // ── Unauthorized ──────────────────────────────────────────────────
          if (error.response?.statusCode == 401) {
            SecureStorage.deleteAll();
          }

          handler.next(error);
        },
      ),
    );
  }
}

class _TokenInterceptor extends Interceptor {
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      final token = await SecureStorage.getToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
        debugPrint('🔑 Token added to request');
      } else {
        debugPrint('⚠️ No token found');
      }
    } catch (e) {
      debugPrint('❌ Error getting token: $e');
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      SecureStorage.deleteAll();
    }
    handler.next(err);
  }
}
