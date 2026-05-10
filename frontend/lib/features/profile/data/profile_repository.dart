import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/profile/domain/profile_models.dart';
import 'package:frontend/providers/core_providers.dart';

class ProfileRepository {
  final Dio _dio;
  ProfileRepository(this._dio);

  Future<CwsnProfileModel> getCwsnProfile() async {
    final response = await _dio.get('/api/users/cwsn-profiles/');
    final results = response.data['results'] as List;
    return CwsnProfileModel.fromJson(results[0] as Map<String, dynamic>);
  }

  Future<CaregiverProfileModel> getCaregiverProfile() async {
    final response = await _dio.get(
      '/api/users/caregiver-profiles/',
      queryParameters: {'mine': 'true'},
    );
    final data = response.data;
    final list = data is List ? data : data['results'] as List;
    return CaregiverProfileModel.fromJson(list[0] as Map<String, dynamic>);
  }

  Future<CwsnProfileModel> updateCwsnProfile(int id, Map<String, dynamic> data) async {
    final response = await _dio.patch('/api/users/cwsn-profiles/$id/', data: data);
    return CwsnProfileModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<CaregiverProfileModel> updateCaregiverProfile(int id, Map<String, dynamic> data) async {
    final response = await _dio.patch('/api/users/caregiver-profiles/$id/', data: data);
    return CaregiverProfileModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<Map<String, dynamic>>> getSupportedLanguages() async {
    final response = await _dio.get('/api/common/languages/');
    final list = response.data is List
        ? response.data as List
        : response.data['results'] as List;
    return list.cast<Map<String, dynamic>>();
  }

  Future<void> changePhoneRequest(String newPhoneNumber) =>
      _dio.post('/api/users/change-phone/request/', data: {'new_phone_number': newPhoneNumber});

  Future<void> changePhoneConfirm(String newPhoneNumber, String code) =>
      _dio.post('/api/users/change-phone/confirm/', data: {'new_phone_number': newPhoneNumber, 'code': code});

  Future<void> deleteAccount() => _dio.delete('/api/users/delete-account/');

  Future<List<ChildProfileModel>> getChildren() async {
    final response = await _dio.get('/api/users/child-profiles/');
    final list = response.data is List
        ? response.data as List
        : response.data['results'] as List;
    return list
        .map((e) => ChildProfileModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ChildProfileModel> addChild(Map<String, dynamic> data) async {
    final response = await _dio.post('/api/users/child-profiles/', data: data);
    return ChildProfileModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ChildProfileModel> updateChild(int id, Map<String, dynamic> data) async {
    final response = await _dio.patch('/api/users/child-profiles/$id/', data: data);
    return ChildProfileModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteChild(int id) => _dio.delete('/api/users/child-profiles/$id/');
}

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(ref.read(dioProvider)),
);
