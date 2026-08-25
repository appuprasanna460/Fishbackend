import 'package:dio/dio.dart';
import '../utils/secure_storage.dart';

class TokenInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await SecureStorage.getToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      // Handle unauthorized: Clear token to force logout
      SecureStorage.deleteAll();
      // Future improvement: Trigger a global stream to redirect to login
    }
    super.onError(err, handler);
  }
}
