import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/pagination/paginated_state.dart';
import 'package:frontend/features/requests/domain/request_models.dart';
import 'package:frontend/providers/core_providers.dart';

class RequestRepository {
  final Dio _dio;
  RequestRepository(this._dio);

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

  Future<PagedResponse<RequestModel>> getPendingRequests({int page = 1}) async {
    final res = await _dio.get(
      '/api/interactions/requests/',
      queryParameters: {'status': 'Pending', 'page': page},
    );
    final results = res.data['results'] as List;
    return PagedResponse(
      results: results.map((e) => RequestModel.fromJson(e)).toList(),
      hasMore: res.data['next'] != null,
    );
  }

  Future<PagedResponse<RequestModel>> getHistoryRequests({int page = 1}) async {
    final res = await _dio.get(
      '/api/interactions/requests/',
      queryParameters: {'status': 'history', 'page': page},
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

  Future<int> getPendingCount() async {
    final res = await _dio.get('/api/interactions/requests/pending_count/');
    return res.data['count'] as int;
  }

  Future<PagedResponse<RequestModel>> getRequestsAsParent({
    int? serviceId,
    int page = 1,
  }) async {
    final res = await _dio.get(
      '/api/interactions/requests/',
      queryParameters: {
        'as_parent': 'true',
        'page': page,
        'service': serviceId,
      }..removeWhere((_, v) => v == null),
    );
    final results = res.data['results'] as List;
    return PagedResponse(
      results: results.map((e) => RequestModel.fromJson(e)).toList(),
      hasMore: res.data['next'] != null,
    );
  }

  Future<RequestModel?> getRequestForCaregiver(int caregiverId) async {
    final res = await _dio.get(
      '/api/interactions/requests/',
      queryParameters: {'as_parent': 'true', 'caregiver': caregiverId},
    );
    final results = res.data['results'] as List;
    if (results.isEmpty) return null;
    final accepted = results.cast<Map<String, dynamic>>().where(
      (e) => e['status'] == 'Accepted',
    ).firstOrNull;
    return RequestModel.fromJson(accepted ?? results.first as Map<String, dynamic>);
  }
}

final requestRepositoryProvider = Provider<RequestRepository>(
  (ref) => RequestRepository(ref.read(dioProvider)),
);
