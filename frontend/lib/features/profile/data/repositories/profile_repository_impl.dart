import 'package:frontend/features/profile/data/sources/profile_remote_source.dart';
import 'package:frontend/features/profile/domain/models/profile_model.dart';
import 'package:frontend/features/profile/domain/repositories/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteSource _remoteSource;

  ProfileRepositoryImpl(this._remoteSource);

  @override
  Future<CwsnProfileModel> getCwsnProfile() => _remoteSource.getCwsnProfile();

  @override
  Future<CaregiverProfileModel> getCaregiverProfile() =>
      _remoteSource.getCaregiverProfile();

  @override
  Future<CwsnProfileModel> updateCwsnProfile(
    int id,
    Map<String, dynamic> data,
  ) => _remoteSource.updateCwsnProfile(id, data);

  @override
  Future<CaregiverProfileModel> updateCaregiverProfile(
    int id,
    Map<String, dynamic> data,
  ) => _remoteSource.updateCaregiverProfile(id, data);

  @override
  Future<void> deleteAccount() => _remoteSource.deleteAccount();
}
