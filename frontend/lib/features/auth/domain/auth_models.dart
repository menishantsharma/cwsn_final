class AuthSession {
  final String token;
  final int userId;
  final bool hasCompletedOnboarding;

  const AuthSession({
    required this.token,
    required this.userId,
    required this.hasCompletedOnboarding,
  });

  factory AuthSession.fromJson(Map<String, dynamic> j) => AuthSession(
        token: j['token'] as String,
        userId: j['user_id'] as int,
        hasCompletedOnboarding: j['has_completed_onboarding'] ?? false,
      );
}

class MeData {
  final int userId;
  final bool hasCompletedOnboarding;

  const MeData({required this.userId, required this.hasCompletedOnboarding});

  factory MeData.fromJson(Map<String, dynamic> j) => MeData(
        userId: j['user_id'] as int,
        hasCompletedOnboarding: j['has_completed_onboarding'] ?? false,
      );
}
