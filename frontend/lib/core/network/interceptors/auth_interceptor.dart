import 'package:dio/dio.dart';
import 'package:frontend/core/storage/secure_storage.dart';

class AuthInterceptor extends Interceptor {
  final SecureStorage _storage;
  final Future<void> Function()? onUnauthorized;

  AuthInterceptor(this._storage, {this.onUnauthorized});

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.getToken();
    if (token != null) {
      options.headers['Authorization'] = 'Token $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      await _storage.deleteToken();
      await _storage.deleteUserId();
      await _storage.clearNewUser();
      await onUnauthorized?.call();
    }
    handler.next(err);
  }
}
