import 'package:dio/dio.dart';
import 'package:frontend/features/categories/domain/models/category_model.dart';
import 'package:frontend/features/categories/domain/models/subcategory_model.dart';

class CategoryRemoteSource {
  final Dio _dio;

  CategoryRemoteSource(this._dio);

  Future<List<CategoryModel>> getCategories() async {
    final res = await _dio.get('/api/common/categories/');
    final results = res.data['results'];
    if (results == null) return [];
    return (results as List)
        .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<SubcategoryModel>> getSubcategories(int categoryId) async {
    final res = await _dio.get(
      '/api/common/subcategories/?category=$categoryId',
    );
    final results = res.data['results'];
    if (results == null) return [];
    return (results as List)
        .map((e) => SubcategoryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
