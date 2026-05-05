import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/pagination/paginated_state.dart';
import 'package:frontend/features/requests/data/sources/request_remote_source.dart';
import 'package:frontend/features/requests/domain/models/request_model.dart';
import 'package:frontend/providers/core_providers.dart';

final requestRemoteSourceProvider = Provider<RequestRemoteSource>(
  (ref) => RequestRemoteSource(ref.read(dioProvider)),
);

class RequestNotifier extends AsyncNotifier<PaginatedState<RequestModel>> {
  @override
  Future<PaginatedState<RequestModel>> build() async {
    final page = await ref
        .read(requestRemoteSourceProvider)
        .getRequests(page: 1);
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
        .read(requestRemoteSourceProvider)
        .getRequests(page: nextPage);

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

  Future<void> accept(int id) async {
    final updated = await ref
        .read(requestRemoteSourceProvider)
        .acceptRequest(id);
    _replace(updated);
  }

  Future<void> reject(int id) async {
    final updated = await ref
        .read(requestRemoteSourceProvider)
        .rejectRequest(id);
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

final pendingRequestCountProvider = Provider<int>((ref) {
  return ref
      .watch(requestProvider)
      .maybeWhen(
        data: (state) => state.items.where((r) => r.status == 'Pending').length,
        orElse: () => 0,
      );
});

class ParentRequestsNotifier
    extends AsyncNotifier<PaginatedState<RequestModel>> {
  @override
  Future<PaginatedState<RequestModel>> build() async {
    final page = await ref
        .read(requestRemoteSourceProvider)
        .getRequestsAsParent(page: 1);
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
        .read(requestRemoteSourceProvider)
        .getRequestsAsParent(page: nextPage);

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

final parentRequestsProvider =
    AsyncNotifierProvider<ParentRequestsNotifier, PaginatedState<RequestModel>>(
      ParentRequestsNotifier.new,
    );
