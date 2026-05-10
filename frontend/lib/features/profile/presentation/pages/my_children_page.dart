import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/theme/app_dimensions.dart';
import 'package:frontend/core/theme/app_text_styles.dart';
import 'package:frontend/core/widgets/app_bar.dart';
import 'package:frontend/core/widgets/confirm_dialog.dart';
import 'package:frontend/core/widgets/empty_state.dart';
import 'package:frontend/features/profile/domain/profile_models.dart';
import 'package:frontend/features/profile/presentation/controllers/profile_controller.dart';
import 'package:frontend/features/profile/presentation/widgets/add_child_sheet.dart';

class MyChildrenPage extends ConsumerWidget {
  const MyChildrenPage({super.key});

  void _showAddChildSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusXl),
        ),
      ),
      builder: (_) => AddChildSheet(
        onSave: (data) => ref.read(profileProvider.notifier).addChild(data),
      ),
    );
  }

  void _showEditChildSheet(
    BuildContext context,
    WidgetRef ref,
    ChildProfileModel child,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusXl),
        ),
      ),
      builder: (_) => AddChildSheet(
        initial: child,
        onSave: (data) =>
            ref.read(profileProvider.notifier).updateChild(child.id, data),
      ),
    );
  }

  void _confirmDeleteChild(
    BuildContext context,
    WidgetRef ref,
    ChildProfileModel child,
  ) {
    showDialog(
      context: context,
      builder: (_) => ConfirmDialog(
        title: 'Remove child?',
        message: '${child.name} will be removed from your profile.',
        confirmLabel: 'Remove',
        isDanger: true,
        onConfirm: () => ref.read(profileProvider.notifier).deleteChild(child.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      appBar: const AppTopBar(title: 'My Children'),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddChildSheet(context, ref),
        backgroundColor: AppColors.primary,
        elevation: 2,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: profileAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(
          child: Text('Failed to load profile', style: AppTextStyles.bodyMedium),
        ),
        data: (profile) {
          final children = profile.cwsnProfile?.children ?? [];

          if (children.isEmpty) {
            return const EmptyState(
              icon: Icons.child_care_outlined,
              title: 'No children added',
              subtitle: 'Tap + to add your first child',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
            itemCount: children.length,
            separatorBuilder: (_, _) =>
                const SizedBox(height: AppDimensions.spacing8),
            itemBuilder: (context, i) {
              final child = children[i];
              return _ChildCard(
                child: child,
                onEdit: () => _showEditChildSheet(context, ref, child),
                onDelete: () => _confirmDeleteChild(context, ref, child),
              );
            },
          );
        },
      ),
    );
  }
}

class _ChildCard extends StatelessWidget {
  final ChildProfileModel child;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ChildCard({
    required this.child,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        child: InkWell(
          onTap: onEdit,
          borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spacing16,
              vertical: AppDimensions.spacing12,
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                  ),
                  child: Center(
                    child: Text(
                      child.name[0].toUpperCase(),
                      style: AppTextStyles.titleSmall.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppDimensions.spacing12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        child.name,
                        style: AppTextStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${child.age} yrs · ${child.gender}',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: onDelete,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.error,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text('Remove', style: AppTextStyles.labelSmall.copyWith(color: AppColors.error)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
