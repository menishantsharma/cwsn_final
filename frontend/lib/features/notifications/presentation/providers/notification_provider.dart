import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/notifications/data/sources/notification_remote_source.dart';
import 'package:frontend/features/notifications/domain/models/notification_model.dart';
import 'package:frontend/providers/core_providers.dart';

final notificationRemoteSourceProvider = Provider<NotificationRemoteSource>(
  (ref) => NotificationRemoteSource(ref.read(dioProvider)),
);

class NotificationNotifier extends AsyncNotifier<List<NotificationModel>> {
  @override
  Future<List<NotificationModel>> build() async {
    return ref.read(notificationRemoteSourceProvider).getNotifications();
  }

  Future<void> markAsRead(int id) async {
    await ref.read(notificationRemoteSourceProvider).markAsRead(id);
    state = AsyncData(
      state.requireValue
          .map((n) => n.id == id ? n.copyWith(isRead: true) : n)
          .toList(),
    );
  }
}

final notificationProvider =
    AsyncNotifierProvider<NotificationNotifier, List<NotificationModel>>(
      NotificationNotifier.new,
    );
