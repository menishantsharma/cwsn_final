import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/theme/app_dimensions.dart';
import 'package:frontend/core/widgets/empty_state.dart';
import 'package:frontend/features/categories/presentation/providers/category_provider.dart';
import 'package:frontend/features/categories/presentation/widgets/categories_header.dart';
import 'package:frontend/features/categories/presentation/widgets/category_card.dart';

class CategoriesPage extends ConsumerWidget {
  const CategoriesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoryProvider);

    return Scaffold(
      body: SafeArea(
        child: categoriesAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (error, _) => Center(
            child: Text('Error: $error'),
          ),
          data: (categories) {
            if (categories.isEmpty) {
              return const EmptyState(
                icon: Icons.category_outlined,
                title: 'No categories available',
                subtitle: 'Please check back later',
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 32, 20, 32),
              itemCount: categories.length + 1,
              separatorBuilder: (_, i) => SizedBox(
                height: i == 0 ? AppDimensions.spacing20 : AppDimensions.spacing8,
              ),
              itemBuilder: (context, index) {
                if (index == 0) return const CategoriesHeader();
                return CategoryCard(category: categories[index - 1]);
              },
            );
          },
        ),
      ),
    );
  }
}
