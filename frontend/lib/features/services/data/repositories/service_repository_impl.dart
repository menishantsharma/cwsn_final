import 'package:frontend/core/pagination/paginated_state.dart';
import 'package:frontend/features/services/data/sources/service_remote_source.dart';
import 'package:frontend/features/services/domain/models/service_model.dart';
import 'package:frontend/features/services/domain/repositories/service_repository.dart';

class ServiceRepositoryImpl implements ServiceRepository {
  final ServiceRemoteSource _remoteSource;

  ServiceRepositoryImpl(this._remoteSource);

  @override
  Future<PagedResponse<ServiceModel>> getAllMyServices({int page = 1}) {
    return _remoteSource.getAllMyServices(page: page);
  }

  @override
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
  }) {
    return _remoteSource.getServices(
      categoryId: categoryId,
      subCategoryId: subCategoryId,
      serviceType: serviceType,
      paymentType: paymentType,
      targetGender: targetGender,
      caregiverGender: caregiverGender,
      childAge: childAge,
      distanceKm: distanceKm,
      page: page,
    );
  }

  @override
  Future<PagedResponse<ServiceModel>> searchServices({
    required String query,
    String? serviceType,
    String? paymentType,
    String? targetGender,
    String? caregiverGender,
    int? childAge,
    int? distanceKm,
    int page = 1,
  }) {
    return _remoteSource.searchServices(
      query: query,
      serviceType: serviceType,
      paymentType: paymentType,
      targetGender: targetGender,
      caregiverGender: caregiverGender,
      childAge: childAge,
      distanceKm: distanceKm,
      page: page,
    );
  }

  @override
  Future<ServiceModel?> getMyServiceForSubcategory({
    required int categoryId,
    required int subCategoryId,
  }) {
    return _remoteSource.getMyServiceForSubcategory(
      categoryId: categoryId,
      subCategoryId: subCategoryId,
    );
  }

  @override
  Future<ServiceDetailModel> getServiceById({required int id}) {
    return _remoteSource.getServiceById(id: id);
  }

  @override
  Future<ServiceDetailModel> createService({required Map<String, dynamic> fields}) {
    return _remoteSource.createService(fields: fields);
  }

  @override
  Future<ServiceDetailModel> updateService({
    required int id,
    required Map<String, dynamic> fields,
  }) {
    return _remoteSource.updateService(id: id, fields: fields);
  }

  @override
  Future<void> deleteService({required int id}) {
    return _remoteSource.deleteService(id: id);
  }
}
