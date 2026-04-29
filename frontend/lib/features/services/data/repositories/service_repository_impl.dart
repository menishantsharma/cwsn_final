import 'package:frontend/features/services/data/sources/service_remote_source.dart';
import 'package:frontend/features/services/domain/models/service_model.dart';
import 'package:frontend/features/services/domain/repositories/service_repository.dart';

class ServiceRepositoryImpl implements ServiceRepository {
  final ServiceRemoteSource _remoteSource;

  ServiceRepositoryImpl(this._remoteSource);

  @override
  Future<List<ServiceModel>> getServices({
    required int categoryId,
    required int subCategoryId,
  }) {
    return _remoteSource.getServices(
      categoryId: categoryId,
      subCategoryId: subCategoryId,
    );
  }
}
