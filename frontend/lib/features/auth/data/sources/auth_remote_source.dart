import 'package:dio/dio.dart';
import 'package:frontend/features/auth/domain/models/auth_model.dart';

class AuthRemoteSource {
  final Dio _dio;
  AuthRemoteSource(this._dio);

  Future<void> sendOtp(String phoneNumber) async {
    await _dio.post(
      '/api/users/auth/send-otp/',
      data: {'phone_number': phoneNumber},
    );
  }

  Future<AuthModel> verifyOtp(String phoneNumber, String code) async {
    final response = await _dio.post(
      '/api/users/auth/verify-otp/',
      data: {'phone_number': phoneNumber, 'code': code},
    );

    return AuthModel.fromJson(response.data);
  }

  Future<MeModel> getMe() async {
    final response = await _dio.get('/api/users/auth/me/');
    return MeModel.fromJson(response.data);
  }

  Future<void> markOnboarded() async {
    await _dio.post('/api/users/auth/onboarded/');
  }
}
