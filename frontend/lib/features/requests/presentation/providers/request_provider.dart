import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/pagination/paginated_state.dart';
import 'package:frontend/features/requests/data/sources/request_remote_source.dart';
import 'package:frontend/features/requests/domain/models/request_model.dart';
import 'package:frontend/providers/core_providers.dart';

final requestRemoteSourceProvider = Provider<RequestRemoteSource>(
  (ref) => RequestRemoteSource(ref.read(dioProvider)),
);

class RequestNotifier extends PaginatedNotifier<RequestModel> {
  @override
  Future<PagedResponse<RequestModel>> fetchPage(int page) =>
      ref.read(requestRemoteSourceProvider).getRequests(page: page);

  Future<void> accept(int id) async {
    final updated =
        await ref.read(requestRemoteSourceProvider).acceptRequest(id);
    _replace(updated);
  }

  Future<void> reject(int id) async {
    final updated =
        await ref.read(requestRemoteSourceProvider).rejectRequest(id);
    _replace(updated);
  }

  void _replace(RequestModel updated) {
    final current = state.asData?.value;
    if (current == null) return;
    state = AsyncData(
      current.copyWith(
        items: current.items
            .map((r) => r.id == updated.id ? updated : r)
            .toList(),
      ),
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
    state = AsyncData(current.copyWith(items: [...current.items, created]));
    ref.invalidate(parentRequestsProvider);
  }
}

final requestProvider =
    AsyncNotifierProvider<RequestNotifier, PaginatedState<RequestModel>>(
      RequestNotifier.new,
    );

// Derived from already-loaded list — only used inside the notifications page
final pendingRequestCountProvider = Provider<int>((ref) {
  return ref.watch(requestProvider).maybeWhen(
        data: (state) =>
            state.items.where((r) => r.status == 'Pending').length,
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
