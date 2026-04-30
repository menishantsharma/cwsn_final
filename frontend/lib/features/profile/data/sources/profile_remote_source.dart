import 'package:dio/dio.dart';
import 'package:frontend/features/profile/domain/models/profile_model.dart';

class ProfileRemoteSource {
  final Dio _dio;

  ProfileRemoteSource(this._dio);

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

  Future<CwsnProfileModel> updateCwsnProfile(
    int id,
    Map<String, dynamic> data,
  ) async {
    final response = await _dio.patch(
      '/api/users/cwsn-profiles/$id/',
      data: data,
    );
    return CwsnProfileModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<CaregiverProfileModel> updateCaregiverProfile(
    int id,
    Map<String, dynamic> data,
  ) async {
    final response = await _dio.patch(
      '/api/users/caregiver-profiles/$id/',
      data: data,
    );
    return CaregiverProfileModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<void> deleteAccount() async {
    await _dio.delete('/api/users/delete-account/');
  }

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

  Future<ChildProfileModel> updateChild(
    int id,
    Map<String, dynamic> data,
  ) async {
    final response = await _dio.patch(
      '/api/users/child-profiles/$id/',
      data: data,
    );
    return ChildProfileModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteChild(int id) async {
    await _dio.delete('/api/users/child-profiles/$id/');
  }
}
