import 'package:frontend/features/services/domain/models/service_model.dart';

abstract class ServiceRepository {
  Future<List<ServiceModel>> getServices({
    required int categoryId,
    required int subCategoryId,
  });

  Future<ServiceModel?> getMyServiceForSubcategory({
    required int categoryId,
    required int subCategoryId,
  });

  Future<ServiceModel> createService({required Map<String, dynamic> fields});

  Future<ServiceModel> updateService({
    required int id,
    required Map<String, dynamic> fields,
  });

  Future<void> deleteService({required int id});
}
