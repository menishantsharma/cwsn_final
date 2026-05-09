import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/storage/secure_storage.dart';
import 'package:frontend/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:frontend/features/auth/data/sources/auth_remote_source.dart';
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

sealed class AuthState {
  const AuthState();
}

class Unauthenticated extends AuthState {
  const Unauthenticated();
}

class NeedsOnboarding extends AuthState {
  final int userId;
  const NeedsOnboarding(this.userId);
}

class Authenticated extends AuthState {
  final int userId;
  const Authenticated(this.userId);
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

    if (!await _storage.hasToken()) return const Unauthenticated();

    try {
      final me = await _repository.getMe();
      return me.hasCompletedOnboarding
          ? Authenticated(me.userId)
          : NeedsOnboarding(me.userId);
    } catch (_) {
      // /me failed (token invalid, network down, etc.). Force re-login.
      await _storage.deleteToken();
      return const Unauthenticated();
    }
  }

  Future<void> sendOtp(String phoneNumber) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.sendOtp(phoneNumber);
      return state.value ?? const Unauthenticated();
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
          ? Authenticated(user.userId)
          : NeedsOnboarding(user.userId);
    });
    return success;
  }

  Future<void> completeOnboarding() async {
    final current = state.value;
    if (current is! NeedsOnboarding) return;
    await _repository.markOnboarded();
    state = AsyncData(Authenticated(current.userId));
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

    state = const AsyncData(Unauthenticated());
  }
}

final authProvider = AsyncNotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
