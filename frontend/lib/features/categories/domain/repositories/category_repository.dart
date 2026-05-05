import 'package:frontend/features/categories/domain/models/category_model.dart';
import 'package:frontend/features/categories/domain/models/subcategory_model.dart';

abstract class CategoryRepository {
  Future<List<CategoryModel>> getCategories();
  Future<List<SubcategoryModel>> getSubcategories(int categoryId);
}