import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/features/categories/domain/models/subcategory_model.dart';
import 'package:frontend/features/services/presentation/providers/service_provider.dart';
import 'package:frontend/features/services/presentation/widgets/add_service_card.dart';
import 'package:frontend/features/services/presentation/widgets/filter_sheet.dart';
import 'package:frontend/features/services/presentation/widgets/my_service_card.dart';
import 'package:frontend/features/services/presentation/widgets/service_card.dart';
import 'package:frontend/features/services/presentation/widgets/services_header.dart';

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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
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
            data: (myService) => ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              itemCount: services.length + 2,
              separatorBuilder: (_, i) => SizedBox(
                height: i == 0 ? 20 : 8,
              ),
              itemBuilder: (context, index) {
                if (index == 0) return ServicesHeader(subcategory: subcategory);
                if (index == 1) {
                  return myService != null
                      ? MyServiceCard(service: myService)
                      : AddServiceCard(subcategory: subcategory);
                }
                return ServiceCard(service: services[index - 2]);
              },
            ),
          ),
        ),
      ),
    );
  }
}
