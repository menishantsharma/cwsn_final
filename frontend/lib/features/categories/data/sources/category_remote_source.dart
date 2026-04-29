import 'package:dio/dio.dart';
import 'package:frontend/features/categories/domain/models/category_model.dart';

class CategoryRemoteSource {
  final Dio _dio;

  CategoryRemoteSource(this._dio);

  Future<List<CategoryModel>> getCategories() async {
    final res = await _dio.get('/api/common/categories/');
    final result = res.data['results'] as List;
    return result.map((e) => CategoryModel.fromJson(e)).toList();
  }
}
