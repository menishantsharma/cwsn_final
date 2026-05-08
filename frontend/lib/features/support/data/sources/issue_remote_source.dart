import 'package:dio/dio.dart';

class IssueRemoteSource {
  final Dio _dio;
  IssueRemoteSource(this._dio);

  Future<void> reportIssue(String description) async {
    await _dio.post(
      '/api/common/issues/',
      data: {'description': description},
    );
  }
}
