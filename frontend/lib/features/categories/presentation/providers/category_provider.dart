import 'package:flutter_riverpod/flutter_riverpod.dart';
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

class CategoryNotifier extends AsyncNotifier<List<CategoryModel>> {
  @override
  Future<List<CategoryModel>> build() async {
    ref.keepAlive();
    return ref.watch(categoryRepositoryProvider).getCategories();
  }
}

final categoryProvider =
    AsyncNotifierProvider<CategoryNotifier, List<CategoryModel>>(
      CategoryNotifier.new,
    );

class SubcategoryNotifier extends AsyncNotifier<List<SubcategoryModel>> {
  final int categoryId;
  SubcategoryNotifier(this.categoryId);

  @override
  Future<List<SubcategoryModel>> build() async {
    ref.keepAlive();
    return ref.watch(categoryRepositoryProvider).getSubcategories(categoryId);
  }
}

final subcategoryProvider =
    AsyncNotifierProvider.family<
      SubcategoryNotifier,
      List<SubcategoryModel>,
      int
    >(SubcategoryNotifier.new);
