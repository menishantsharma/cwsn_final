import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/pagination/paginated_state.dart';
import 'package:frontend/features/requests/data/sources/request_remote_source.dart';
import 'package:frontend/features/requests/domain/models/request_model.dart';
import 'package:frontend/providers/core_providers.dart';

final requestRemoteSourceProvider = Provider<RequestRemoteSource>(
  (ref) => RequestRemoteSource(ref.read(dioProvider)),
);

class PendingRequestsNotifier extends PaginatedNotifier<RequestModel> {
  @override
  Future<PagedResponse<RequestModel>> fetchPage(int page) =>
      ref.read(requestRemoteSourceProvider).getPendingRequests(page: page);

  Future<void> accept(int id) async {
    await ref.read(requestRemoteSourceProvider).acceptRequest(id);
    _remove(id);
    ref.invalidate(historyRequestsProvider);
    ref.invalidate(parentRequestsProvider);
  }

  Future<void> reject(int id) async {
    await ref.read(requestRemoteSourceProvider).rejectRequest(id);
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
        .read(requestRemoteSourceProvider)
        .createRequest(serviceId: serviceId, childId: childId, note: note);
    final current = state.asData?.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(items: [created, ...current.items]));
    ref.invalidate(parentRequestsProvider);
  }
}

final pendingRequestsProvider =
    AsyncNotifierProvider<PendingRequestsNotifier, PaginatedState<RequestModel>>(
      PendingRequestsNotifier.new,
    );

class HistoryRequestsNotifier extends PaginatedNotifier<RequestModel> {
  @override
  Future<PagedResponse<RequestModel>> fetchPage(int page) =>
      ref.read(requestRemoteSourceProvider).getHistoryRequests(page: page);
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
  return ref.read(requestRemoteSourceProvider).getPendingCount();
});

class ParentRequestsNotifier extends PaginatedNotifier<RequestModel> {
  @override
  Future<PagedResponse<RequestModel>> fetchPage(int page) =>
      ref.read(requestRemoteSourceProvider).getRequestsAsParent(page: page);
}

final parentRequestsProvider =
    AsyncNotifierProvider<ParentRequestsNotifier, PaginatedState<RequestModel>>(
      ParentRequestsNotifier.new,
    );

