import 'package:dio/dio.dart';
import 'package:frontend/core/pagination/paginated_state.dart';
import 'package:frontend/features/services/domain/models/service_model.dart';

class ServiceRemoteSource {
  final Dio _dio;

  ServiceRemoteSource(this._dio);

  Future<PagedResponse<ServiceModel>> getServices({
    required int categoryId,
    required int subCategoryId,
    String? serviceType,
    String? paymentType,
    String? targetGender,
    String? caregiverGender,
    int? childAge,
    int? distanceKm,
    int page = 1,
  }) async {
    final params = <String, dynamic>{
      'category': categoryId,
      'sub_category': subCategoryId,
      'service_type': serviceType,
      'payment_type': paymentType,
      'target_gender': targetGender,
      'caregiver_gender': caregiverGender,
      'child_age': childAge,
      'distance_km': distanceKm,
      'page': page,
    }..removeWhere((_, v) => v == null);

    final res = await _dio.get(
      '/api/services/services/',
      queryParameters: params,
    );

    final results = res.data['results'] as List<dynamic>;
    return PagedResponse(
      results: results
          .map((e) => ServiceModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      hasMore: res.data['next'] != null,
    );
  }

  Future<PagedResponse<ServiceModel>> getAllMyServices({int page = 1}) async {
    final res = await _dio.get(
      '/api/services/services/',
      queryParameters: {'mine': 'true', 'page': page},
    );
    final results = res.data['results'] as List<dynamic>;
    return PagedResponse(
      results: results
          .map((e) => ServiceModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      hasMore: res.data['next'] != null,
    );
  }

  Future<PagedResponse<ServiceModel>> searchServices({
    required String query,
    String? serviceType,
    String? paymentType,
    String? targetGender,
    String? caregiverGender,
    int? childAge,
    int? distanceKm,
    int page = 1,
  }) async {
    final params = <String, dynamic>{
      'search': query,
      'service_type': serviceType,
      'payment_type': paymentType,
      'target_gender': targetGender,
      'caregiver_gender': caregiverGender,
      'child_age': childAge,
      'distance_km': distanceKm,
      'page': page,
    }..removeWhere((_, v) => v == null);
    final res = await _dio.get(
      '/api/services/services/',
      queryParameters: params,
    );
    final results = res.data['results'] as List<dynamic>;
    return PagedResponse(
      results: results
          .map((e) => ServiceModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      hasMore: res.data['next'] != null,
    );
  }

  Future<ServiceModel?> getMyServiceForSubcategory({
    required int categoryId,
    required int subCategoryId,
  }) async {
    final response = await _dio.get(
      '/api/services/services/',
      queryParameters: {
        'category': categoryId,
        'sub_category': subCategoryId,
        'mine': 'true',
      },
    );

    final results = response.data['results'] as List<dynamic>;
    if (results.isEmpty) return null;
    return ServiceModel.fromJson(results.first as Map<String, dynamic>);
  }

  Future<ServiceModel> createService({
    required Map<String, dynamic> fields,
  }) async {
    final response = await _dio.post(
      '/api/services/services/',
      data: FormData.fromMap(fields),
    );
    return ServiceModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ServiceModel> updateService({
    required int id,
    required Map<String, dynamic> fields,
  }) async {
    final response = await _dio.patch(
      '/api/services/services/$id/',
      data: FormData.fromMap(fields),
    );
    return ServiceModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteService({required int id}) async {
    await _dio.delete('/api/services/services/$id/');
  }
}
