import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/pagination/load_more_button.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/theme/app_dimensions.dart';
import 'package:frontend/core/theme/app_text_styles.dart';
import 'package:frontend/core/widgets/app_bar.dart';
import 'package:frontend/core/widgets/empty_state.dart';
import 'package:frontend/features/services/presentation/providers/service_provider.dart';
import 'package:frontend/features/services/presentation/widgets/my_service_card.dart';

class MyServicesPage extends ConsumerWidget {
  const MyServicesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servicesAsync = ref.watch(allMyServicesProvider);

    return Scaffold(
      appBar: const AppTopBar(title: 'My Services'),
      body: servicesAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(
          child: Text('Failed to load services', style: AppTextStyles.bodyMedium),
        ),
        data: (state) {
          if (state.items.isEmpty && !state.hasMore) {
            return const EmptyState(
              icon: Icons.home_repair_service_outlined,
              title: 'No services yet',
              subtitle: 'Services you offer will appear here',
            );
          }
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => ref.refresh(allMyServicesProvider.future),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              itemCount: state.items.length + (state.hasMore ? 1 : 0),
              itemBuilder: (context, i) {
                if (i == 0 && !state.hasMore) {
                  // header count shown only once, above the first card
                }
                if (i == state.items.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: AppDimensions.spacing8),
                    child: LoadMoreButton(
                      isLoading: state.isLoadingMore,
                      onPressed: () =>
                          ref.read(allMyServicesProvider.notifier).loadMore(),
                    ),
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (i == 0) ...[
                      Text(
                        '${state.items.length}${state.hasMore ? '+' : ''} service${state.items.length == 1 ? '' : 's'}',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spacing16),
                    ],
                    MyServiceCard(service: state.items[i]),
                    const SizedBox(height: AppDimensions.spacing12),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }
}
