import 'package:dio/dio.dart';
import 'package:frontend/features/requests/domain/models/request_model.dart';

class RequestRemoteSource {
  final Dio _dio;

  RequestRemoteSource(this._dio);

  Future<List<RequestModel>> getRequests() async {
    final res = await _dio.get('/api/interactions/requests/');
    final results = res.data['results'] as List;
    return results.map((e) => RequestModel.fromJson(e)).toList();
  }

  Future<RequestModel> acceptRequest(int id) async {
    final res = await _dio.post('/api/interactions/requests/$id/accept/');
    return RequestModel.fromJson(res.data);
  }

  Future<RequestModel> rejectRequest(int id) async {
    final res = await _dio.post('/api/interactions/requests/$id/reject/');
    return RequestModel.fromJson(res.data);
  }
}
