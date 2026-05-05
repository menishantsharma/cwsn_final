import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/pagination/paginated_state.dart';
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

class ServiceFilter {
  final String? serviceType;
  final String? paymentType;
  final String? targetGender;
  final String? caregiverGender;
  final int? childAge;
  final int? distanceKm;

  const ServiceFilter({
    this.serviceType,
    this.paymentType,
    this.targetGender,
    this.caregiverGender,
    this.childAge,
    this.distanceKm,
  });

  bool get isActive =>
      serviceType != null ||
      paymentType != null ||
      targetGender != null ||
      caregiverGender != null ||
      childAge != null ||
      distanceKm != null;

  ServiceFilter copyWith({
    Object? serviceType = _sentinel,
    Object? paymentType = _sentinel,
    Object? targetGender = _sentinel,
    Object? caregiverGender = _sentinel,
    Object? childAge = _sentinel,
    Object? distanceKm = _sentinel,
  }) {
    return ServiceFilter(
      serviceType: serviceType == _sentinel
          ? this.serviceType
          : serviceType as String?,
      paymentType: paymentType == _sentinel
          ? this.paymentType
          : paymentType as String?,
      targetGender: targetGender == _sentinel
          ? this.targetGender
          : targetGender as String?,
      caregiverGender: caregiverGender == _sentinel
          ? this.caregiverGender
          : caregiverGender as String?,
      childAge: childAge == _sentinel ? this.childAge : childAge as int?,
      distanceKm: distanceKm == _sentinel
          ? this.distanceKm
          : distanceKm as int?,
    );
  }
}

const _sentinel = Object();

final serviceFilterProvider =
    NotifierProvider<ServiceFilterNotifier, ServiceFilter>(
      ServiceFilterNotifier.new,
    );

class ServiceFilterNotifier extends Notifier<ServiceFilter> {
  @override
  ServiceFilter build() => const ServiceFilter();

  void setServiceType(String? value) =>
      state = state.copyWith(serviceType: value);
  void setPaymentType(String? value) =>
      state = state.copyWith(paymentType: value);
  void setTargetGender(String? value) =>
      state = state.copyWith(targetGender: value);
  void setCaregiverGender(String? value) =>
      state = state.copyWith(caregiverGender: value);
  void setChildAge(int? value) => state = state.copyWith(childAge: value);
  void setDistanceKm(int? value) => state = state.copyWith(distanceKm: value);
  void clearAll() => state = const ServiceFilter();
}

class ServiceNotifier extends AsyncNotifier<PaginatedState<ServiceModel>> {
  final int categoryId;
  final int subCategoryId;
  ServiceNotifier(this.categoryId, this.subCategoryId);

  @override
  Future<PaginatedState<ServiceModel>> build() async {
    // Watching filter here means any filter change auto-resets to page 1
    final filter = ref.watch(serviceFilterProvider);
    final page = await ref
        .read(serviceRepositoryProvider)
        .getServices(
          categoryId: categoryId,
          subCategoryId: subCategoryId,
          serviceType: filter.serviceType,
          paymentType: filter.paymentType,
          targetGender: filter.targetGender,
          caregiverGender: filter.caregiverGender,
          childAge: filter.childAge,
          distanceKm: filter.distanceKm,
          page: 1,
        );
    return PaginatedState(
      items: page.results,
      hasMore: page.hasMore,
      currentPage: 1,
    );
  }

  Future<void> loadMore() async {
    final current = state.asData?.value;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    final filter = ref.read(serviceFilterProvider);
    state = AsyncData(current.copyWith(isLoadingMore: true));
    final nextPage = current.currentPage + 1;
    final page = await ref
        .read(serviceRepositoryProvider)
        .getServices(
          categoryId: categoryId,
          subCategoryId: subCategoryId,
          serviceType: filter.serviceType,
          paymentType: filter.paymentType,
          targetGender: filter.targetGender,
          caregiverGender: filter.caregiverGender,
          childAge: filter.childAge,
          distanceKm: filter.distanceKm,
          page: nextPage,
        );

    final latest = state.asData?.value;
    if (latest == null || !latest.isLoadingMore) return;
    state = AsyncData(
      latest.copyWith(
        items: [...current.items, ...page.results],
        hasMore: page.hasMore,
        isLoadingMore: false,
        currentPage: nextPage,
      ),
    );
  }
}

final serviceProvider =
    AsyncNotifierProvider.family<
      ServiceNotifier,
      PaginatedState<ServiceModel>,
      (int, int)
    >((args) => ServiceNotifier(args.$1, args.$2));

class AllMyServicesNotifier
    extends AsyncNotifier<PaginatedState<ServiceModel>> {
  @override
  Future<PaginatedState<ServiceModel>> build() async {
    final page = await ref
        .read(serviceRepositoryProvider)
        .getAllMyServices(page: 1);
    return PaginatedState(
      items: page.results,
      hasMore: page.hasMore,
      currentPage: 1,
    );
  }

  Future<void> loadMore() async {
    final current = state.asData?.value;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));
    final nextPage = current.currentPage + 1;
    final page = await ref
        .read(serviceRepositoryProvider)
        .getAllMyServices(page: nextPage);

    final latest = state.asData?.value;
    if (latest == null || !latest.isLoadingMore) return;
    state = AsyncData(
      latest.copyWith(
        items: [...current.items, ...page.results],
        hasMore: page.hasMore,
        isLoadingMore: false,
        currentPage: nextPage,
      ),
    );
  }
}

final allMyServicesProvider =
    AsyncNotifierProvider<AllMyServicesNotifier, PaginatedState<ServiceModel>>(
      AllMyServicesNotifier.new,
    );

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

  void _invalidateLists() {
    final key = (_original.categoryId, _original.subCategoryId);
    ref.invalidate(allMyServicesProvider);
    ref.invalidate(serviceProvider(key));
    ref.invalidate(myServiceProvider(key));
  }

  Future<void> updateField(Map<String, dynamic> fields) async {
    final current = state.value;
    if (current == null) return;

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final updated = await ref
          .read(serviceRepositoryProvider)
          .updateService(id: _original.id, fields: fields);
      _invalidateLists();
      return updated;
    });
  }

  Future<void> deleteService() async {
    state = const AsyncLoading();
    await ref.read(serviceRepositoryProvider).deleteService(id: _original.id);
    _invalidateLists();
  }
}

final editableServiceProvider =
    NotifierProvider<EditableServiceNotifier, AsyncValue<ServiceModel>>(
      EditableServiceNotifier.new,
    );
