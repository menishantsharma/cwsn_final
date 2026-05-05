import 'package:frontend/core/pagination/paginated_state.dart';
import 'package:frontend/features/categories/data/sources/category_remote_source.dart';
import 'package:frontend/features/categories/domain/models/category_model.dart';
import 'package:frontend/features/categories/domain/models/subcategory_model.dart';
import 'package:frontend/features/categories/domain/repositories/category_repository.dart';

class CategoryRepositoryImpl extends CategoryRepository {
  final CategoryRemoteSource _source;
  CategoryRepositoryImpl(this._source);

  @override
  Future<PagedResponse<CategoryModel>> getCategories({int page = 1}) => _source.getCategories(page: page);

  @override
  Future<PagedResponse<SubcategoryModel>> getSubcategories(int categoryId, {int page = 1}) =>
      _source.getSubcategories(categoryId, page: page);
}
