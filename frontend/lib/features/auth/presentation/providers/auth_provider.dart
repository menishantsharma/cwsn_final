import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/storage/secure_storage.dart';
import 'package:frontend/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:frontend/features/auth/data/sources/auth_remote_source.dart';
import 'package:frontend/features/auth/domain/models/auth_model.dart';
import 'package:frontend/features/auth/domain/repositories/auth_repository.dart';
import 'package:frontend/providers/core_providers.dart';

final authRemoteSourceProvider = Provider<AuthRemoteSource>(
  (ref) => AuthRemoteSource(ref.read(dioProvider)),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(ref.read(authRemoteSourceProvider)),
);

enum AuthStatus { initial, otpSent, verified }

class AuthState {
  final AuthStatus status;
  final String? phoneNumber;
  final AuthModel? user;

  const AuthState({
    this.status = AuthStatus.initial,
    this.phoneNumber,
    this.user,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? phoneNumber,
    AuthModel? user,
  }) {
    return AuthState(
      status: status ?? this.status,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      user: user ?? this.user,
    );
  }
}

class AuthNotifier extends AsyncNotifier<AuthState> {
  late AuthRepository _repository;
  late SecureStorage _storage;

  @override
  Future<AuthState> build() async {
    _repository = ref.read(authRepositoryProvider);
    _storage = ref.read(secureStorageProvider);

    final hasToken = await _storage.hasToken();

    if (hasToken) {
      return AuthState(status: AuthStatus.verified);
    }

    return const AuthState();
  }

  Future<void> sendOtp(String phoneNumber) async {
    final current = state.value ?? const AuthState();
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      await _repository.sendOtp(phoneNumber);
      return current.copyWith(
        status: AuthStatus.otpSent,
        phoneNumber: phoneNumber,
      );
    });
  }

  Future<void> verifyOtp(String code) async {
    final phoneNumber = state.value?.phoneNumber;
    if (phoneNumber == null || phoneNumber.isEmpty) {
      state = AsyncError(
        Exception('Session expired. Please re-enter your phone number.'),
        StackTrace.current,
      );
      return;
    }

    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      final user = await _repository.verifyOtp(phoneNumber, code);
      await _storage.saveToken(user.token);

      return AuthState(
        status: AuthStatus.verified,
        phoneNumber: phoneNumber,
        user: user,
      );
    });
  }

  Future<void> logout() async {
    await _storage.deleteToken();
    state = const AsyncData(AuthState());
  }
}

final authProvider = AsyncNotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
