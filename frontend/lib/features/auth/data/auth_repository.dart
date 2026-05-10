import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/auth/domain/auth_models.dart';
import 'package:frontend/providers/core_providers.dart';

class AuthRepository {
  final Dio _dio;
  AuthRepository(this._dio);

  Future<void> sendOtp(String phoneNumber) =>
      _dio.post('/api/users/auth/send-otp/', data: {'phone_number': phoneNumber});

  Future<AuthSession> verifyOtp(String phoneNumber, String code) async {
    final response = await _dio.post(
      '/api/users/auth/verify-otp/',
      data: {'phone_number': phoneNumber, 'code': code},
    );
    return AuthSession.fromJson(response.data);
  }

  Future<MeData> getMe() async {
    final response = await _dio.get('/api/users/auth/me/');
    return MeData.fromJson(response.data);
  }

  Future<void> markOnboarded() => _dio.post('/api/users/auth/onboarded/');
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.read(dioProvider)),
);
