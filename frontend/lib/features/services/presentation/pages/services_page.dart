import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/theme/app_dimensions.dart';
import 'package:frontend/core/widgets/empty_state.dart';
import 'package:frontend/features/categories/domain/category_models.dart';
import 'package:frontend/features/services/presentation/controllers/service_controller.dart';
import 'package:frontend/features/services/presentation/widgets/add_service_card.dart';
import 'package:frontend/features/services/presentation/widgets/filter_sheet.dart';
import 'package:frontend/features/services/presentation/widgets/my_service_card.dart';
import 'package:frontend/features/services/presentation/widgets/service_card.dart';

class ServicesPage extends ConsumerStatefulWidget {
  final SubcategoryModel subcategory;

  const ServicesPage({super.key, required this.subcategory});

  @override
  ConsumerState<ServicesPage> createState() => _ServicesPageState();
}

class _ServicesPageState extends ConsumerState<ServicesPage> {
  final _scrollController = ScrollController();
  late final (int, int) _args;
  late final ServiceFilterNotifier _filterNotifier;

  @override
  void initState() {
    super.initState();
    _args = (widget.subcategory.categoryId, widget.subcategory.id);
    _filterNotifier = ref.read(serviceFilterProvider.notifier);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    Future.microtask(_filterNotifier.clearAll);
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels <
        _scrollController.position.maxScrollExtent - 200) { return; }
    final state = ref.read(serviceProvider(_args)).asData?.value;
    if (state == null || state.isLoadingMore || !state.hasMore) { return; }
    ref.read(serviceProvider(_args).notifier).loadMore();
  }

  @override
  Widget build(BuildContext context) {
    final servicesAsync = ref.watch(serviceProvider(_args));
    final myServiceAsync = ref.watch(myServiceProvider(_args));
    final filter = ref.watch(serviceFilterProvider);

    // Resolve myService without blocking the list — show nothing while loading
    final myServiceWidget = myServiceAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => AddServiceCard(subcategory: widget.subcategory),
      data: (myService) => myService != null
          ? MyServiceCard(service: myService)
          : AddServiceCard(subcategory: widget.subcategory),
    );

    return Scaffold(
      body: SafeArea(
        child: servicesAsync.when(
          loading: () =>
              const Center(child: CircularProgressIndicator(color: AppColors.primary)),
          error: (e, _) => const Center(child: Text('Something went wrong')),
          data: (state) {
            final isEmpty = state.items.isEmpty && !state.hasMore;

            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () => ref.read(serviceProvider(_args).notifier).refresh(),
              child: CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                clipBehavior: Clip.none,
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
                      widget.subcategory.name,
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
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    sliver: SliverList.separated(
                      itemCount: isEmpty ? 2 : state.items.length + 1,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppDimensions.spacing12),
                      itemBuilder: (context, index) {
                        if (index == 0) return myServiceWidget;
                        if (isEmpty) {
                          return const EmptyState(
                            icon: Icons.miscellaneous_services_outlined,
                            title: 'No services yet',
                            subtitle: 'Be the first to offer a service here',
                          );
                        }
                        return ServiceCard(service: state.items[index - 1]);
                      },
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
              ),
            );
          },
        ),
      ),
    );
  }
}
