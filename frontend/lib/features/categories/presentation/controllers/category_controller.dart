import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/pagination/paginated_state.dart';
import 'package:frontend/features/auth/presentation/controllers/auth_controller.dart';
import 'package:frontend/features/categories/data/category_repository.dart';
import 'package:frontend/features/categories/domain/category_models.dart';

class CategoryNotifier extends PaginatedNotifier<CategoryModel> {
  @override
  Future<PaginatedState<CategoryModel>> build() {
    ref.clearOnLogout();
    ref.keepAlive();
    return super.build();
  }

  @override
  Future<PagedResponse<CategoryModel>> fetchPage(int page) =>
      ref.read(categoryRepositoryProvider).getCategories(page: page);
}

final categoryProvider =
    AsyncNotifierProvider<CategoryNotifier, PaginatedState<CategoryModel>>(
      CategoryNotifier.new,
    );

class SubcategoryNotifier extends PaginatedFamilyNotifier<SubcategoryModel, int> {
  final int categoryId;

  SubcategoryNotifier(this.categoryId);

  @override
  int get arg => categoryId;

  @override
  Future<PaginatedState<SubcategoryModel>> build() {
    ref.clearOnLogout();
    ref.keepAlive();
    return super.build();
  }

  @override
  Future<PagedResponse<SubcategoryModel>> fetchPage(int categoryId, int page) =>
      ref.read(categoryRepositoryProvider).getSubcategories(categoryId, page: page);
}

final subcategoryProvider =
    AsyncNotifierProvider.family<
      SubcategoryNotifier,
      PaginatedState<SubcategoryModel>,
      int
    >(SubcategoryNotifier.new);
