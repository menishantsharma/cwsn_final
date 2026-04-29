import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/services/data/repositories/service_repository_impl.dart';
import 'package:frontend/features/services/data/sources/service_remote_source.dart';
import 'package:frontend/features/services/domain/models/service_model.dart';
import 'package:frontend/features/services/domain/repositories/service_repository.dart';
import 'package:frontend/providers/core_providers.dart';

final serviceRemoteSourceProvider = Provider<ServiceRemoteSource>(
  (ref) => ServiceRemoteSource(ref.read(dioProvider)),
);

final serviceRepositoryProvider = Provider<ServiceRepository>(
  (ref) => ServiceRepositoryImpl(ref.read(serviceRemoteSourceProvider)),
);

final serviceProvider = FutureProvider.family<List<ServiceModel>, (int, int)>((
  ref,
  args,
) {
  final (categoryId, subCategoryId) = args;
  return ref
      .watch(serviceRepositoryProvider)
      .getServices(categoryId: categoryId, subCategoryId: subCategoryId);
});
