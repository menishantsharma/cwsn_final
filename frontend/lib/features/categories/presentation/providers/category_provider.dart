import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/pagination/paginated_state.dart';
import 'package:frontend/features/categories/data/repositories/category_repository_impl.dart';
import 'package:frontend/features/categories/data/sources/category_remote_source.dart';
import 'package:frontend/features/categories/domain/models/category_model.dart';
import 'package:frontend/features/categories/domain/models/subcategory_model.dart';
import 'package:frontend/features/categories/domain/repositories/category_repository.dart';
import 'package:frontend/providers/core_providers.dart';

final categoryRemoteSourceProvider = Provider<CategoryRemoteSource>(
  (ref) => CategoryRemoteSource(ref.watch(dioProvider)),
);

final categoryRepositoryProvider = Provider<CategoryRepository>(
  (ref) => CategoryRepositoryImpl(ref.watch(categoryRemoteSourceProvider)),
);

class CategoryNotifier extends PaginatedNotifier<CategoryModel> {
  @override
  Future<PaginatedState<CategoryModel>> build() {
    ref.keepAlive();
    return super.build();
  }

  @override
  Future<PagedResponse<CategoryModel>> fetchPage(int page) async {
    return await ref.read(categoryRepositoryProvider).getCategories(page: page);
  }
}

final categoryProvider =
    AsyncNotifierProvider<CategoryNotifier, PaginatedState<CategoryModel>>(
      CategoryNotifier.new,
    );

class SubcategoryNotifier extends PaginatedFamilyNotifier<SubcategoryModel, int> {
  final int categoryId;

  @override
  int get arg => categoryId;

  SubcategoryNotifier(this.categoryId);

  @override
  Future<PaginatedState<SubcategoryModel>> build() {
    ref.keepAlive();
    return super.build();
  }

  @override
  Future<PagedResponse<SubcategoryModel>> fetchPage(int categoryId, int page) async {
    return ref.read(categoryRepositoryProvider).getSubcategories(categoryId, page: page);
  }
}

final subcategoryProvider =
    AsyncNotifierProvider.family<
      SubcategoryNotifier,
      PaginatedState<SubcategoryModel>,
      int
    >(SubcategoryNotifier.new);
