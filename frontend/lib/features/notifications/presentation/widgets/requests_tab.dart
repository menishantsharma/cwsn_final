import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/theme/app_dimensions.dart';
import 'package:frontend/core/theme/app_text_styles.dart';
import 'package:frontend/core/widgets/empty_state.dart';
import 'package:frontend/features/notifications/presentation/widgets/request_card.dart';
import 'package:frontend/features/notifications/presentation/widgets/section_label.dart';
import 'package:frontend/features/requests/domain/models/request_model.dart';
import 'package:frontend/features/requests/presentation/providers/request_provider.dart';

class RequestsTab extends ConsumerWidget {
  const RequestsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(pendingRequestCountProvider);
    if (pending == 0) return const Tab(text: 'Requests');
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Requests'),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
            ),
            child: Text(
              '$pending',
              style: AppTextStyles.labelSmall.copyWith(
                color: Colors.white,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RequestsTabView extends ConsumerStatefulWidget {
  const RequestsTabView({super.key});

  @override
  ConsumerState<RequestsTabView> createState() => _RequestsTabViewState();
}

class _RequestsTabViewState extends ConsumerState<RequestsTabView> {
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
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(requestProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final requestsAsync = ref.watch(requestProvider);

    return requestsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (e, _) =>
          Center(child: Text('Error: $e', style: AppTextStyles.bodyMedium)),
      data: (state) {
        if (state.items.isEmpty && !state.hasMore) {
          return const EmptyState(
            icon: Icons.handshake_outlined,
            title: 'No requests yet',
            subtitle: 'Incoming service requests will appear here',
          );
        }

        final pending =
            state.items.where((r) => r.status == 'Pending').toList();
        final history =
            state.items.where((r) => r.status != 'Pending').toList();

        // Build a flat list of widgets for the sliver delegate
        final items = <_ListItem>[];
        if (pending.isNotEmpty) {
          items.add(_HeaderItem('Pending'));
          items.addAll(pending.map(_RequestItem.new));
        }
        if (history.isNotEmpty) {
          items.add(_HeaderItem('History'));
          items.addAll(history.map(_RequestItem.new));
        }
        if (state.isLoadingMore) items.add(_LoadingItem());

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => ref.read(requestProvider.notifier).refresh(),
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final item = items[i];
                      if (item is _HeaderItem) {
                        return Padding(
                          padding: EdgeInsets.only(
                            top: i == 0 ? 0 : AppDimensions.spacing8,
                            bottom: AppDimensions.spacing12,
                          ),
                          child: SectionLabel(item.label),
                        );
                      }
                      if (item is _RequestItem) {
                        return Padding(
                          padding: const EdgeInsets.only(
                              bottom: AppDimensions.spacing8),
                          child: RequestCard(request: item.request),
                        );
                      }
                      // _LoadingItem
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
                    },
                    childCount: items.length,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

sealed class _ListItem {}

class _HeaderItem extends _ListItem {
  final String label;
  _HeaderItem(this.label);
}

class _RequestItem extends _ListItem {
  final RequestModel request;
  _RequestItem(this.request);
}

class _LoadingItem extends _ListItem {}
