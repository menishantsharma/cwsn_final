import 'package:dio/dio.dart';
import 'package:frontend/core/network/interceptors/auth_interceptor.dart';
import 'package:frontend/core/network/interceptors/error_interceptor.dart';
import 'package:frontend/core/storage/secure_storage.dart';

class DioClient {
  late final Dio dio;

  DioClient(SecureStorage storage, {Future<void> Function()? onUnauthorized}) {
    dio = Dio(
      BaseOptions(
        baseUrl: 'http://103.21.126.116:9000',
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    dio.interceptors.addAll([
      AuthInterceptor(storage, onUnauthorized: onUnauthorized),
      ErrorInterceptor(),
      LogInterceptor(requestBody: true, responseBody: true),
    ]);
  }
}
