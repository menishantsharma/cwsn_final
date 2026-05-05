import 'package:frontend/core/pagination/paginated_state.dart';
import 'package:frontend/features/services/domain/models/service_model.dart';

abstract class ServiceRepository {
  Future<PagedResponse<ServiceModel>> getAllMyServices({int page = 1});

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
