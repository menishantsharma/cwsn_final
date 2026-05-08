import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/widgets/app_bar.dart';
import 'package:frontend/core/theme/app_dimensions.dart';
import 'package:frontend/core/widgets/empty_state.dart';
import 'package:frontend/features/categories/domain/models/category_model.dart';
import 'package:frontend/features/categories/presentation/providers/category_provider.dart';
import 'package:frontend/features/categories/presentation/widgets/subcategory_card.dart';

class SubcategoriesPage extends ConsumerStatefulWidget {
  final CategoryModel category;

  const SubcategoriesPage({super.key, required this.category});

  @override
  ConsumerState<SubcategoriesPage> createState() => _SubcategoriesPageState();
}

class _SubcategoriesPageState extends ConsumerState<SubcategoriesPage> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels <
        _scrollController.position.maxScrollExtent - 200) { return; }
    final state = ref.read(subcategoryProvider(widget.category.id)).asData?.value;
    if (state == null || state.isLoadingMore || !state.hasMore) { return; }
    ref.read(subcategoryProvider(widget.category.id).notifier).loadMore();
  }

  @override
  Widget build(BuildContext context) {
    final subcategoriesAsync = ref.watch(subcategoryProvider(widget.category.id));

    return Scaffold(
      appBar: AppTopBar(title: widget.category.name),
      body: subcategoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (state) {
          if (state.items.isEmpty) {
            return const EmptyState(
              icon: Icons.list_outlined,
              title: 'No subcategories found',
              subtitle: 'This category has no subcategories yet',
            );
          }

          return CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                sliver: SliverList.separated(
                  itemCount: state.items.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppDimensions.spacing8),
                  itemBuilder: (context, index) =>
                      SubcategoryCard(subcategory: state.items[index]),
                ),
              ),
              if (state.isLoadingMore)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                )
              else
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          );
        },
      ),
    );
  }
}
