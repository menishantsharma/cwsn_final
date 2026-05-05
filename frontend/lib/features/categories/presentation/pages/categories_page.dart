import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/pagination/load_more_button.dart';
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
          error: (error, _) => Center(child: Text('Error: $error')),
          data: (state) {
            if (state.items.isEmpty) {
              return const EmptyState(
                icon: Icons.category_outlined,
                title: 'No categories available',
                subtitle: 'Please check back later',
              );
            }

            return CustomScrollView(
              slivers: [
                SliverAppBar(
                  floating: true,
                  snap: true,
                  backgroundColor: Colors.white,
                  surfaceTintColor: Colors.transparent,
                  elevation: 0,
                  expandedHeight: 120,
                  flexibleSpace: const FlexibleSpaceBar(
                    collapseMode: CollapseMode.none,
                    background: Padding(
                      padding: EdgeInsets.fromLTRB(20, 32, 20, 0),
                      child: CategoriesHeader(),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                  sliver: SliverList.separated(
                    itemCount: state.items.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppDimensions.spacing12),
                    itemBuilder: (context, index) => CategoryCard(
                      category: state.items[index],
                      index: index,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: state.hasMore
                      ? LoadMoreButton(
                          isLoading: state.isLoadingMore,
                          onPressed: () =>
                              ref.read(categoryProvider.notifier).loadMore(),
                        )
                      : const SizedBox(height: 32),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
