import 'package:dio/dio.dart';

class AppException implements Exception {
  final String message;
  final int? statusCode;

  const AppException({required this.message, this.statusCode});

  factory AppException.fromDioError(DioException err) {
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
        return const AppException(message: 'Request timed out. Try again.');
      case DioExceptionType.connectionError:
        return const AppException(message: 'No internet connection.');
      case DioExceptionType.badResponse:
        final data = err.response?.data;
        final message = data is Map
            ? data['error'] ?? 'Something went wrong'
            : 'Something went wrong';
        return AppException(
          message: message,
          statusCode: err.response?.statusCode,
        );
      default:
        return const AppException(message: 'Something went wrong.');
    }
  }

  @override
  String toString() => message;
}
