import 'package:frontend/features/services/domain/models/service_model.dart';

abstract class ServiceRepository {
  Future<List<ServiceModel>> getServices({
    required int categoryId,
    required int subCategoryId,
  });
}
