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

class AuthState {
  final bool isAuthenticated;
  final bool isNewUser;
  final int? userId;

  const AuthState({
    this.isAuthenticated = false,
    this.isNewUser = false,
    this.userId,
  });

  AuthState copyWith({bool? isAuthenticated, bool? isNewUser, int? userId}) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
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
      final isNewUser = await _storage.isNewUser();
      final userId = await _storage.getUserId();
      return AuthState(isAuthenticated: true, isNewUser: isNewUser, userId: userId);
    }

    return const AuthState();
  }

  Future<void> sendOtp(String phoneNumber) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.sendOtp(phoneNumber);
      return state.value ?? const AuthState();
    });
  }

  Future<bool> verifyOtp(String phoneNumber, String code) async {
    state = const AsyncValue.loading();
    bool success = false;
    state = await AsyncValue.guard(() async {
      final user = await _repository.verifyOtp(phoneNumber, code);
      await _storage.saveToken(user.token);
      await _storage.saveUserId(user.userId);
      if (user.isNewUser) await _storage.setNewUser();
      success = true;
      return AuthState(isAuthenticated: true, isNewUser: user.isNewUser, userId: user.userId);
    });
    return success;
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
