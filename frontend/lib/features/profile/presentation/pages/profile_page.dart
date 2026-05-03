import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/theme/app_dimensions.dart';
import 'package:frontend/core/theme/app_text_styles.dart';
import 'package:frontend/core/widgets/confirm_dialog.dart';
import 'package:frontend/features/profile/domain/models/profile_model.dart';
import 'package:frontend/features/services/presentation/providers/service_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/app/app_router.dart';
import 'package:frontend/features/auth/presentation/providers/auth_provider.dart';
import 'package:frontend/features/profile/presentation/providers/profile_provider.dart';

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
      builder: (_) => _AddChildSheet(
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusXl)),
      ),
      builder: (_) => _AddChildSheet(
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text('Profile', style: AppTextStyles.titleMedium),
      ),
      body: profileAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(
          child: Text(
            'Failed to load profile',
            style: AppTextStyles.bodyMedium,
          ),
        ),
        data: (profile) => ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacing20,
          ),
          children: [
            const SizedBox(height: AppDimensions.spacing24),

            // Avatar
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                    child: Text(
                      (profile.cwsnProfile?.name.isNotEmpty == true)
                          ? profile.cwsnProfile!.name[0].toUpperCase()
                          : '?',
                      style: AppTextStyles.displaySmall.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacing12),
                  Text(
                    profile.cwsnProfile?.name ?? '',
                    style: AppTextStyles.titleLarge,
                  ),
                  if (profile.cwsnProfile?.phoneNumber != null)
                    Text(
                      profile.cwsnProfile!.phoneNumber,
                      style: AppTextStyles.bodySmall,
                    ),
                ],
              ),
            ),

            const SizedBox(height: AppDimensions.spacing32),

            _SectionCard(
              title: 'Personal Info',
              onEdit: () => context.push(AppRoutes.editPersonalInfo),
              children: [
                _InfoRow('Age', profile.cwsnProfile?.age.toString()),
                _InfoRow('Gender', profile.cwsnProfile?.gender),
                _InfoRow('Area', profile.cwsnProfile?.streetAddress),
              ],
            ),

            const SizedBox(height: AppDimensions.spacing12),

            _SectionCard(
              title: 'Children',
              trailing: GestureDetector(
                onTap: () => _showAddChildSheet(context, ref),
                child: Text(
                  'Add',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
              children: profile.cwsnProfile?.children.isEmpty != false
                  ? [_EmptyRow('No children added yet')]
                  : profile.cwsnProfile!.children
                        .map(
                          (child) => _ChildRow(
                            child: child,
                            onEdit: () =>
                                _showEditChildSheet(context, ref, child),
                            onDelete: () =>
                                _confirmDeleteChild(context, ref, child),
                          ),
                        )
                        .toList(),
            ),

            const SizedBox(height: AppDimensions.spacing12),

            _SectionCard(
              title: 'Caregiver Info',
              onEdit: () => context.push(AppRoutes.editCaregiverInfo),
              children: [
                _InfoRow('About', profile.caregiverProfile?.aboutMe),
                _InfoRow(
                  'Qualifications',
                  profile.caregiverProfile?.qualifications,
                ),
                _InfoRow(
                  'Languages',
                  profile.caregiverProfile?.languages.join(', '),
                ),
              ],
            ),

            const SizedBox(height: AppDimensions.spacing12),

            _MyServicesCard(),

            const SizedBox(height: AppDimensions.spacing32),

            _ActionRow(
              icon: Icons.logout_rounded,
              label: 'Logout',
              onTap: () => _confirmLogout(context, ref),
            ),
            const SizedBox(height: AppDimensions.spacing8),
            _ActionRow(
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

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final VoidCallback? onEdit;
  final Widget? trailing;

  const _SectionCard({
    required this.title,
    required this.children,
    this.onEdit,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.spacing16,
              AppDimensions.spacing16,
              AppDimensions.spacing8,
              AppDimensions.spacing12,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.textSecondary,
                    letterSpacing: 0.8,
                  ),
                ),
                if (onEdit != null)
                  GestureDetector(
                    onTap: onEdit,
                    child: Text(
                      'Edit',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spacing16,
              vertical: AppDimensions.spacing8,
            ),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String? value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacing8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: AppTextStyles.bodySmall),
          ),
          Expanded(
            child: Text(
              (value?.isNotEmpty == true) ? value! : '—',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyRow extends StatelessWidget {
  final String message;
  const _EmptyRow(this.message);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacing8),
      child: Text(message, style: AppTextStyles.bodySmall),
    );
  }
}

class _ChildRow extends StatelessWidget {
  final ChildProfileModel child;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ChildRow({
    required this.child,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacing6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  child.name,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${child.age} yrs · ${child.gender}',
                  style: AppTextStyles.labelSmall,
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onEdit,
            child: Text(
              'Edit',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.spacing16),
          GestureDetector(
            onTap: onDelete,
            child: Text(
              'Remove',
              style: AppTextStyles.labelSmall.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _ActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = AppColors.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacing16,
          vertical: AppDimensions.spacing16,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: AppDimensions.spacing12),
            Text(label, style: AppTextStyles.bodySmall.copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}

class _MyServicesCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servicesAsync = ref.watch(allMyServicesProvider);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.spacing16,
              AppDimensions.spacing16,
              AppDimensions.spacing16,
              AppDimensions.spacing12,
            ),
            child: Text(
              'My Services',
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.textSecondary,
                letterSpacing: 0.8,
              ),
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          servicesAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(AppDimensions.spacing16),
              child: Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 2,
                ),
              ),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(AppDimensions.spacing16),
              child: Text(
                'Failed to load services',
                style: AppTextStyles.bodySmall,
              ),
            ),
            data: (services) => services.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(AppDimensions.spacing16),
                    child: Text(
                      'No services added yet',
                      style: AppTextStyles.bodySmall,
                    ),
                  )
                : Column(
                    children: services
                        .map(
                          (service) => InkWell(
                            onTap: () => context.push(
                              AppRoutes.editableServiceDetail,
                              extra: service,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppDimensions.spacing16,
                                vertical: AppDimensions.spacing12,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          service.title,
                                          style: AppTextStyles.bodySmall
                                              .copyWith(
                                                color: AppColors.textPrimary,
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${service.serviceType} · ${service.paymentType}',
                                          style: AppTextStyles.labelSmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 12,
                                    color: AppColors.textHint,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }
}

class _AddChildSheet extends StatefulWidget {
  final Future<void> Function(Map<String, dynamic>) onSave;
  final ChildProfileModel? initial;

  const _AddChildSheet({required this.onSave, this.initial});

  @override
  State<_AddChildSheet> createState() => _AddChildSheetState();
}

class _AddChildSheetState extends State<_AddChildSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _ageController;
  late String _gender;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initial?.name ?? '');
    _ageController = TextEditingController(
      text: widget.initial != null ? widget.initial!.age.toString() : '',
    );
    _gender = widget.initial?.gender ?? 'Male';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await widget.onSave({
        'name': _nameController.text.trim(),
        'age': int.parse(_ageController.text.trim()),
        'gender': _gender,
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initial != null;
    return Padding(
      padding: EdgeInsets.only(
        left: AppDimensions.spacing20,
        right: AppDimensions.spacing20,
        top: AppDimensions.spacing24,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppDimensions.spacing24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppDimensions.spacing20),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                ),
              ),
            ),

            Text(
              isEdit ? 'Edit Child' : 'Add Child',
              style: AppTextStyles.titleMedium,
            ),
            const SizedBox(height: AppDimensions.spacing24),

            _SheetField(
              label: 'Name',
              child: TextFormField(
                controller: _nameController,
                decoration: _sheetInputDecoration('Child\'s full name'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
            ),
            _SheetField(
              label: 'Age',
              child: TextFormField(
                controller: _ageController,
                decoration: _sheetInputDecoration('e.g. 7'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  if (int.tryParse(v.trim()) == null) return 'Must be a number';
                  return null;
                },
              ),
            ),
            _SheetField(
              label: 'Gender',
              child: DropdownButtonFormField<String>(
                initialValue: _gender,
                decoration: _sheetInputDecoration('Select'),
                items: ['Male', 'Female', 'Other']
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                onChanged: (v) => setState(() => _gender = v!),
              ),
            ),

            const SizedBox(height: AppDimensions.spacing8),

            SizedBox(
              height: AppDimensions.buttonHeight,
              child: Material(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                child: InkWell(
                  onTap: _loading ? null : _submit,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                  child: Center(
                    child: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            isEdit ? 'Update' : 'Save',
                            style: AppTextStyles.labelLarge.copyWith(color: Colors.white, fontSize: 16),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

InputDecoration _sheetInputDecoration(String hint) => InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint),
      filled: true,
      fillColor: AppColors.background,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacing16,
        vertical: AppDimensions.spacing12,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
    );

class _SheetField extends StatelessWidget {
  final String label;
  final Widget child;

  const _SheetField({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.labelMedium.copyWith(
            color: AppColors.textSecondary,
            letterSpacing: 0.5,
          )),
          const SizedBox(height: AppDimensions.spacing6),
          child,
        ],
      ),
    );
  }
}

