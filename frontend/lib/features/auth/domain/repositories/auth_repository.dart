import 'package:frontend/features/auth/domain/models/auth_model.dart';

abstract class AuthRepository {
  Future<void> sendOtp(String phoneNumber);
  Future<AuthModel> verifyOtp(String phoneNumber, String code);
  Future<MeModel> getMe();
  Future<void> markOnboarded();
}
