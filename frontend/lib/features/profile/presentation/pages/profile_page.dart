import 'package:flutter/material.dart';
import 'package:frontend/core/widgets/app_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/app/app_router.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/theme/app_dimensions.dart';
import 'package:frontend/core/theme/app_text_styles.dart';
import 'package:frontend/core/widgets/confirm_dialog.dart';
import 'package:frontend/features/auth/presentation/controllers/auth_controller.dart';
import 'package:frontend/features/profile/presentation/controllers/profile_controller.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

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

              // ── Personal section ─────────────────────────
              _SectionLabel('Personal'),
              const SizedBox(height: AppDimensions.spacing8),
              _MenuGroup(
                children: [
                  _MenuRow(
                    icon: Icons.person_outline_rounded,
                    label: 'Personal Info',
                    onTap: () => context.push(AppRoutes.editPersonalInfo),
                  ),
                  _MenuRow(
                    icon: Icons.child_care_outlined,
                    label: 'My Children',
                    onTap: () => context.push(AppRoutes.myChildren),
                  ),
                ],
              ),

              const SizedBox(height: AppDimensions.spacing24),

              // ── Caregiver section ────────────────────────
              _SectionLabel('Caregiver'),
              const SizedBox(height: AppDimensions.spacing8),
              _MenuGroup(
                children: [
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

              // ── Support ──────────────────────────────────
              _SectionLabel('Support'),
              const SizedBox(height: AppDimensions.spacing8),
              _MenuGroup(
                children: [
                  _MenuRow(
                    icon: Icons.bug_report_outlined,
                    label: 'Report an Issue',
                    onTap: () => context.push(AppRoutes.reportIssue),
                  ),
                ],
              ),

              const SizedBox(height: AppDimensions.spacing24),

              // ── Legal ─────────────────────────────────────
              _SectionLabel('Legal'),
              const SizedBox(height: AppDimensions.spacing8),
              _MenuGroup(
                children: [
                  _MenuRow(
                    icon: Icons.description_outlined,
                    label: 'Terms of Service',
                    onTap: () => context.push(AppRoutes.terms),
                  ),
                  _MenuRow(
                    icon: Icons.privacy_tip_outlined,
                    label: 'Privacy Policy',
                    onTap: () => context.push(AppRoutes.privacy),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
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

  const _MenuRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor = AppColors.textSecondary,
    this.labelColor = AppColors.textPrimary,
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
