import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/pagination/paginated_state.dart';
import 'package:frontend/features/auth/presentation/controllers/auth_controller.dart';
import 'package:frontend/features/notifications/data/notification_repository.dart';
import 'package:frontend/features/notifications/domain/notification_models.dart';

class NotificationNotifier extends PaginatedNotifier<NotificationModel> {
  @override
  Future<PaginatedState<NotificationModel>> build() {
    ref.clearOnLogout();
    return super.build();
  }

  @override
  Future<PagedResponse<NotificationModel>> fetchPage(int page) =>
      ref.read(notificationRepositoryProvider).getNotifications(page: page);

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
    ref.read(notificationRepositoryProvider).markAsRead(id);
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
    await ref.read(notificationRepositoryProvider).markAllRead();
    ref.invalidate(unreadCountProvider);
  }
}

final notificationProvider =
    AsyncNotifierProvider<NotificationNotifier, PaginatedState<NotificationModel>>(
      NotificationNotifier.new,
    );

final unreadCountProvider = FutureProvider<int>((ref) async {
  ref.clearOnLogout();
  return ref.read(notificationRepositoryProvider).getUnreadCount();
});
