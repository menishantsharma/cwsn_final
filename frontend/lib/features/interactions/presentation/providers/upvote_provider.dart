import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/interactions/data/sources/upvote_remote_source.dart';
import 'package:frontend/providers/core_providers.dart';

final upvoteRemoteSourceProvider = Provider<UpvoteRemoteSource>(
  (ref) => UpvoteRemoteSource(ref.read(dioProvider)),
);

// Map of serviceId -> upvoteId, plus a delta map for local count changes
class UpvoteState {
  final Map<int, int> upvotes; // serviceId -> upvoteId
  final Map<int, int> deltas; // serviceId -> count delta

  const UpvoteState({required this.upvotes, required this.deltas});

  UpvoteState copyWith({Map<int, int>? upvotes, Map<int, int>? deltas}) {
    return UpvoteState(
      upvotes: upvotes ?? this.upvotes,
      deltas: deltas ?? this.deltas,
    );
  }
}

class UpvoteNotifier extends AsyncNotifier<UpvoteState> {
  @override
  Future<UpvoteState> build() async {
    final upvotes = await ref.read(upvoteRemoteSourceProvider).getUserUpvotes();
    return UpvoteState(
      upvotes: {for (final u in upvotes) u.serviceId: u.id},
      deltas: {},
    );
  }

  Future<void> toggle(int serviceId) async {
    final current = state.requireValue;
    if (current.upvotes.containsKey(serviceId)) {
      final upvoteId = current.upvotes[serviceId]!;
      await ref.read(upvoteRemoteSourceProvider).removeUpvote(upvoteId);
      final newUpvotes = {...current.upvotes}..remove(serviceId);
      final newDeltas = {...current.deltas, serviceId: (current.deltas[serviceId] ?? 0) - 1};
      state = AsyncData(current.copyWith(upvotes: newUpvotes, deltas: newDeltas));
    } else {
      final created = await ref
          .read(upvoteRemoteSourceProvider)
          .upvoteService(serviceId);
      final newUpvotes = {...current.upvotes, serviceId: created.id};
      final newDeltas = {...current.deltas, serviceId: (current.deltas[serviceId] ?? 0) + 1};
      state = AsyncData(current.copyWith(upvotes: newUpvotes, deltas: newDeltas));
    }
  }
}

final upvoteProvider = AsyncNotifierProvider<UpvoteNotifier, UpvoteState>(
  UpvoteNotifier.new,
);

final isUpvotedProvider = Provider.family<bool, int>((ref, serviceId) {
  return ref.watch(upvoteProvider).maybeWhen(
        data: (s) => s.upvotes.containsKey(serviceId),
        orElse: () => false,
      );
});

final upvoteCountDeltaProvider = Provider.family<int, int>((ref, serviceId) {
  return ref.watch(upvoteProvider).maybeWhen(
        data: (s) => s.deltas[serviceId] ?? 0,
        orElse: () => 0,
      );
});
