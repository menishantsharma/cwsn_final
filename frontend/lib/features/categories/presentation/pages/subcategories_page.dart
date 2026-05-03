import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/theme/app_dimensions.dart';
import 'package:frontend/core/widgets/empty_state.dart';
import 'package:frontend/features/categories/domain/models/category_model.dart';
import 'package:frontend/features/categories/presentation/widgets/subcategories_header.dart';
import 'package:frontend/features/categories/presentation/widgets/subcategory_card.dart';

class SubcategoriesPage extends StatelessWidget {
  final CategoryModel category;

  const SubcategoriesPage({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final subcategories = category.subcategories;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: subcategories.isEmpty
          ? const EmptyState(
              icon: Icons.list_outlined,
              title: 'No subcategories found',
              subtitle: 'This category has no subcategories yet',
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              itemCount: subcategories.length + 1,
              separatorBuilder: (_, i) => SizedBox(
                height: i == 0 ? AppDimensions.spacing20 : AppDimensions.spacing8,
              ),
              itemBuilder: (context, index) {
                if (index == 0) return SubcategoriesHeader(category: category);
                return SubcategoryCard(subcategory: subcategories[index - 1]);
              },
            ),
    );
  }
}
