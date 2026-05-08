import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/storage/secure_storage.dart';
import 'package:frontend/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:frontend/features/auth/data/sources/auth_remote_source.dart';
import 'package:frontend/features/auth/domain/models/auth_model.dart';
import 'package:frontend/features/auth/domain/repositories/auth_repository.dart';
import 'package:frontend/features/categories/presentation/providers/category_provider.dart';
import 'package:frontend/features/interactions/presentation/providers/upvote_provider.dart';
import 'package:frontend/features/notifications/presentation/providers/notification_provider.dart';
import 'package:frontend/features/profile/presentation/providers/profile_provider.dart';
import 'package:frontend/features/requests/presentation/providers/request_provider.dart';
import 'package:frontend/features/services/presentation/providers/service_provider.dart';
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
  final bool isNewUser;
  final int? userId;

  const AuthState({
    this.status = AuthStatus.initial,
    this.phoneNumber,
    this.user,
    this.isNewUser = false,
    this.userId,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? phoneNumber,
    AuthModel? user,
    bool? isNewUser,
    int? userId,
  }) {
    return AuthState(
      status: status ?? this.status,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      user: user ?? this.user,
      isNewUser: isNewUser ?? this.isNewUser,
      userId: userId ?? this.userId,
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

    ref.listen(unauthorizedEventProvider, (_, _) async {
      await logout();
    });

    final hasToken = await _storage.hasToken();

    if (hasToken) {
      final newUser = await _storage.isNewUser();
      final userId = await _storage.getUserId();
      return AuthState(status: AuthStatus.verified, isNewUser: newUser, userId: userId);
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
      await _storage.saveUserId(user.userId);
      if (user.isNewUser) await _storage.setNewUser();

      return AuthState(
        status: AuthStatus.verified,
        phoneNumber: phoneNumber,
        user: user,
        isNewUser: user.isNewUser,
        userId: user.userId,
      );
    });
  }

  void backToPhoneInput() {
    final current = state.value ?? const AuthState();
    state = AsyncData(current.copyWith(status: AuthStatus.initial));
  }

  Future<void> completeOnboarding() async {
    await _storage.clearNewUser();
    final current = state.value ?? const AuthState();
    state = AsyncData(current.copyWith(isNewUser: false));
  }

  Future<void> logout() async {
    await _storage.deleteToken();
    await _storage.deleteUserId();
    await _storage.clearNewUser();

    // Drop every cached user-data provider so the next signed-in user
    // starts from a clean slate.
    ref.invalidate(profileProvider);
    ref.invalidate(supportedLanguagesProvider);
    ref.invalidate(categoryProvider);
    ref.invalidate(subcategoryProvider);
    ref.invalidate(serviceProvider);
    ref.invalidate(myServiceProvider);
    ref.invalidate(allMyServicesProvider);
    ref.invalidate(serviceDetailProvider);
    ref.invalidate(editableServiceProvider);
    ref.invalidate(searchProvider);
    ref.invalidate(serviceFilterProvider);
    ref.invalidate(pendingRequestsProvider);
    ref.invalidate(historyRequestsProvider);
    ref.invalidate(pendingCountProvider);
    ref.invalidate(parentRequestsProvider);
    ref.invalidate(caregiverRequestProvider);
    ref.invalidate(notificationProvider);
    ref.invalidate(unreadCountProvider);
    ref.invalidate(upvoteProvider);

    state = const AsyncData(AuthState());
  }
}

final authProvider = AsyncNotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
