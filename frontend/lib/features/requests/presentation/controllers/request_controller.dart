import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/pagination/paginated_state.dart';
import 'package:frontend/features/auth/presentation/controllers/auth_controller.dart';
import 'package:frontend/features/requests/data/request_repository.dart';
import 'package:frontend/features/requests/domain/request_models.dart';

class PendingRequestsNotifier extends PaginatedNotifier<RequestModel> {
  @override
  Future<PaginatedState<RequestModel>> build() {
    ref.clearOnLogout();
    return super.build();
  }

  @override
  Future<PagedResponse<RequestModel>> fetchPage(int page) =>
      ref.read(requestRepositoryProvider).getPendingRequests(page: page);

  Future<void> accept(int id) async {
    await ref.read(requestRepositoryProvider).acceptRequest(id);
    _remove(id);
    ref.invalidate(historyRequestsProvider);
    ref.invalidate(parentRequestsProvider);
  }

  Future<void> reject(int id) async {
    await ref.read(requestRepositoryProvider).rejectRequest(id);
    _remove(id);
    ref.invalidate(historyRequestsProvider);
    ref.invalidate(parentRequestsProvider);
  }

  void _remove(int id) {
    final current = state.asData?.value;
    if (current == null) return;
    state = AsyncData(
      current.copyWith(items: current.items.where((r) => r.id != id).toList()),
    );
  }

  Future<void> sendRequest({
    required int serviceId,
    required int childId,
    String? note,
  }) async {
    final created = await ref
        .read(requestRepositoryProvider)
        .createRequest(serviceId: serviceId, childId: childId, note: note);
    final current = state.asData?.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(items: [created, ...current.items]));
    ref.invalidate(parentRequestsProvider);
    ref.invalidate(caregiverRequestProvider(created.caregiverId));
  }
}

final pendingRequestsProvider =
    AsyncNotifierProvider<PendingRequestsNotifier, PaginatedState<RequestModel>>(
      PendingRequestsNotifier.new,
    );

class HistoryRequestsNotifier extends PaginatedNotifier<RequestModel> {
  @override
  Future<PaginatedState<RequestModel>> build() {
    ref.clearOnLogout();
    return super.build();
  }

  @override
  Future<PagedResponse<RequestModel>> fetchPage(int page) =>
      ref.read(requestRepositoryProvider).getHistoryRequests(page: page);
}

final historyRequestsProvider =
    AsyncNotifierProvider<HistoryRequestsNotifier, PaginatedState<RequestModel>>(
      HistoryRequestsNotifier.new,
    );

// Derived count from already-loaded pending list — used for the tab badge
final pendingRequestCountProvider = Provider<int>((ref) {
  return ref.watch(pendingRequestsProvider).maybeWhen(
        data: (state) => state.items.length,
        orElse: () => 0,
      );
});

// Lightweight count — single DB query, safe to watch from any page
final pendingCountProvider = FutureProvider<int>((ref) async {
  ref.clearOnLogout();
  return ref.read(requestRepositoryProvider).getPendingCount();
});

class ParentRequestsNotifier extends PaginatedNotifier<RequestModel> {
  @override
  Future<PaginatedState<RequestModel>> build() {
    ref.clearOnLogout();
    return super.build();
  }

  @override
  Future<PagedResponse<RequestModel>> fetchPage(int page) =>
      ref.read(requestRepositoryProvider).getRequestsAsParent(page: page);
}

final parentRequestsProvider =
    AsyncNotifierProvider<ParentRequestsNotifier, PaginatedState<RequestModel>>(
      ParentRequestsNotifier.new,
    );

final caregiverRequestProvider = FutureProvider.family<RequestModel?, int>(
  (ref, caregiverId) {
    ref.clearOnLogout();
    return ref.read(requestRepositoryProvider).getRequestForCaregiver(caregiverId);
  },
);
