import 'package:frontend/features/services/data/sources/service_remote_source.dart';
import 'package:frontend/features/services/domain/models/service_model.dart';
import 'package:frontend/features/services/domain/repositories/service_repository.dart';

class ServiceRepositoryImpl implements ServiceRepository {
  final ServiceRemoteSource _remoteSource;

  ServiceRepositoryImpl(this._remoteSource);

  @override
  Future<List<ServiceModel>> getAllMyServices() {
    return _remoteSource.getAllMyServices();
  }

  @override
  Future<List<ServiceModel>> getServices({
    required int categoryId,
    required int subCategoryId,
    String? serviceType,
    String? paymentType,
    String? targetGender,
    String? caregiverGender,
    int? childAge,
    int? distanceKm,
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
  Future<ServiceModel> createService({required Map<String, dynamic> fields}) {
    return _remoteSource.createService(fields: fields);
  }

  @override
  Future<ServiceModel> updateService({
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
