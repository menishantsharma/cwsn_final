import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/theme/app_dimensions.dart';
import 'package:frontend/core/theme/app_text_styles.dart';
import 'package:frontend/core/widgets/confirm_dialog.dart';
import 'package:frontend/features/services/domain/models/service_model.dart';
import 'package:frontend/features/services/presentation/providers/service_provider.dart';
import 'package:frontend/features/services/presentation/widgets/editable_field_row.dart';
import 'package:frontend/features/services/presentation/widgets/provider_section.dart';
import 'package:frontend/features/services/presentation/widgets/section_label.dart';
import 'package:frontend/features/services/presentation/widgets/service_hero.dart';
import 'package:frontend/features/services/presentation/widgets/sheet_widgets.dart';

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

  void _confirmDelete(BuildContext context) {
    final navigator = Navigator.of(context);
    showDialog(
      context: context,
      builder: (_) => ConfirmDialog(
        title: 'Delete service?',
        message: 'This will archive the service and remove it from all listings.',
        confirmLabel: 'Delete',
        isDanger: true,
        onConfirm: () async {
          await ref.read(editableServiceProvider.notifier).deleteService();
          navigator.pop();
        },
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

  void _showTextSheet(BuildContext context, {required String label, required void Function(String) onSave, String? value, int maxLines = 1}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusXl)),
      ),
      builder: (_) => TextSheet(label: label, value: value, maxLines: maxLines, onSave: onSave),
    );
  }

  void _showChipSheet(BuildContext context, {required String label, required List<String> options, required String selected, required void Function(String) onSave}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusXl)),
      ),
      builder: (_) => ChipSheet(label: label, options: options, selected: selected, onSave: onSave),
    );
  }

  void _showAgeSheet(BuildContext context, {required void Function(int?, int?) onSave, int? minAge, int? maxAge}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusXl)),
      ),
      builder: (_) => AgeSheet(minAge: minAge, maxAge: maxAge, onSave: onSave),
    );
  }

  @override
  Widget build(BuildContext context) {
    final serviceAsync = ref.watch(editableServiceProvider);
    final service = serviceAsync.value ?? widget.service;
    final isSaving = serviceAsync.isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppColors.background,
            elevation: 0,
            scrolledUnderElevation: 0,
            pinned: true,
            automaticallyImplyLeading: false,
            leading: IconButton(
              icon: const Icon(Icons.chevron_left, size: 28),
              color: AppColors.textPrimary,
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              if (isSaving)
                const Padding(
                  padding: EdgeInsets.only(right: 16),
                  child: Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                    ),
                  ),
                )
              else
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppColors.error),
                  onPressed: () => _confirmDelete(context),
                ),
            ],
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ServiceHero(image: service.image),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      EditableFieldRow(
                        value: service.title,
                        hint: 'Add title',
                        style: AppTextStyles.displaySmall,
                        onEdit: () => _showTextSheet(context, label: 'Title', value: service.title, onSave: (val) => _save(service.copyWith(title: val))),
                      ),
                      const SizedBox(height: AppDimensions.spacing12),
                      Row(
                        children: [
                          EditableChip(
                            label: service.serviceType,
                            icon: Icons.location_on_outlined,
                            onEdit: () => _showChipSheet(context, label: 'Service Type', options: const ['Online', 'Offline', 'Hybrid'], selected: service.serviceType, onSave: (val) => _save(service.copyWith(serviceType: val))),
                          ),
                          const SizedBox(width: AppDimensions.spacing8),
                          EditableChip(
                            label: service.paymentType,
                            icon: Icons.payments_outlined,
                            onEdit: () => _showChipSheet(context, label: 'Payment Type', options: const ['Paid', 'Unpaid'], selected: service.paymentType, onSave: (val) => _save(service.copyWith(paymentType: val))),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.spacing20),
                      SectionLabel('About this service'),
                      const SizedBox(height: AppDimensions.spacing8),
                      EditableFieldRow(
                        value: service.description,
                        hint: 'Add a description',
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary, height: 1.5),
                        onEdit: () => _showTextSheet(context, label: 'Description', value: service.description, maxLines: 5, onSave: (val) => _save(service.copyWith(description: val))),
                      ),
                      const SizedBox(height: AppDimensions.spacing20),
                      SectionLabel('Target audience'),
                      const SizedBox(height: AppDimensions.spacing12),
                      EditableFieldRow(
                        value: service.targetGender == 'Any' ? null : service.targetGender,
                        hint: 'Set target gender',
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                        prefix: const Icon(Icons.person_outline, size: 16, color: AppColors.primary),
                        onEdit: () => _showChipSheet(context, label: 'Target Gender', options: const ['Male', 'Female', 'Any'], selected: service.targetGender, onSave: (val) => _save(service.copyWith(targetGender: val))),
                      ),
                      const SizedBox(height: AppDimensions.spacing8),
                      EditableFieldRow(
                        value: _ageLabel(service.targetAgeMin, service.targetAgeMax),
                        hint: 'Set age range',
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                        prefix: const Icon(Icons.cake_outlined, size: 16, color: AppColors.primary),
                        onEdit: () => _showAgeSheet(context, minAge: service.targetAgeMin, maxAge: service.targetAgeMax, onSave: (min, max) => _save(service.copyWith(targetAgeMin: min, targetAgeMax: max))),
                      ),
                      if (service.caregiverProfile != null) ...[
                        const SizedBox(height: AppDimensions.spacing32),
                        Row(
                          children: [
                            const Icon(Icons.info_outline, size: 13, color: AppColors.textHint),
                            const SizedBox(width: AppDimensions.spacing4),
                            Expanded(
                              child: Text(
                                'Your profile is shared across all services.',
                                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textHint),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppDimensions.spacing16),
                        SectionLabel('About the provider'),
                        const SizedBox(height: AppDimensions.spacing12),
                        const ProviderSection(),
                      ],
                      const SizedBox(height: AppDimensions.spacing32),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
