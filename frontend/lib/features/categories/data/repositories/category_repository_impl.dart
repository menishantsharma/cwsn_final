import 'package:frontend/features/categories/data/sources/category_remote_source.dart';
import 'package:frontend/features/categories/domain/models/category_model.dart';
import 'package:frontend/features/categories/domain/models/subcategory_model.dart';
import 'package:frontend/features/categories/domain/repositories/category_repository.dart';

class CategoryRepositoryImpl extends CategoryRepository {
  final CategoryRemoteSource _source;
  CategoryRepositoryImpl(this._source);

  @override
  Future<List<CategoryModel>> getCategories() => _source.getCategories();

  @override
  Future<List<SubcategoryModel>> getSubcategories(int categoryId) =>
      _source.getSubcategories(categoryId);
}
