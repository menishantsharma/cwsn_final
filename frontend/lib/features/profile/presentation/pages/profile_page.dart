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
import 'package:frontend/features/profile/presentation/widgets/action_row.dart';
import 'package:frontend/features/profile/presentation/widgets/add_child_sheet.dart';
import 'package:frontend/features/profile/presentation/widgets/child_row.dart';
import 'package:frontend/features/profile/presentation/widgets/info_row.dart';
import 'package:frontend/features/profile/presentation/widgets/my_services_card.dart';
import 'package:frontend/features/profile/presentation/widgets/profile_avatar.dart';
import 'package:frontend/features/profile/presentation/widgets/section_card.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  void _showAddChildSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusXl)),
      ),
      builder: (_) => AddChildSheet(
        onSave: (data) => ref.read(profileProvider.notifier).addChild(data),
      ),
    );
  }

  void _showEditChildSheet(BuildContext context, WidgetRef ref, ChildProfileModel child) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusXl)),
      ),
      builder: (_) => AddChildSheet(
        initial: child,
        onSave: (data) => ref.read(profileProvider.notifier).updateChild(child.id, data),
      ),
    );
  }

  void _confirmDeleteChild(BuildContext context, WidgetRef ref, ChildProfileModel child) {
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
        message: 'This permanently deletes your account and all data. This cannot be undone.',
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
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(
          child: Text('Failed to load profile', style: AppTextStyles.bodyMedium),
        ),
        data: (profile) => ListView(
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacing20),
          children: [
            const SizedBox(height: AppDimensions.spacing24),
            ProfileAvatar(profile: profile),
            const SizedBox(height: AppDimensions.spacing32),
            SectionCard(
              title: 'Personal Info',
              onEdit: () => context.push(AppRoutes.editPersonalInfo),
              children: [
                InfoRow('Age', profile.cwsnProfile?.age.toString()),
                InfoRow('Gender', profile.cwsnProfile?.gender),
                InfoRow('Area', profile.cwsnProfile?.streetAddress),
              ],
            ),
            const SizedBox(height: AppDimensions.spacing12),
            SectionCard(
              title: 'Children',
              trailing: GestureDetector(
                onTap: () => _showAddChildSheet(context, ref),
                child: Text(
                  'Add',
                  style: AppTextStyles.labelMedium.copyWith(color: AppColors.primary),
                ),
              ),
              children: profile.cwsnProfile?.children.isEmpty != false
                  ? [EmptyRow('No children added yet')]
                  : profile.cwsnProfile!.children
                        .map(
                          (child) => ChildRow(
                            child: child,
                            onEdit: () => _showEditChildSheet(context, ref, child),
                            onDelete: () => _confirmDeleteChild(context, ref, child),
                          ),
                        )
                        .toList(),
            ),
            const SizedBox(height: AppDimensions.spacing12),
            SectionCard(
              title: 'Caregiver Info',
              onEdit: () => context.push(AppRoutes.editCaregiverInfo),
              children: [
                InfoRow('About', profile.caregiverProfile?.aboutMe),
                InfoRow('Qualifications', profile.caregiverProfile?.qualifications),
                InfoRow('Languages', profile.caregiverProfile?.languages.join(', ')),
              ],
            ),
            const SizedBox(height: AppDimensions.spacing12),
            const MyServicesCard(),
            const SizedBox(height: AppDimensions.spacing32),
            ActionRow(
              icon: Icons.logout_rounded,
              label: 'Logout',
              onTap: () => _confirmLogout(context, ref),
            ),
            const SizedBox(height: AppDimensions.spacing8),
            ActionRow(
              icon: Icons.delete_outline_rounded,
              label: 'Delete Account',
              color: AppColors.error,
              onTap: () => _confirmDeleteAccount(context, ref),
            ),
            const SizedBox(height: AppDimensions.spacing40),
          ],
        ),
      ),
    );
  }
}
