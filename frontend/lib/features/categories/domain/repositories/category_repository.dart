import 'package:frontend/core/pagination/paginated_state.dart';
import 'package:frontend/features/categories/domain/models/category_model.dart';
import 'package:frontend/features/categories/domain/models/subcategory_model.dart';

abstract class CategoryRepository {
  Future<PagedResponse<CategoryModel>> getCategories({int page = 1});
  Future<PagedResponse<SubcategoryModel>> getSubcategories(int categoryId, {int page = 1});
}