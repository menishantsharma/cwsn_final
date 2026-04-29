import 'package:frontend/features/auth/data/sources/auth_remote_source.dart';
import 'package:frontend/features/auth/domain/models/auth_model.dart';
import 'package:frontend/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteSource _source;
  AuthRepositoryImpl(this._source);

  @override
  Future<void> sendOtp(String phoneNumber) => _source.sendOtp(phoneNumber);

  @override
  Future<AuthModel> verifyOtp(String phoneNumber, String code) =>
      _source.verifyOtp(phoneNumber, code);
}
