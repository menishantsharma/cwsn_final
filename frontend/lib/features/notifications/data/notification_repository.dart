import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/pagination/paginated_state.dart';
import 'package:frontend/features/notifications/domain/notification_models.dart';
import 'package:frontend/providers/core_providers.dart';

class NotificationRepository {
  final Dio _dio;
  NotificationRepository(this._dio);

  Future<PagedResponse<NotificationModel>> getNotifications({
    int page = 1,
  }) async {
    final res = await _dio.get(
      '/api/interactions/notifications/',
      queryParameters: {'page': page},
    );
    final results = res.data['results'] as List;
    return PagedResponse(
      results: results.map((e) => NotificationModel.fromJson(e)).toList(),
      hasMore: res.data['next'] != null,
    );
  }

  Future<void> markAsRead(int id) =>
      _dio.post('/api/interactions/notifications/$id/mark_read/');

  Future<void> markAllRead() =>
      _dio.post('/api/interactions/notifications/mark_all_read/');

  Future<int> getUnreadCount() async {
    final res = await _dio.get('/api/interactions/notifications/unread_count/');
    return res.data['count'] as int;
  }
}

final notificationRepositoryProvider = Provider<NotificationRepository>(
  (ref) => NotificationRepository(ref.read(dioProvider)),
);
