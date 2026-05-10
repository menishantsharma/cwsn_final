enum AuthStatus { authenticated, unauthenticated, onboarding }

class AuthState {
  final int? userId;
  final AuthStatus status;

  const AuthState({required this.status, this.userId});

  AuthState copyWith({AuthStatus? status, int? userId}) {
    return AuthState(
      status: status ?? this.status,
      userId: userId ?? this.userId,
    );
  }
}
