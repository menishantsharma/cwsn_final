import 'package:dio/dio.dart';
import 'package:frontend/features/services/domain/models/service_model.dart';

class ServiceRemoteSource {
  final Dio _dio;

  ServiceRemoteSource(this._dio);

  Future<List<ServiceModel>> getServices({
    required int categoryId,
    required int subCategoryId,
  }) async {
    final response = await _dio.get(
      '/api/services/services/',
      queryParameters: {'category': categoryId, 'sub_category': subCategoryId},
    );

    final results = response.data['results'] as List<dynamic>;
    return results
        .map((e) => ServiceModel.fromJson(e as Map<String, dynamic>))
        .toList();
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
        'mine': true,
      },
    );

    final results = response.data['results'] as List<dynamic>;
    if (results.isEmpty) return null;
    return ServiceModel.fromJson(results.first as Map<String, dynamic>);
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
}
