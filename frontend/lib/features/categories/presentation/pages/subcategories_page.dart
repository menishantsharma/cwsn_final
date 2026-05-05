import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/widgets/app_bar.dart';
import 'package:frontend/core/theme/app_dimensions.dart';
import 'package:frontend/core/widgets/empty_state.dart';
import 'package:frontend/features/categories/domain/models/category_model.dart';
import 'package:frontend/features/categories/presentation/providers/category_provider.dart';
import 'package:frontend/features/categories/presentation/widgets/subcategory_card.dart';

class SubcategoriesPage extends ConsumerWidget {
  final CategoryModel category;

  const SubcategoriesPage({super.key, required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subcategoriesAsync = ref.watch(subcategoryProvider(category.id));

    return Scaffold(
      appBar: AppTopBar(title: category.name),
      body: subcategoriesAsync.when(
        data: (subcategoes) {
          if (subcategoes.isEmpty) {
            return EmptyState(
              icon: Icons.list_outlined,
              title: 'No subcategories found',
              subtitle: 'This category has no subcategories yet',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            itemCount: subcategoes.length,
            separatorBuilder: (_, _) =>
                const SizedBox(height: AppDimensions.spacing8),
            itemBuilder: (context, index) =>
                SubcategoryCard(subcategory: subcategoes[index]),
          );
        },
        error: (stack, sd) {
          return Text('Error');
        },
        loading: () {
          return CircularProgressIndicator();
        },
      ),
    );
  }
}
