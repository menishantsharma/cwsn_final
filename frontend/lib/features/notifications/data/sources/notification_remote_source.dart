import 'package:dio/dio.dart';
import 'package:frontend/features/notifications/domain/models/notification_model.dart';

class NotificationRemoteSource {
  final Dio _dio;

  NotificationRemoteSource(this._dio);

  Future<List<NotificationModel>> getNotifications() async {
    final res = await _dio.get('/api/interactions/notifications/');
    final results = res.data['results'] as List;
    return results.map((e) => NotificationModel.fromJson(e)).toList();
  }

  Future<void> markAsRead(int id) async {
    await _dio.post('/api/interactions/notifications/$id/mark_read/');
  }
}
