import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/interactions/data/sources/upvote_remote_source.dart';
import 'package:frontend/providers/core_providers.dart';

final upvoteRemoteSourceProvider = Provider<UpvoteRemoteSource>(
  (ref) => UpvoteRemoteSource(ref.read(dioProvider)),
);

// Map of serviceId -> upvoteId for the current user's upvotes
class UpvoteNotifier extends AsyncNotifier<Map<int, int>> {
  @override
  Future<Map<int, int>> build() async {
    final upvotes = await ref.read(upvoteRemoteSourceProvider).getUserUpvotes();
    return {for (final u in upvotes) u.serviceId: u.id};
  }

  Future<void> toggle(int serviceId) async {
    final current = state.requireValue;
    if (current.containsKey(serviceId)) {
      final upvoteId = current[serviceId]!;
      await ref.read(upvoteRemoteSourceProvider).removeUpvote(upvoteId);
      state = AsyncData({...current}..remove(serviceId));
    } else {
      final created = await ref
          .read(upvoteRemoteSourceProvider)
          .upvoteService(serviceId);
      state = AsyncData({...current, serviceId: created.id});
    }
  }
}

final upvoteProvider = AsyncNotifierProvider<UpvoteNotifier, Map<int, int>>(
  UpvoteNotifier.new,
);

final isUpvotedProvider = Provider.family<bool, int>((ref, serviceId) {
  return ref
      .watch(upvoteProvider)
      .maybeWhen(
        data: (map) => map.containsKey(serviceId),
        orElse: () => false,
      );
});
