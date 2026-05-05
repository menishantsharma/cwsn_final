import 'package:dio/dio.dart';
import 'package:frontend/core/pagination/paginated_state.dart';
import 'package:frontend/features/categories/domain/models/category_model.dart';
import 'package:frontend/features/categories/domain/models/subcategory_model.dart';

class CategoryRemoteSource {
  final Dio _dio;

  CategoryRemoteSource(this._dio);

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
