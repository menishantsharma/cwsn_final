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

class ServiceNotifier
    extends PaginatedFamilyNotifier<ServiceModel, (int, int)> {
  final (int, int) _args;

  ServiceNotifier(this._args);

  @override
  (int, int) get arg => _args;

  @override
  Future<PagedResponse<ServiceModel>> fetchPage((int, int) arg, int page) {
    // Watching filter here means any filter change auto-resets to page 1
    final filter = ref.watch(serviceFilterProvider);
    return ref.read(serviceRepositoryProvider).getServices(
          categoryId: arg.$1,
          subCategoryId: arg.$2,
          serviceType: filter.serviceType,
          paymentType: filter.paymentType,
          targetGender: filter.targetGender,
          caregiverGender: filter.caregiverGender,
          childAge: filter.childAge,
          distanceKm: filter.distanceKm,
          page: page,
        );
  }
}

final serviceProvider =
    AsyncNotifierProvider.family<
      ServiceNotifier,
      PaginatedState<ServiceModel>,
      (int, int)
    >((args) => ServiceNotifier(args));

class AllMyServicesNotifier extends PaginatedNotifier<ServiceModel> {
  @override
  Future<PagedResponse<ServiceModel>> fetchPage(int page) =>
      ref.read(serviceRepositoryProvider).getAllMyServices(page: page);
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
      .read(serviceRepositoryProvider)
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

class SearchNotifier
    extends PaginatedFamilyNotifier<ServiceModel, String> {
  final String _query;

  SearchNotifier(this._query);

  @override
  String get arg => _query;

  @override
  Future<PagedResponse<ServiceModel>> fetchPage(String arg, int page) {
    final filter = ref.watch(serviceFilterProvider);
    return ref.read(serviceRepositoryProvider).searchServices(
          query: arg,
          serviceType: filter.serviceType,
          paymentType: filter.paymentType,
          targetGender: filter.targetGender,
          caregiverGender: filter.caregiverGender,
          childAge: filter.childAge,
          distanceKm: filter.distanceKm,
          page: page,
        );
  }
}

final searchProvider =
    AsyncNotifierProvider.family<SearchNotifier, PaginatedState<ServiceModel>, String>(
      SearchNotifier.new,
    );
