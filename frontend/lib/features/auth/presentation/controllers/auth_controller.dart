import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/storage/secure_storage.dart';
import 'package:frontend/features/auth/data/auth_repository.dart';
import 'package:frontend/providers/core_providers.dart';

enum AuthStatus { unauthenticated, onboarding, authenticated }

class AuthState {
  final AuthStatus status;
  final int? userId;

  const AuthState._(this.status, this.userId);

  const AuthState.unauthenticated() : this._(AuthStatus.unauthenticated, null);
  const AuthState.onboarding(int userId) : this._(AuthStatus.onboarding, userId);
  const AuthState.authenticated(int userId)
      : this._(AuthStatus.authenticated, userId);
}

class AuthNotifier extends AsyncNotifier<AuthState> {
  AuthRepository get _repo => ref.read(authRepositoryProvider);
  SecureStorage get _storage => ref.read(secureStorageProvider);

  // Holds the verificationId between sendOtp and verifyOtp calls.
  String? _verificationId;

  @override
  Future<AuthState> build() async {
    ref.listen(unauthorizedEventProvider, (_, _) => logout());

    if (!await _storage.hasToken()) return const AuthState.unauthenticated();

    try {
      final me = await _repo.getMe();
      return me.hasCompletedOnboarding
          ? AuthState.authenticated(me.userId)
          : AuthState.onboarding(me.userId);
    } catch (_) {
      await _storage.deleteToken();
      return const AuthState.unauthenticated();
    }
  }

  /// Sends OTP via Firebase. Throws on failure.
  Future<void> sendOtp(String phoneNumber) async {
    final previous = state.value ?? const AuthState.unauthenticated();
    state = const AsyncLoading();
    try {
      _verificationId = await _repo.sendOtp(phoneNumber);
      state = AsyncData(previous);
    } catch (_) {
      state = AsyncData(previous);
      rethrow;
    }
  }

  /// Verifies the SMS code. Throws on failure so UI can show error.
  Future<void> verifyOtp(String smsCode) async {
    final verificationId = _verificationId;
    if (verificationId == null) throw 'No verification in progress. Please request a new OTP.';

    final previous = state.value ?? const AuthState.unauthenticated();
    state = const AsyncLoading();
    try {
      final session = await _repo.verifyOtp(verificationId, smsCode);
      await _storage.saveToken(session.token);
      state = AsyncData(session.hasCompletedOnboarding
          ? AuthState.authenticated(session.userId)
          : AuthState.onboarding(session.userId));
    } catch (e) {
      state = AsyncData(previous);
      rethrow;
    }
  }

  Future<void> completeOnboarding() async {
    final current = state.value;
    if (current == null || current.status != AuthStatus.onboarding) return;
    await _repo.markOnboarded();
    state = AsyncData(AuthState.authenticated(current.userId!));
  }

  /// Other feature providers self-clear via [RefAuthAware.clearOnLogout].
  Future<void> logout() async {
    await _storage.deleteToken();
    state = const AsyncData(AuthState.unauthenticated());
  }
}

final authProvider = AsyncNotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

/// Add `ref.clearOnLogout()` at the top of any feature provider's build or
/// `(ref) { ... }` callback to make it self-invalidate when the user logs out.
extension RefAuthAware on Ref {
  void clearOnLogout() {
    listen(authProvider, (_, next) {
      if (next.value?.status == AuthStatus.unauthenticated) {
        invalidateSelf();
      }
    });
  }
}
