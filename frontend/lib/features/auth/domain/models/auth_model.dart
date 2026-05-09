class AuthModel {
  final String token;
  final int userId;
  final bool hasCompletedOnboarding;
  final bool isCwsnUser;
  final bool isCaregiver;

  AuthModel({
    required this.token,
    required this.userId,
    required this.hasCompletedOnboarding,
    required this.isCwsnUser,
    required this.isCaregiver,
  });

  factory AuthModel.fromJson(Map<String, dynamic> json) {
    return AuthModel(
      token: json['token'],
      userId: json['user_id'],
      hasCompletedOnboarding: json['has_completed_onboarding'] ?? false,
      isCwsnUser: json['is_cwsn_user'],
      isCaregiver: json['is_caregiver'],
    );
  }
}

class MeModel {
  final int userId;
  final bool hasCompletedOnboarding;
  final bool isCwsnUser;
  final bool isCaregiver;

  MeModel({
    required this.userId,
    required this.hasCompletedOnboarding,
    required this.isCwsnUser,
    required this.isCaregiver,
  });

  factory MeModel.fromJson(Map<String, dynamic> json) {
    return MeModel(
      userId: json['user_id'],
      hasCompletedOnboarding: json['has_completed_onboarding'] ?? false,
      isCwsnUser: json['is_cwsn_user'] ?? false,
      isCaregiver: json['is_caregiver'] ?? false,
    );
  }
}
