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
      _repository.getChildren(),
    ]);

    final cwsnProfile = results[0] as CwsnProfileModel;
    final children = results[2] as List<ChildProfileModel>;

    return ProfileState(
      cwsnProfile: cwsnProfile.copyWith(children: children),
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
      // Keep caregiver location in sync with CWSN profile location
      CaregiverProfileModel? updatedCaregiver = current.caregiverProfile;
      if (current.caregiverProfile != null &&
          data.containsKey('street_address')) {
        final locationData = {
          'street_address': data['street_address'],
          if (data.containsKey('latitude')) 'latitude': data['latitude'],
          if (data.containsKey('longitude')) 'longitude': data['longitude'],
        };
        updatedCaregiver = await _repository.updateCaregiverProfile(
          current.caregiverProfile!.id,
          locationData,
        );
      }
      return current.copyWith(
        cwsnProfile: updated,
        caregiverProfile: updatedCaregiver,
      );
    });
    ref.invalidate(myServiceProvider);
    ref.invalidate(serviceProvider);
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
    ref.invalidate(serviceProvider);
  }

  Future<void> deleteAccount() async {
    await _repository.deleteAccount();
    await ref.read(authProvider.notifier).logout();
  }

  Future<void> addChild(Map<String, dynamic> data) async {
    final current = state.value!;
    final newChild = await _repository.addChild(data);
    final updatedChildren = <ChildProfileModel>[
      ...(current.cwsnProfile?.children ?? []),
      newChild,
    ];
    state = AsyncData(
      current.copyWith(
        cwsnProfile: current.cwsnProfile?.copyWith(children: updatedChildren),
      ),
    );
  }

  Future<void> updateChild(int id, Map<String, dynamic> data) async {
    final current = state.value!;
    final updated = await _repository.updateChild(id, data);
    final updatedChildren = current.cwsnProfile!.children
        .map((c) => c.id == id ? updated : c)
        .toList();
    state = AsyncData(
      current.copyWith(
        cwsnProfile: current.cwsnProfile!.copyWith(children: updatedChildren),
      ),
    );
  }

  Future<void> deleteChild(int id) async {
    final current = state.value!;
    await _repository.deleteChild(id);
    final updatedChildren = current.cwsnProfile!.children
        .where((c) => c.id != id)
        .toList();
    state = AsyncData(
      current.copyWith(
        cwsnProfile: current.cwsnProfile!.copyWith(children: updatedChildren),
      ),
    );
  }
}

final profileProvider = AsyncNotifierProvider<ProfileNotifier, ProfileState>(
  ProfileNotifier.new,
);
