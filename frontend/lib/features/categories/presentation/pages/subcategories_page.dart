import 'package:flutter/material.dart';
import 'package:frontend/core/widgets/app_bar.dart';
import 'package:frontend/core/theme/app_dimensions.dart';
import 'package:frontend/core/widgets/empty_state.dart';
import 'package:frontend/features/categories/domain/models/category_model.dart';
import 'package:frontend/features/categories/presentation/widgets/subcategory_card.dart';

class SubcategoriesPage extends StatelessWidget {
  final CategoryModel category;

  const SubcategoriesPage({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final subcategories = category.subcategories;

    return Scaffold(
      appBar: AppTopBar(title: category.name),
      body: subcategories.isEmpty
          ? const EmptyState(
              icon: Icons.list_outlined,
              title: 'No subcategories found',
              subtitle: 'This category has no subcategories yet',
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              itemCount: subcategories.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppDimensions.spacing8),
              itemBuilder: (context, index) => SubcategoryCard(subcategory: subcategories[index]),
            ),
    );
  }
}
