import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/pagination/paginated_state.dart';
import 'package:frontend/features/notifications/data/sources/notification_remote_source.dart';
import 'package:frontend/features/notifications/domain/models/notification_model.dart';
import 'package:frontend/providers/core_providers.dart';

final notificationRemoteSourceProvider = Provider<NotificationRemoteSource>(
  (ref) => NotificationRemoteSource(ref.read(dioProvider)),
);

class NotificationNotifier
    extends AsyncNotifier<PaginatedState<NotificationModel>> {
  @override
  Future<PaginatedState<NotificationModel>> build() async {
    final page = await ref
        .read(notificationRemoteSourceProvider)
        .getNotifications(page: 1);
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
        .read(notificationRemoteSourceProvider)
        .getNotifications(page: nextPage);

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

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final page = await ref
          .read(notificationRemoteSourceProvider)
          .getNotifications(page: 1);
      return PaginatedState(
        items: page.results,
        hasMore: page.hasMore,
        currentPage: 1,
      );
    });
  }

  Future<void> markAsRead(int id) async {
    await ref.read(notificationRemoteSourceProvider).markAsRead(id);
    final current = state.asData?.value;
    if (current == null) return;
    state = AsyncData(
      current.copyWith(
        items: current.items
            .map((n) => n.id == id ? n.copyWith(isRead: true) : n)
            .toList(),
      ),
    );
  }
}

final notificationProvider =
    AsyncNotifierProvider<NotificationNotifier, PaginatedState<NotificationModel>>(
      NotificationNotifier.new,
    );
