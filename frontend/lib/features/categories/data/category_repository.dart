import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/pagination/paginated_state.dart';
import 'package:frontend/features/categories/domain/category_models.dart';
import 'package:frontend/providers/core_providers.dart';

class CategoryRepository {
  final Dio _dio;
  CategoryRepository(this._dio);

  Future<PagedResponse<CategoryModel>> getCategories({int page = 1}) async {
    final res = await _dio.get(
      '/api/common/categories/',
      queryParameters: {'page': page},
    );
    final results = res.data['results'];
    return PagedResponse(
      results: results == null
          ? []
          : (results as List).map((e) => CategoryModel.fromJson(e)).toList(),
      hasMore: res.data['next'] != null,
    );
  }

  Future<PagedResponse<SubcategoryModel>> getSubcategories(
    int categoryId, {
    int page = 1,
  }) async {
    final res = await _dio.get(
      '/api/common/subcategories/',
      queryParameters: {'category': categoryId, 'page': page},
    );
    final results = res.data['results'];
    return PagedResponse(
      results: results == null
          ? []
          : (results as List).map((e) => SubcategoryModel.fromJson(e)).toList(),
      hasMore: res.data['next'] != null,
    );
  }
}

final categoryRepositoryProvider = Provider<CategoryRepository>(
  (ref) => CategoryRepository(ref.read(dioProvider)),
);
