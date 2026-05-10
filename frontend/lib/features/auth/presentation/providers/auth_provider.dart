import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/storage/secure_storage.dart';
import 'package:frontend/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:frontend/features/auth/data/sources/auth_remote_source.dart';
import 'package:frontend/features/auth/domain/repositories/auth_repository.dart';
import 'package:frontend/features/auth/presentation/providers/auth_state.dart';
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

    if (!await _storage.hasToken()) {
      return const AuthState(status: AuthStatus.unauthenticated);
    }

    try {
      final me = await _repository.getMe();
      return me.hasCompletedOnboarding
          ? AuthState(status: AuthStatus.authenticated, userId: me.userId)
          : AuthState(status: AuthStatus.onboarding, userId: me.userId);
    } catch (_) {
      await _storage.deleteToken();
      return const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> sendOtp(String phoneNumber) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.sendOtp(phoneNumber);
      return state.value ?? const AuthState(status: AuthStatus.unauthenticated);
    });
  }

  Future<bool> verifyOtp(String phoneNumber, String code) async {
    state = const AsyncValue.loading();
    bool success = false;
    state = await AsyncValue.guard(() async {
      final user = await _repository.verifyOtp(phoneNumber, code);
      await _storage.saveToken(user.token);
      success = true;
      return user.hasCompletedOnboarding
          ? AuthState(status: AuthStatus.authenticated, userId: user.userId)
          : AuthState(status: AuthStatus.onboarding, userId: user.userId);
    });
    return success;
  }

  Future<void> completeOnboarding() async {
    final current = state.value;
    if (current is! AuthState || current.status != AuthStatus.onboarding) {
      return;
    }
    await _repository.markOnboarded();
    state = AsyncData(
      AuthState(status: AuthStatus.authenticated, userId: current.userId),
    );
  }

  Future<void> logout() async {
    await _storage.deleteToken();

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

    state = const AsyncData(AuthState(status: AuthStatus.unauthenticated));
  }
}

final authProvider = AsyncNotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
