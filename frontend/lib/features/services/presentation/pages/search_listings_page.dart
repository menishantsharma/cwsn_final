import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/pagination/load_more_button.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/theme/app_dimensions.dart';
import 'package:frontend/core/widgets/empty_state.dart';
import 'package:frontend/features/services/presentation/providers/service_provider.dart';
import 'package:frontend/features/services/presentation/widgets/filter_sheet.dart';
import 'package:frontend/features/services/presentation/widgets/service_card.dart';
import 'package:go_router/go_router.dart';

class SearchListingsPage extends ConsumerWidget {
  final String query;

  const SearchListingsPage({super.key, required this.query});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultsAsync = ref.watch(searchProvider(query));
    final filter = ref.watch(serviceFilterProvider);

    return Scaffold(
      body: SafeArea(
        child: resultsAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (_, _) => const Center(child: Text('Something went wrong')),
          data: (state) => CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                backgroundColor: Colors.white,
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.chevron_left, size: 28),
                  color: AppColors.textPrimary,
                  onPressed: () => context.pop(),
                ),
                title: Text(
                  '"$query"',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                actions: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.tune_rounded),
                        color: AppColors.textPrimary,
                        tooltip: 'Filter',
                        onPressed: () => showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.white,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(24),
                            ),
                          ),
                          builder: (_) => FilterSheet(initialFilter: filter),
                        ),
                      ),
                      if (filter.isActive)
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              state.items.isEmpty
                  ? SliverFillRemaining(
                      child: EmptyState(
                        icon: Icons.search_off_rounded,
                        title: 'No results found',
                        subtitle: 'Try a different keyword or adjust filters',
                      ),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      sliver: SliverList.separated(
                        itemCount: state.items.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AppDimensions.spacing12),
                        itemBuilder: (_, index) =>
                            ServiceCard(service: state.items[index]),
                      ),
                    ),
              SliverToBoxAdapter(
                child: state.hasMore
                    ? LoadMoreButton(
                        isLoading: state.isLoadingMore,
                        onPressed: () =>
                            ref.read(searchProvider(query).notifier).loadMore(),
                      )
                    : const SizedBox(height: 32),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
