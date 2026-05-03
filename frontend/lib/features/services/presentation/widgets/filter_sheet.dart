import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/theme/app_dimensions.dart';
import 'package:frontend/core/theme/app_text_styles.dart';
import 'package:frontend/features/services/presentation/providers/service_provider.dart';
import 'package:frontend/features/services/presentation/widgets/sheet_widgets.dart';

class FilterSheet extends ConsumerStatefulWidget {
  final ServiceFilter initialFilter;

  const FilterSheet({super.key, required this.initialFilter});

  @override
  ConsumerState<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<FilterSheet> {
  late String? _serviceType;
  late String? _paymentType;
  late String? _targetGender;
  late String? _caregiverGender;
  late int? _distanceKm;

  @override
  void initState() {
    super.initState();
    _serviceType = widget.initialFilter.serviceType;
    _paymentType = widget.initialFilter.paymentType;
    _targetGender = widget.initialFilter.targetGender;
    _caregiverGender = widget.initialFilter.caregiverGender;
    _distanceKm = widget.initialFilter.distanceKm;
  }

  void _apply() {
    final notifier = ref.read(serviceFilterProvider.notifier);
    notifier.setServiceType(_serviceType);
    notifier.setPaymentType(_paymentType);
    notifier.setTargetGender(_targetGender);
    notifier.setCaregiverGender(_caregiverGender);
    notifier.setChildAge(null);
    notifier.setDistanceKm(_serviceType == 'Offline' ? _distanceKm : null);
    Navigator.of(context).pop();
  }

  void _clear() {
    setState(() {
      _serviceType = null;
      _paymentType = null;
      _targetGender = null;
      _caregiverGender = null;
      _distanceKm = null;
    });
    ref.read(serviceFilterProvider.notifier).clearAll();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SheetHandle(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Filter Services', style: AppTextStyles.titleMedium),
              GestureDetector(
                onTap: _clear,
                child: Text(
                  'Clear all',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacing20),
          FilterSection(
            label: 'Service Type',
            options: const ['Online', 'Offline', 'Hybrid'],
            selected: _serviceType,
            onSelected: (v) => setState(() {
              _serviceType = v;
              if (v == 'Offline') {
                _distanceKm ??= 10;
              } else {
                _distanceKm = null;
              }
            }),
          ),
          if (_serviceType == 'Offline') ...[
            const SizedBox(height: AppDimensions.spacing16),
            _DistanceSlider(
              distanceKm: _distanceKm!,
              onChanged: (v) => setState(() => _distanceKm = v),
            ),
          ],
          const SizedBox(height: AppDimensions.spacing16),
          FilterSection(
            label: 'Payment',
            options: const ['Paid', 'Unpaid'],
            selected: _paymentType,
            onSelected: (v) => setState(() => _paymentType = v),
          ),
          const SizedBox(height: AppDimensions.spacing16),
          FilterSection(
            label: 'Child Gender',
            options: const ['Any', 'Male', 'Female'],
            selected: _targetGender,
            onSelected: (v) => setState(() => _targetGender = v),
          ),
          const SizedBox(height: AppDimensions.spacing16),
          FilterSection(
            label: 'Caregiver Gender',
            options: const ['Male', 'Female'],
            selected: _caregiverGender,
            onSelected: (v) => setState(() => _caregiverGender = v),
          ),
          const SizedBox(height: AppDimensions.spacing24),
          SheetSaveButton(label: 'Apply Filters', onTap: _apply),
        ],
      ),
    );
  }
}

class FilterSection extends StatelessWidget {
  final String label;
  final List<String> options;
  final String? selected;
  final ValueChanged<String?> onSelected;

  const FilterSection({
    super.key,
    required this.label,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textSecondary,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: AppDimensions.spacing8),
        Wrap(
          spacing: AppDimensions.spacing8,
          runSpacing: AppDimensions.spacing8,
          children: options.map((opt) {
            final isSelected = selected == opt;
            return GestureDetector(
              onTap: () => onSelected(isSelected ? null : opt),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spacing16,
                  vertical: AppDimensions.spacing8,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border,
                  ),
                ),
                child: Text(
                  opt,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _DistanceSlider extends StatelessWidget {
  final int distanceKm;
  final ValueChanged<int> onChanged;

  const _DistanceSlider({required this.distanceKm, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'DISTANCE',
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textSecondary,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: AppDimensions.spacing8),
        Row(
          children: [
            const Icon(Icons.location_on, size: 16, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(
              'Within $distanceKm km of you',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: AppColors.primary.withValues(alpha: 0.15),
            thumbColor: AppColors.primary,
            overlayColor: AppColors.primary.withValues(alpha: 0.12),
          ),
          child: Slider(
            value: distanceKm.toDouble(),
            min: 5,
            max: 50,
            divisions: 9,
            onChanged: (v) => onChanged(v.round()),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('5 km', style: AppTextStyles.labelSmall.copyWith(color: AppColors.textHint)),
            Text('50 km', style: AppTextStyles.labelSmall.copyWith(color: AppColors.textHint)),
          ],
        ),
      ],
    );
  }
}
