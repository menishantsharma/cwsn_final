import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/requests/data/sources/request_remote_source.dart';
import 'package:frontend/features/requests/domain/models/request_model.dart';
import 'package:frontend/providers/core_providers.dart';

final requestRemoteSourceProvider = Provider<RequestRemoteSource>(
  (ref) => RequestRemoteSource(ref.read(dioProvider)),
);

class RequestNotifier extends AsyncNotifier<List<RequestModel>> {
  @override
  Future<List<RequestModel>> build() async {
    return ref.read(requestRemoteSourceProvider).getRequests();
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
    state = AsyncData(
      state.requireValue.map((r) => r.id == updated.id ? updated : r).toList(),
    );
  }
}

final requestProvider =
    AsyncNotifierProvider<RequestNotifier, List<RequestModel>>(
      RequestNotifier.new,
    );

final pendingRequestCountProvider = Provider<int>((ref) {
  return ref
      .watch(requestProvider)
      .maybeWhen(
        data: (requests) => requests.where((r) => r.status == 'Pending').length,
        orElse: () => 0,
      );
});
