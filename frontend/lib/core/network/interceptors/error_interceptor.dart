import 'package:dio/dio.dart';
import 'package:frontend/core/errors/app_exception.dart';

class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        error: AppException.fromDioError(err),
        type: err.type,
        response: err.response,
      ),
    );
  }
}
