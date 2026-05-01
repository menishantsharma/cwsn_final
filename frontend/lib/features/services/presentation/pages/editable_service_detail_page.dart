import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/app/app_router.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/theme/app_dimensions.dart';
import 'package:frontend/core/theme/app_text_styles.dart';
import 'package:frontend/features/profile/domain/models/profile_model.dart' as profile_model;
import 'package:frontend/features/profile/presentation/providers/profile_provider.dart';
import 'package:frontend/features/services/domain/models/service_model.dart';
import 'package:frontend/features/services/presentation/providers/service_provider.dart';
import 'package:go_router/go_router.dart';

class EditableServiceDetailPage extends ConsumerStatefulWidget {
  final ServiceModel service;

  const EditableServiceDetailPage({super.key, required this.service});

  @override
  ConsumerState<EditableServiceDetailPage> createState() =>
      _EditableServiceDetailPageState();
}

class _EditableServiceDetailPageState
    extends ConsumerState<EditableServiceDetailPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(editableServiceProvider.notifier).init(widget.service),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final navigator = Navigator.of(context); // capture before await

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete service?'),
        content: const Text(
          'This will archive the service and remove it from all listings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await ref.read(editableServiceProvider.notifier).deleteService();
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final serviceAsync = ref.watch(editableServiceProvider);
    final service = serviceAsync.value ?? widget.service;
    final isSaving = serviceAsync.isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          if (isSaving)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _confirmDelete(context),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: AppDimensions.spacing8,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ServiceHero(image: service.image),
            const SizedBox(height: AppDimensions.spacing20),

            // Title
            _EditableRow(
              value: service.title,
              hint: 'Add title',
              style: AppTextStyles.displaySmall,
              onEdit: () => _showTextSheet(
                context,
                label: 'Title',
                value: service.title,
                onSave: (val) => _save(service.copyWith(title: val)),
              ),
            ),

            const SizedBox(height: AppDimensions.spacing12),

            // Service type + payment type chips
            Row(
              children: [
                _EditableChip(
                  label: service.serviceType,
                  icon: Icons.location_on_outlined,
                  onEdit: () => _showChipSheet(
                    context,
                    label: 'Service Type',
                    options: const ['Online', 'Offline', 'Hybrid'],
                    selected: service.serviceType,
                    onSave: (val) => _save(service.copyWith(serviceType: val)),
                  ),
                ),
                const SizedBox(width: AppDimensions.spacing8),
                _EditableChip(
                  label: service.paymentType,
                  icon: Icons.payments_outlined,
                  onEdit: () => _showChipSheet(
                    context,
                    label: 'Payment Type',
                    options: const ['Paid', 'Unpaid'],
                    selected: service.paymentType,
                    onSave: (val) => _save(service.copyWith(paymentType: val)),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppDimensions.spacing20),

            // Description
            _SectionLabel(label: 'About this service'),
            const SizedBox(height: AppDimensions.spacing8),
            _EditableRow(
              value: service.description,
              hint: 'Add a description',
              style: AppTextStyles.bodyMedium,
              onEdit: () => _showTextSheet(
                context,
                label: 'Description',
                value: service.description,
                maxLines: 5,
                onSave: (val) => _save(service.copyWith(description: val)),
              ),
            ),

            const SizedBox(height: AppDimensions.spacing20),

            // Target audience
            _SectionLabel(label: 'Target audience'),
            const SizedBox(height: AppDimensions.spacing12),

            _EditableRow(
              value: service.targetGender == 'Any'
                  ? null
                  : service.targetGender,
              hint: 'Set target gender',
              style: AppTextStyles.bodyMedium,
              prefix: const Icon(
                Icons.person_outline,
                size: 16,
                color: AppColors.primary,
              ),
              onEdit: () => _showChipSheet(
                context,
                label: 'Target Gender',
                options: const ['Male', 'Female', 'Any'],
                selected: service.targetGender,
                onSave: (val) => _save(service.copyWith(targetGender: val)),
              ),
            ),

            const SizedBox(height: AppDimensions.spacing8),

            _EditableRow(
              value: _ageLabel(service.targetAgeMin, service.targetAgeMax),
              hint: 'Set age range',
              style: AppTextStyles.bodyMedium,
              prefix: const Icon(
                Icons.cake_outlined,
                size: 16,
                color: AppColors.primary,
              ),
              onEdit: () => _showAgeSheet(
                context,
                minAge: service.targetAgeMin,
                maxAge: service.targetAgeMax,
                onSave: (min, max) => _save(
                  service.copyWith(targetAgeMin: min, targetAgeMax: max),
                ),
              ),
            ),

            if (service.caregiverProfile != null) ...[
              const SizedBox(height: AppDimensions.spacing24),
              const _SectionDivider(),
              const SizedBox(height: AppDimensions.spacing8),
              Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 13,
                    color: AppColors.textHint,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Your profile is shared across all services. Changes here will reflect everywhere.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textHint,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.spacing16),
              const _ProviderSection(),
            ],

            const SizedBox(height: AppDimensions.spacing32),
          ],
        ),
      ),
    );
  }

  String? _ageLabel(int? min, int? max) {
    if (min == null && max == null) return null;
    if (min != null && max != null) return '$min – $max years';
    if (min != null) return '$min+ years';
    return 'Up to $max years';
  }

  void _save(ServiceModel updated) {
    ref.read(editableServiceProvider.notifier).updateField({
      'title': updated.title,
      'description': updated.description,
      'service_type': updated.serviceType,
      'payment_type': updated.paymentType,
      'target_age_min': updated.targetAgeMin,
      'target_age_max': updated.targetAgeMax,
      'target_gender': updated.targetGender,
      'category': updated.categoryId,
      'sub_category': updated.subCategoryId,
    });
  }

  // ── Bottom Sheets ─────────────────────────────────────────

  void _showTextSheet(
    BuildContext context, {
    required String label,
    required void Function(String) onSave,
    String? value,
    int maxLines = 1,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusXl),
        ),
      ),
      builder: (_) => _TextSheetContent(
        label: label,
        value: value,
        maxLines: maxLines,
        onSave: onSave,
      ),
    );
  }

  void _showChipSheet(
    BuildContext context, {
    required String label,
    required List<String> options,
    required String selected,
    required void Function(String) onSave,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusXl),
        ),
      ),
      builder: (_) => _ChipSheetContent(
        label: label,
        options: options,
        selected: selected,
        onSave: onSave,
      ),
    );
  }

  void _showAgeSheet(
    BuildContext context, {
    required void Function(int?, int?) onSave,
    int? minAge,
    int? maxAge,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusXl),
        ),
      ),
      builder: (_) =>
          _AgeSheetContent(minAge: minAge, maxAge: maxAge, onSave: onSave),
    );
  }
}

// ── Editable Row ──────────────────────────────────────────

class _EditableRow extends StatelessWidget {
  final String? value;
  final String? hint;
  final TextStyle style;
  final Widget? prefix;
  final VoidCallback onEdit;

  const _EditableRow({
    required this.style,
    required this.onEdit,
    this.value,
    this.hint,
    this.prefix,
  });

  @override
  Widget build(BuildContext context) {
    final isEmpty = value == null || value!.isEmpty;
    return GestureDetector(
      onTap: onEdit,
      behavior: HitTestBehavior.opaque,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (prefix != null) ...[
            prefix!,
            const SizedBox(width: AppDimensions.spacing6),
          ],
          Expanded(
            child: isEmpty
                ? Text(
                    hint ?? 'Tap to add',
                    style: style.copyWith(
                      color: AppColors.textHint,
                      fontStyle: FontStyle.italic,
                    ),
                  )
                : Text(value!, style: style),
          ),
          const SizedBox(width: AppDimensions.spacing8),
          const Icon(Icons.edit_outlined, size: 16, color: AppColors.textHint),
        ],
      ),
    );
  }
}

// ── Editable Chip ─────────────────────────────────────────

class _EditableChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onEdit;

  const _EditableChip({
    required this.label,
    required this.icon,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onEdit,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacing12,
          vertical: AppDimensions.spacing6,
        ),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: AppColors.primaryDark),
            const SizedBox(width: AppDimensions.spacing4),
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(width: AppDimensions.spacing4),
            const Icon(
              Icons.edit_outlined,
              size: 11,
              color: AppColors.primaryDark,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Section Label ─────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(label, style: AppTextStyles.titleSmall);
  }
}

// ── Section Divider ───────────────────────────────────────

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.border)),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacing12,
          ),
          child: Text('Provided by', style: AppTextStyles.labelMedium),
        ),
        const Expanded(child: Divider(color: AppColors.border)),
      ],
    );
  }
}

// ── Service Hero ──────────────────────────────────────────

class _ServiceHero extends StatelessWidget {
  final String? image;
  const _ServiceHero({required this.image});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        image: image != null
            ? DecorationImage(image: NetworkImage(image!), fit: BoxFit.cover)
            : null,
      ),
      child: image == null
          ? Center(
              child: Icon(
                Icons.design_services_outlined,
                size: 64,
                color: AppColors.primary.withValues(alpha: 0.5),
              ),
            )
          : null,
    );
  }
}

// ── Provider Section (editable) ───────────────────────────

class _ProviderSection extends ConsumerWidget {
  const _ProviderSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);

    return profileAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (profile) {
        final cwsn = profile.cwsnProfile;
        final caregiver = profile.caregiverProfile;
        final name = cwsn?.name ?? '';
        final gender = cwsn?.gender;
        final hasContent = caregiver != null &&
            (caregiver.aboutMe.isNotEmpty ||
                caregiver.qualifications.isNotEmpty ||
                caregiver.languages.isNotEmpty);

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppDimensions.spacing20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _ProviderHeader(name: name, gender: gender)),
                  GestureDetector(
                    onTap: () => context.push(AppRoutes.editPersonalInfo),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.edit_outlined, size: 14, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text('Edit', style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.spacing16),
              const Divider(color: AppColors.border),
              const SizedBox(height: AppDimensions.spacing16),
              if (hasContent) ...[
                _ProviderDetails(profile: caregiver),
                const SizedBox(height: AppDimensions.spacing16),
              ],
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () => context.push(AppRoutes.editCaregiverInfo),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.edit_outlined, size: 14, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text('Edit caregiver info', style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary)),
                    ],
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

class _ProviderHeader extends StatelessWidget {
  final String name;
  final String? gender;
  const _ProviderHeader({required this.name, required this.gender});

  String _initials(String n) {
    final parts = n.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    if (parts[0].isNotEmpty) return parts[0][0].toUpperCase();
    return '?';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              _initials(name),
              style: AppTextStyles.titleMedium.copyWith(color: AppColors.primary),
            ),
          ),
        ),
        const SizedBox(width: AppDimensions.spacing12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: AppTextStyles.titleSmall),
              if (gender != null && gender!.isNotEmpty) ...[
                const SizedBox(height: AppDimensions.spacing4),
                Text(gender!, style: AppTextStyles.bodySmall),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ProviderDetails extends StatelessWidget {
  final profile_model.CaregiverProfileModel profile;
  const _ProviderDetails({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (profile.aboutMe.isNotEmpty) ...[
          _DetailRow(label: 'About', value: profile.aboutMe),
          const SizedBox(height: AppDimensions.spacing12),
        ],
        if (profile.qualifications.isNotEmpty) ...[
          _DetailRow(label: 'Qualifications', value: profile.qualifications),
          const SizedBox(height: AppDimensions.spacing12),
        ],
        if (profile.languages.isNotEmpty)
          _LanguagesRow(languages: profile.languages),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.labelMedium),
        const SizedBox(height: AppDimensions.spacing4),
        Text(value, style: AppTextStyles.bodyMedium),
      ],
    );
  }
}

class _LanguagesRow extends StatelessWidget {
  final List<String> languages;
  const _LanguagesRow({required this.languages});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Languages', style: AppTextStyles.labelMedium),
        const SizedBox(height: AppDimensions.spacing8),
        Wrap(
          spacing: AppDimensions.spacing8,
          runSpacing: AppDimensions.spacing8,
          children: languages
              .map(
                (lang) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.spacing12,
                    vertical: AppDimensions.spacing4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(
                      AppDimensions.radiusFull,
                    ),
                  ),
                  child: Text(lang, style: AppTextStyles.labelMedium),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _AgeSheetContent extends StatefulWidget {
  final int? minAge;
  final int? maxAge;
  final void Function(int?, int?) onSave;

  const _AgeSheetContent({required this.onSave, this.minAge, this.maxAge});

  @override
  State<_AgeSheetContent> createState() => _AgeSheetContentState();
}

class _AgeSheetContentState extends State<_AgeSheetContent> {
  late final TextEditingController _minController;
  late final TextEditingController _maxController;

  @override
  void initState() {
    super.initState();
    _minController = TextEditingController(
      text: widget.minAge?.toString() ?? '',
    );
    _maxController = TextEditingController(
      text: widget.maxAge?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Target Age Range', style: AppTextStyles.titleSmall),
          const SizedBox(height: AppDimensions.spacing12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _minController,
                  keyboardType: TextInputType.number,
                  style: AppTextStyles.bodyLarge,
                  decoration: InputDecoration(
                    labelText: 'Min age',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusMd,
                      ),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusMd,
                      ),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppDimensions.spacing12),
              Expanded(
                child: TextField(
                  controller: _maxController,
                  keyboardType: TextInputType.number,
                  style: AppTextStyles.bodyLarge,
                  decoration: InputDecoration(
                    labelText: 'Max age',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusMd,
                      ),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusMd,
                      ),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacing16),
          SizedBox(
            width: double.infinity,
            height: AppDimensions.buttonHeight,
            child: ElevatedButton(
              onPressed: () {
                widget.onSave(
                  int.tryParse(_minController.text),
                  int.tryParse(_maxController.text),
                );
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                ),
              ),
              child: Text(
                'Save',
                style: AppTextStyles.labelLarge.copyWith(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Text Sheet ────────────────────────────────────────────

class _TextSheetContent extends StatefulWidget {
  final String label;
  final String? value;
  final int maxLines;
  final void Function(String) onSave;

  const _TextSheetContent({
    required this.label,
    required this.onSave,
    this.value,
    this.maxLines = 1,
  });

  @override
  State<_TextSheetContent> createState() => _TextSheetContentState();
}

class _TextSheetContentState extends State<_TextSheetContent> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.label, style: AppTextStyles.titleSmall),
          const SizedBox(height: AppDimensions.spacing12),
          TextField(
            controller: _controller,
            maxLines: widget.maxLines,
            autofocus: true,
            style: AppTextStyles.bodyLarge,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.spacing16),
          SizedBox(
            width: double.infinity,
            height: AppDimensions.buttonHeight,
            child: ElevatedButton(
              onPressed: () {
                widget.onSave(_controller.text.trim());
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                ),
              ),
              child: Text(
                'Save',
                style: AppTextStyles.labelLarge.copyWith(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Chip Sheet ────────────────────────────────────────────

class _ChipSheetContent extends StatefulWidget {
  final String label;
  final List<String> options;
  final String selected;
  final void Function(String) onSave;

  const _ChipSheetContent({
    required this.label,
    required this.options,
    required this.selected,
    required this.onSave,
  });

  @override
  State<_ChipSheetContent> createState() => _ChipSheetContentState();
}

class _ChipSheetContentState extends State<_ChipSheetContent> {
  late String _current;

  @override
  void initState() {
    super.initState();
    _current = widget.selected;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.label, style: AppTextStyles.titleSmall),
          const SizedBox(height: AppDimensions.spacing16),
          Wrap(
            spacing: AppDimensions.spacing8,
            runSpacing: AppDimensions.spacing8,
            children: widget.options.map((opt) {
              final isSelected = opt == _current;
              return GestureDetector(
                onTap: () => setState(() => _current = opt),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.spacing16,
                    vertical: AppDimensions.spacing8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(
                      AppDimensions.radiusFull,
                    ),
                  ),
                  child: Text(
                    opt,
                    style: AppTextStyles.labelMedium.copyWith(
                      color: isSelected
                          ? Colors.white
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppDimensions.spacing20),
          SizedBox(
            width: double.infinity,
            height: AppDimensions.buttonHeight,
            child: ElevatedButton(
              onPressed: () {
                widget.onSave(_current);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                ),
              ),
              child: Text(
                'Save',
                style: AppTextStyles.labelLarge.copyWith(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
