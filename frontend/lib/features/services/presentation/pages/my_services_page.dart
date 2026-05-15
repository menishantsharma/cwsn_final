import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/theme/app_dimensions.dart';
import 'package:frontend/core/theme/app_text_styles.dart';
import 'package:frontend/core/widgets/app_bar.dart';
import 'package:frontend/core/widgets/empty_state.dart';
import 'package:frontend/features/services/presentation/controllers/service_controller.dart';
import 'package:frontend/features/services/presentation/widgets/my_service_card.dart';

class MyServicesPage extends ConsumerStatefulWidget {
  const MyServicesPage({super.key});

  @override
  ConsumerState<MyServicesPage> createState() => _MyServicesPageState();
}

class _MyServicesPageState extends ConsumerState<MyServicesPage> {
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
    final state = ref.read(allMyServicesProvider).asData?.value;
    if (state == null || state.isLoadingMore || !state.hasMore) { return; }
    ref.read(allMyServicesProvider.notifier).loadMore();
  }

  @override
  Widget build(BuildContext context) {
    final servicesAsync = ref.watch(allMyServicesProvider);

    return Scaffold(
      appBar: const AppTopBar(title: 'My Services'),
      body: servicesAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => ref.read(allMyServicesProvider.notifier).refresh(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.6,
              child: Center(
                child: Text('Could not load your services. Pull to refresh.', style: AppTextStyles.bodyMedium),
              ),
            ),
          ),
        ),
        data: (state) {
          if (state.items.isEmpty && !state.hasMore) {
            return EmptyState(
              icon: Icons.home_repair_service_outlined,
              title: 'No services yet',
              subtitle: 'Services you offer will appear here',
              onRefresh: () => ref.read(allMyServicesProvider.notifier).refresh(),
            );
          }
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => ref.read(allMyServicesProvider.notifier).refresh(),
            child: ListView.builder(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              itemCount: state.items.length + (state.isLoadingMore ? 1 : 0),
              itemBuilder: (context, i) {
                if (i == state.items.length) {
                  return const Padding(
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
