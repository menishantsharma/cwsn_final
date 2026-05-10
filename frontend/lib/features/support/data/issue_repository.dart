import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/providers/core_providers.dart';

class IssueRepository {
  final Dio _dio;
  IssueRepository(this._dio);

  Future<void> reportIssue(String description) =>
      _dio.post('/api/common/issues/', data: {'description': description});
}

final issueRepositoryProvider = Provider<IssueRepository>(
  (ref) => IssueRepository(ref.read(dioProvider)),
);
