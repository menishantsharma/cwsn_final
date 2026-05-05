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
      backgroundColor: Colors.white,
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
                // Greeting — scrolls away
                const SliverToBoxAdapter(child: CategoriesGreeting()),

                // Search bar — pinned
                const SliverPersistentHeader(
                  pinned: true,
                  delegate: _SearchBarDelegate(),
                ),

                // Category list
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
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

class _SearchBarDelegate extends SliverPersistentHeaderDelegate {
  const _SearchBarDelegate();

  // height = 8 (top pad) + 44 (bar) + 12 (bottom pad)
  static const double _height = 64;

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return const CategoriesSearchBar();
  }

  @override
  bool shouldRebuild(_SearchBarDelegate old) => false;
}
