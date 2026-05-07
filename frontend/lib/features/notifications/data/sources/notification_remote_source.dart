import 'package:dio/dio.dart';
import 'package:frontend/core/pagination/paginated_state.dart';
import 'package:frontend/features/notifications/domain/models/notification_model.dart';

class NotificationRemoteSource {
  final Dio _dio;

  NotificationRemoteSource(this._dio);

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

  Future<void> markAsRead(int id) async {
    await _dio.post('/api/interactions/notifications/$id/mark_read/');
  }

  Future<void> markAllRead() async {
    await _dio.post('/api/interactions/notifications/mark_all_read/');
  }

  Future<int> getUnreadCount() async {
    final res = await _dio.get('/api/interactions/notifications/unread_count/');
    return res.data['count'] as int;
  }
}
