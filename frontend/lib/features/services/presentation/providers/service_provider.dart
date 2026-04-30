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

final myServiceProvider = FutureProvider.family<ServiceModel?, (int, int)>((
  ref,
  args,
) {
  final (categoryId, subCategoryId) = args;
  return ref
      .watch(serviceRepositoryProvider)
      .getMyServiceForSubcategory(
        categoryId: categoryId,
        subCategoryId: subCategoryId,
      );
});

class EditableServiceNotifier extends Notifier<AsyncValue<ServiceModel>> {
  late ServiceModel _original;

  @override
  AsyncValue<ServiceModel> build() => const AsyncLoading();

  void init(ServiceModel service) {
    _original = service;
    state = AsyncData(service);
  }

  Future<void> updateField(Map<String, dynamic> fields) async {
    final current = state.value;
    if (current == null) return;

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final updated = await ref
          .read(serviceRepositoryProvider)
          .updateService(id: _original.id, fields: fields);
      return updated;
    });
  }

  Future<void> deleteService() async {
    state = const AsyncLoading();
    await ref.read(serviceRepositoryProvider).deleteService(id: _original.id);
  }
}

final editableServiceProvider =
    NotifierProvider<EditableServiceNotifier, AsyncValue<ServiceModel>>(
      EditableServiceNotifier.new,
    );
