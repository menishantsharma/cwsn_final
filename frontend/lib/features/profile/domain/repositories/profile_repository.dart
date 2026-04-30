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
  Future<List<ChildProfileModel>> getChildren();
  Future<ChildProfileModel> addChild(Map<String, dynamic> data);
  Future<ChildProfileModel> updateChild(int id, Map<String, dynamic> data);
  Future<void> deleteChild(int id);
}
