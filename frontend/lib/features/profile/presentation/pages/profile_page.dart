import 'package:flutter/material.dart';
import 'package:frontend/core/widgets/app_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/app/app_router.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/theme/app_dimensions.dart';
import 'package:frontend/core/theme/app_text_styles.dart';
import 'package:frontend/core/widgets/confirm_dialog.dart';
import 'package:frontend/features/auth/presentation/providers/auth_provider.dart';
import 'package:frontend/features/profile/domain/models/profile_model.dart';
import 'package:frontend/features/profile/presentation/providers/profile_provider.dart';
import 'package:frontend/features/profile/presentation/widgets/add_child_sheet.dart';
import 'package:frontend/features/profile/presentation/widgets/child_row.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

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

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => ConfirmDialog(
        title: 'Log out?',
        message: 'You will be signed out of your account.',
        confirmLabel: 'Log out',
        isDanger: false,
        onConfirm: () => ref.read(authProvider.notifier).logout(),
      ),
    );
  }

  void _confirmDeleteAccount(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => ConfirmDialog(
        title: 'Delete account?',
        message:
            'This permanently deletes your account and all data. This cannot be undone.',
        confirmLabel: 'Delete',
        isDanger: true,
        onConfirm: () => ref.read(profileProvider.notifier).deleteAccount(),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      appBar: const AppTopBar(title: 'Profile'),
      body: profileAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(
          child: Text('Failed to load profile', style: AppTextStyles.bodyMedium),
        ),
        data: (profile) {
          final name = profile.cwsnProfile?.name ?? '';
          final phone = profile.cwsnProfile?.phoneNumber;
          final children = profile.cwsnProfile?.children ?? [];

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 48),
            children: [
              // ── Hero header ──────────────────────────────
              Column(
                children: [
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: AppTextStyles.displaySmall.copyWith(
                        color: AppColors.primary,
                        fontSize: 36,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacing12),
                  Text(name, style: AppTextStyles.titleLarge),
                  if (phone != null && phone.isNotEmpty) ...[
                    const SizedBox(height: AppDimensions.spacing4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.phone_outlined,
                          size: 13,
                          color: AppColors.textHint,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          phone,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),

              const SizedBox(height: AppDimensions.spacing32),

              // ── Account section ──────────────────────────
              _SectionLabel('Account'),
              const SizedBox(height: AppDimensions.spacing8),
              _MenuGroup(
                children: [
                  _MenuRow(
                    icon: Icons.person_outline_rounded,
                    label: 'Personal Info',
                    onTap: () => context.push(AppRoutes.editPersonalInfo),
                  ),
                  _MenuRow(
                    icon: Icons.medical_services_outlined,
                    label: 'Caregiver Info',
                    onTap: () => context.push(AppRoutes.editCaregiverInfo),
                  ),
                  _MenuRow(
                    icon: Icons.home_repair_service_outlined,
                    label: 'My Services',
                    onTap: () => context.push(AppRoutes.myServices),
                  ),
                ],
              ),

              const SizedBox(height: AppDimensions.spacing24),

              // ── Children section ─────────────────────────
              _SectionLabel('Children'),
              const SizedBox(height: AppDimensions.spacing8),
              _MenuGroup(
                children: [
                  if (children.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.spacing16,
                        vertical: AppDimensions.spacing16,
                      ),
                      child: Text(
                        'No children added yet',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textHint,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    )
                  else
                    ...children.map(
                      (child) => Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.spacing16,
                          vertical: AppDimensions.spacing4,
                        ),
                        child: ChildRow(
                          child: child,
                          onEdit: () => _showEditChildSheet(context, ref, child),
                          onDelete: () =>
                              _confirmDeleteChild(context, ref, child),
                        ),
                      ),
                    ),
                  const Divider(height: 1, color: AppColors.border),
                  _MenuRow(
                    icon: Icons.add_rounded,
                    label: 'Add Child',
                    iconColor: AppColors.primary,
                    labelColor: AppColors.primary,
                    showChevron: false,
                    onTap: () => _showAddChildSheet(context, ref),
                  ),
                ],
              ),

              const SizedBox(height: AppDimensions.spacing24),

              // ── Account actions ──────────────────────────
              _SectionLabel('Account Actions'),
              const SizedBox(height: AppDimensions.spacing8),
              _MenuGroup(
                children: [
                  _MenuRow(
                    icon: Icons.logout_rounded,
                    label: 'Log out',
                    onTap: () => _confirmLogout(context, ref),
                  ),
                  _MenuRow(
                    icon: Icons.delete_outline_rounded,
                    label: 'Delete Account',
                    iconColor: AppColors.error,
                    labelColor: AppColors.error,
                    onTap: () => _confirmDeleteAccount(context, ref),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
      child: Text(
        text.toUpperCase(),
        style: AppTextStyles.labelSmall.copyWith(
          color: AppColors.textSecondary,
          letterSpacing: 0.8,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _MenuGroup extends StatelessWidget {
  final List<Widget> children;
  const _MenuGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: _withDividers(children),
      ),
    );
  }

  List<Widget> _withDividers(List<Widget> items) {
    final result = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      result.add(items[i]);
      // don't add a divider after an item that is itself a Divider
      if (i < items.length - 1 && items[i] is! Divider) {
        final next = items[i + 1];
        if (next is! Divider) {
          result.add(const Divider(
            height: 1,
            indent: 52,
            color: AppColors.border,
          ));
        }
      }
    }
    return result;
  }
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color iconColor;
  final Color labelColor;
  final bool showChevron;

  const _MenuRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor = AppColors.textSecondary,
    this.labelColor = AppColors.textPrimary,
    this.showChevron = true,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacing16,
          vertical: 14,
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
              ),
              child: Icon(icon, size: 17, color: iconColor),
            ),
            const SizedBox(width: AppDimensions.spacing12),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  color: labelColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (showChevron)
              const Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: AppColors.textHint,
              ),
          ],
        ),
      ),
    );
  }
}
