import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/pagination/paginated_state.dart';
import 'package:frontend/features/notifications/data/sources/notification_remote_source.dart';
import 'package:frontend/features/notifications/domain/models/notification_model.dart';
import 'package:frontend/providers/core_providers.dart';

final notificationRemoteSourceProvider = Provider<NotificationRemoteSource>(
  (ref) => NotificationRemoteSource(ref.read(dioProvider)),
);

class NotificationNotifier
    extends PaginatedNotifier<NotificationModel> {
  @override
  Future<PagedResponse<NotificationModel>> fetchPage(int page) =>
      ref.read(notificationRemoteSourceProvider).getNotifications(page: page);

  Future<void> markAsRead(int id) async {
    final current = state.asData?.value;
    if (current == null) return;
    final alreadyRead = current.items.any((n) => n.id == id && n.isRead);
    if (alreadyRead) return;
    state = AsyncData(
      current.copyWith(
        items: current.items
            .map((n) => n.id == id ? n.copyWith(isRead: true) : n)
            .toList(),
      ),
    );
    ref.read(notificationRemoteSourceProvider).markAsRead(id);
    ref.invalidate(unreadCountProvider);
  }

  Future<void> markAllRead() async {
    final current = state.asData?.value;
    if (current == null) return;
    state = AsyncData(
      current.copyWith(
        items: current.items.map((n) => n.copyWith(isRead: true)).toList(),
      ),
    );
    await ref.read(notificationRemoteSourceProvider).markAllRead();
    ref.invalidate(unreadCountProvider);
  }
}

final notificationProvider =
    AsyncNotifierProvider<NotificationNotifier, PaginatedState<NotificationModel>>(
      NotificationNotifier.new,
    );

final unreadCountProvider = FutureProvider<int>((ref) async {
  return ref.read(notificationRemoteSourceProvider).getUnreadCount();
});
