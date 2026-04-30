import 'package:frontend/features/profile/domain/models/profile_model.dart';

abstract class ProfileRepository {
  Future<CwsnProfileModel> getCwsnProfile();
  Future<CaregiverProfileModel> getCaregiverProfile();
  Future<CwsnProfileModel> updateCwsnProfile(int id, Map<String, dynamic> data);
  Future<CaregiverProfileModel> updateCaregiverProfile(
    int id,
    Map<String, dynamic> data,
  );
  Future<void> deleteAccount();
}
