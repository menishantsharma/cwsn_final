import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/theme/app_dimensions.dart';
import 'package:frontend/core/widgets/empty_state.dart';
import 'package:frontend/features/categories/domain/models/subcategory_model.dart';
import 'package:frontend/features/services/presentation/providers/service_provider.dart';
import 'package:frontend/features/services/presentation/widgets/add_service_card.dart';
import 'package:frontend/features/services/presentation/widgets/filter_sheet.dart';
import 'package:frontend/features/services/presentation/widgets/my_service_card.dart';
import 'package:frontend/features/services/presentation/widgets/service_card.dart';

class ServicesPage extends ConsumerWidget {
  final SubcategoryModel subcategory;

  const ServicesPage({super.key, required this.subcategory});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final args = (subcategory.categoryId, subcategory.id);
    final servicesAsync = ref.watch(serviceProvider(args));
    final myServiceAsync = ref.watch(myServiceProvider(args));
    final filter = ref.watch(serviceFilterProvider);

    return Scaffold(
      body: SafeArea(
        child: servicesAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (e, _) => const Center(child: Text('Something went wrong')),
          data: (services) => myServiceAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
            error: (e, _) => const Center(child: Text('Something went wrong')),
            data: (myService) {
              final firstItem = myService != null
                  ? MyServiceCard(service: myService)
                  : AddServiceCard(subcategory: subcategory);

              final isEmpty = services.isEmpty && myService == null;

              return CustomScrollView(
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
                      subcategory.name,
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
                                    top: Radius.circular(24)),
                              ),
                              builder: (_) =>
                                  FilterSheet(initialFilter: filter),
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
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                    sliver: SliverList.separated(
                      itemCount: isEmpty ? 2 : services.length + 1,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppDimensions.spacing12),
                      itemBuilder: (context, index) {
                        if (index == 0) return firstItem;
                        if (isEmpty) {
                          return const EmptyState(
                            icon: Icons.miscellaneous_services_outlined,
                            title: 'No services yet',
                            subtitle: 'Be the first to offer a service here',
                          );
                        }
                        return ServiceCard(service: services[index - 1]);
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
