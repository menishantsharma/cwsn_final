import 'package:dio/dio.dart';
import 'package:frontend/core/pagination/paginated_state.dart';
import 'package:frontend/features/requests/domain/models/request_model.dart';

class RequestRemoteSource {
  final Dio _dio;

  RequestRemoteSource(this._dio);

  Future<PagedResponse<RequestModel>> getRequests({int page = 1}) async {
    final res = await _dio.get(
      '/api/interactions/requests/',
      queryParameters: {'page': page},
    );

    final results = res.data['results'] as List;

    return PagedResponse(
      results: results.map((e) => RequestModel.fromJson(e)).toList(),
      hasMore: res.data['next'] != null,
    );
  }

  Future<RequestModel> acceptRequest(int id) async {
    final res = await _dio.post('/api/interactions/requests/$id/accept/');
    return RequestModel.fromJson(res.data);
  }

  Future<RequestModel> rejectRequest(int id) async {
    final res = await _dio.post('/api/interactions/requests/$id/reject/');
    return RequestModel.fromJson(res.data);
  }

  Future<RequestModel> createRequest({
    required int serviceId,
    required int childId,
    String? note,
  }) async {
    final res = await _dio.post(
      '/api/interactions/requests/',
      data: {
        'service': serviceId,
        'child': childId,
        if (note != null && note.isNotEmpty) 'note': note,
      },
    );
    return RequestModel.fromJson(res.data);
  }

  Future<PagedResponse<RequestModel>> getRequestsAsParent({
    int? serviceId,
    int page = 1,
  }) async {
    final res = await _dio.get(
      '/api/interactions/requests/',
      queryParameters: {
        'as_parent': 'true',
        if (serviceId != null) 'service': serviceId,
        'page': page,
      },
    );
    final results = res.data['results'] as List;
    return PagedResponse(
      results: results.map((e) => RequestModel.fromJson(e)).toList(),
      hasMore: res.data['next'] != null,
    );
  }
}
