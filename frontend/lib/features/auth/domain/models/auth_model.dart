class AuthModel {
  final String token;
  final int userId;
  final bool isNewUser;
  final bool isCwsnUser;
  final bool isCaregiver;

  AuthModel({required this.token, required this.userId, required this.isNewUser, required this.isCwsnUser, required this.isCaregiver});

  factory AuthModel.fromJson(Map<String, dynamic> json) {
    return AuthModel(
      token: json['token'],
      userId: json['user_id'],
      isNewUser: json['is_new_user'],
      isCwsnUser: json['is_cwsn_user'],
      isCaregiver: json['is_caregiver'],
    );
  }
}
