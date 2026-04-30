import 'package:dio/dio.dart';
import 'package:frontend/features/interactions/domain/models/upvote_model.dart';

class UpvoteRemoteSource {
  final Dio _dio;
  UpvoteRemoteSource(this._dio);

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

  Future<void> removeUpvote(int upvoteId) async {
    await _dio.delete('/api/interactions/upvotes/$upvoteId/');
  }
}
