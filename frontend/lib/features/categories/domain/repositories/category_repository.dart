import 'package:frontend/features/categories/domain/models/category_model.dart';

abstract class CategoryRepository {
  Future<List<CategoryModel>> getCategories();
}