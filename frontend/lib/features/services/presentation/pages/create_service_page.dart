import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/theme/app_dimensions.dart';
import 'package:frontend/core/theme/app_text_styles.dart';
import 'package:frontend/features/categories/domain/models/subcategory_model.dart';
import 'package:frontend/features/services/presentation/providers/service_provider.dart';
import 'package:frontend/features/services/presentation/widgets/editable_field_row.dart';
import 'package:frontend/features/services/presentation/widgets/provider_section.dart';
import 'package:frontend/features/services/presentation/widgets/section_label.dart';
import 'package:frontend/features/services/presentation/widgets/service_hero.dart';
import 'package:frontend/features/services/presentation/widgets/sheet_widgets.dart';

class CreateServicePage extends ConsumerStatefulWidget {
  final SubcategoryModel subcategory;

  const CreateServicePage({super.key, required this.subcategory});

  @override
  ConsumerState<CreateServicePage> createState() => _CreateServicePageState();
}

class _CreateServicePageState extends ConsumerState<CreateServicePage> {
  String _title = '';
  String _description = '';
  String _serviceType = 'Online';
  String _paymentType = 'Paid';
  String _targetGender = 'Any';
  int? _targetAgeMin;
  int? _targetAgeMax;
  bool _isLoading = false;

  bool get _canCreate =>
      _title.trim().isNotEmpty && _description.trim().isNotEmpty;

  Future<void> _create() async {
    final navigator = Navigator.of(context);
    setState(() => _isLoading = true);
    try {
      await ref.read(serviceRepositoryProvider).createService(
        fields: {
          'title': _title.trim(),
          'description': _description.trim(),
          'service_type': _serviceType,
          'payment_type': _paymentType,
          'target_gender': _targetGender,
          'target_age_min': _targetAgeMin,
          'target_age_max': _targetAgeMax,
          'category': widget.subcategory.categoryId,
          'sub_category': widget.subcategory.id,
        }..removeWhere((_, v) => v == null),
      );
      ref.invalidate(myServiceProvider((widget.subcategory.categoryId, widget.subcategory.id)));
      ref.invalidate(serviceProvider((widget.subcategory.categoryId, widget.subcategory.id)));
      ref.invalidate(allMyServicesProvider);
      navigator.pop();
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  String? _ageLabel(int? min, int? max) {
    if (min == null && max == null) return null;
    if (min != null && max != null) return '$min – $max years';
    if (min != null) return '$min+ years';
    return 'Up to $max years';
  }

  void _showTextSheet(BuildContext context, {required String label, required String value, required void Function(String) onSave, int maxLines = 1}) {
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
              if (_isLoading)
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
                TextButton(
                  onPressed: _canCreate ? _create : null,
                  child: Text(
                    'Create',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: _canCreate ? AppColors.primary : AppColors.textHint,
                    ),
                  ),
                ),
            ],
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ServiceHero(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      EditableFieldRow(
                        value: _title.isEmpty ? null : _title,
                        hint: 'Add title *',
                        style: AppTextStyles.displaySmall,
                        onEdit: () => _showTextSheet(context, label: 'Title', value: _title, onSave: (v) => setState(() => _title = v)),
                      ),
                      const SizedBox(height: AppDimensions.spacing12),
                      Row(
                        children: [
                          EditableChip(
                            label: _serviceType,
                            icon: Icons.location_on_outlined,
                            onEdit: () => _showChipSheet(context, label: 'Service Type', options: const ['Online', 'Offline', 'Hybrid'], selected: _serviceType, onSave: (v) => setState(() => _serviceType = v)),
                          ),
                          const SizedBox(width: AppDimensions.spacing8),
                          EditableChip(
                            label: _paymentType,
                            icon: Icons.payments_outlined,
                            onEdit: () => _showChipSheet(context, label: 'Payment Type', options: const ['Paid', 'Unpaid'], selected: _paymentType, onSave: (v) => setState(() => _paymentType = v)),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppDimensions.spacing20),
                      SectionLabel('About this service'),
                      const SizedBox(height: AppDimensions.spacing8),
                      EditableFieldRow(
                        value: _description.isEmpty ? null : _description,
                        hint: 'Add a description *',
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary, height: 1.5),
                        onEdit: () => _showTextSheet(context, label: 'Description', value: _description, maxLines: 5, onSave: (v) => setState(() => _description = v)),
                      ),
                      const SizedBox(height: AppDimensions.spacing20),
                      SectionLabel('Target audience'),
                      const SizedBox(height: AppDimensions.spacing12),
                      EditableFieldRow(
                        value: _targetGender == 'Any' ? null : _targetGender,
                        hint: 'Set target gender',
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                        prefix: const Icon(Icons.person_outline, size: 16, color: AppColors.primary),
                        onEdit: () => _showChipSheet(context, label: 'Target Gender', options: const ['Male', 'Female', 'Any'], selected: _targetGender, onSave: (v) => setState(() => _targetGender = v)),
                      ),
                      const SizedBox(height: AppDimensions.spacing8),
                      EditableFieldRow(
                        value: _ageLabel(_targetAgeMin, _targetAgeMax),
                        hint: 'Set age range',
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                        prefix: const Icon(Icons.cake_outlined, size: 16, color: AppColors.primary),
                        onEdit: () => _showAgeSheet(context, minAge: _targetAgeMin, maxAge: _targetAgeMax, onSave: (min, max) => setState(() { _targetAgeMin = min; _targetAgeMax = max; })),
                      ),
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
