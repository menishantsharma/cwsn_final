import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/interactions/domain/upvote_models.dart';
import 'package:frontend/providers/core_providers.dart';

class UpvoteRepository {
  final Dio _dio;
  UpvoteRepository(this._dio);

  Future<List<UpvoteModel>> getUserUpvotes() async {
    final res = await _dio.get('/api/interactions/upvotes/');
    final results = res.data['results'] as List;
    return results.map((e) => UpvoteModel.fromJson(e)).toList();
  }

  Future<UpvoteModel> upvoteService(int serviceId) async {
    final res = await _dio.post(
      '/api/interactions/upvotes/',
      data: {'service': serviceId},
    );
    return UpvoteModel.fromJson(res.data);
  }

  Future<void> removeUpvote(int upvoteId) =>
      _dio.delete('/api/interactions/upvotes/$upvoteId/');

  Future<void> reportService({
    required int reportedUserId,
    required String reason,
  }) =>
      _dio.post('/api/interactions/reports/',
          data: {'reported_user': reportedUserId, 'reason': reason});
}

final upvoteRepositoryProvider = Provider<UpvoteRepository>(
  (ref) => UpvoteRepository(ref.read(dioProvider)),
);
