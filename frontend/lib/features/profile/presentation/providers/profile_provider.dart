import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/auth/presentation/providers/auth_provider.dart';
import 'package:frontend/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:frontend/features/profile/data/sources/profile_remote_source.dart';
import 'package:frontend/features/profile/domain/models/profile_model.dart';
import 'package:frontend/features/profile/domain/repositories/profile_repository.dart';
import 'package:frontend/features/services/presentation/providers/service_provider.dart';
import 'package:frontend/providers/core_providers.dart';

final profileRemoteSourceProvider = Provider<ProfileRemoteSource>(
  (ref) => ProfileRemoteSource(ref.read(dioProvider)),
);

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepositoryImpl(ref.read(profileRemoteSourceProvider)),
);

class ProfileState {
  final CwsnProfileModel? cwsnProfile;
  final CaregiverProfileModel? caregiverProfile;

  const ProfileState({this.cwsnProfile, this.caregiverProfile});

  ProfileState copyWith({
    CwsnProfileModel? cwsnProfile,
    CaregiverProfileModel? caregiverProfile,
  }) {
    return ProfileState(
      cwsnProfile: cwsnProfile ?? this.cwsnProfile,
      caregiverProfile: caregiverProfile ?? this.caregiverProfile,
    );
  }
}

class ProfileNotifier extends AsyncNotifier<ProfileState> {
  late ProfileRepository _repository;

  @override
  Future<ProfileState> build() async {
    _repository = ref.read(profileRepositoryProvider);
    final results = await Future.wait([
      _repository.getCwsnProfile(),
      _repository.getCaregiverProfile(),
    ]);
    return ProfileState(
      cwsnProfile: results[0] as CwsnProfileModel,
      caregiverProfile: results[1] as CaregiverProfileModel,
    );
  }

  Future<void> updateCwsnProfile(Map<String, dynamic> data) async {
    final current = state.value!;
    state = await AsyncValue.guard(() async {
      final updated = await _repository.updateCwsnProfile(
        current.cwsnProfile!.id,
        data,
      );
      return current.copyWith(cwsnProfile: updated);
    });
    ref.invalidate(myServiceProvider);
  }

  Future<void> updateCaregiverProfile(Map<String, dynamic> data) async {
    final current = state.value!;
    state = await AsyncValue.guard(() async {
      final updated = await _repository.updateCaregiverProfile(
        current.caregiverProfile!.id,
        data,
      );
      return current.copyWith(caregiverProfile: updated);
    });
    ref.invalidate(myServiceProvider);
  }

  Future<void> deleteAccount() async {
    await _repository.deleteAccount();
    await ref.read(authProvider.notifier).logout();
  }
}

final profileProvider = AsyncNotifierProvider<ProfileNotifier, ProfileState>(
  ProfileNotifier.new,
);
