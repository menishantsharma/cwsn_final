import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/app/app_router.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/theme/app_dimensions.dart';
import 'package:frontend/core/theme/app_text_styles.dart';
import 'package:frontend/features/categories/domain/models/subcategory_model.dart';
import 'package:frontend/features/services/domain/models/service_model.dart';
import 'package:frontend/features/services/presentation/providers/service_provider.dart';
import 'package:go_router/go_router.dart';

class ServicesPage extends ConsumerWidget {
  final SubcategoryModel subcategory;

  const ServicesPage({super.key, required this.subcategory});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final args = (subcategory.categoryId, subcategory.id);
    final servicesAsync = ref.watch(serviceProvider(args));
    final myServiceAsync = ref.watch(myServiceProvider(args));
    final filter = ref.watch(serviceFilterProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.tune_rounded),
                tooltip: 'Filter',
                onPressed: () => _showFilterSheet(context, ref, filter),
              ),
              if (filter.isActive)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: servicesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => const Center(child: Text('Something went wrong')),
          data: (services) => myServiceAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => const Center(child: Text('Something went wrong')),
            data: (myService) => ListView.separated(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: AppDimensions.spacing32,
              ),
              itemCount: services.length + 2,
              separatorBuilder: (_, i) => SizedBox(
                height: i == 0
                    ? AppDimensions.spacing24
                    : AppDimensions.spacing12,
              ),
              itemBuilder: (context, index) {
                if (index == 0) return _Header(subcategory: subcategory);
                if (index == 1) {
                  return myService != null
                      ? _MyServiceCard(service: myService)
                      : _AddServiceCard(subcategory: subcategory);
                }
                return _ServiceCard(service: services[index - 2]);
              },
            ),
          ),
        ),
      ),
    );
  }

  void _showFilterSheet(BuildContext context, WidgetRef ref, ServiceFilter filter) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _FilterSheet(initialFilter: filter),
    );
  }
}

class _FilterSheet extends ConsumerStatefulWidget {
  final ServiceFilter initialFilter;
  const _FilterSheet({required this.initialFilter});

  @override
  ConsumerState<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<_FilterSheet> {
  late String? _serviceType;
  late String? _paymentType;
  late String? _targetGender;
  late String? _caregiverGender;
  late TextEditingController _ageController;

  @override
  void initState() {
    super.initState();
    _serviceType = widget.initialFilter.serviceType;
    _paymentType = widget.initialFilter.paymentType;
    _targetGender = widget.initialFilter.targetGender;
    _caregiverGender = widget.initialFilter.caregiverGender;
    _ageController = TextEditingController(
      text: widget.initialFilter.childAge?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _ageController.dispose();
    super.dispose();
  }

  void _apply() {
    final notifier = ref.read(serviceFilterProvider.notifier);
    notifier.setServiceType(_serviceType);
    notifier.setPaymentType(_paymentType);
    notifier.setTargetGender(_targetGender);
    notifier.setCaregiverGender(_caregiverGender);
    final age = int.tryParse(_ageController.text.trim());
    notifier.setChildAge(age);
    Navigator.of(context).pop();
  }

  void _clear() {
    setState(() {
      _serviceType = null;
      _paymentType = null;
      _targetGender = null;
      _caregiverGender = null;
      _ageController.clear();
    });
    ref.read(serviceFilterProvider.notifier).clearAll();
    Navigator.of(context).pop();
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Filter Services', style: AppTextStyles.titleMedium),
              TextButton(onPressed: _clear, child: const Text('Clear all')),
            ],
          ),
          const SizedBox(height: 20),
          _FilterSection(
            label: 'Service Type',
            options: const ['Online', 'Offline', 'Hybrid'],
            selected: _serviceType,
            onSelected: (v) => setState(() => _serviceType = v),
          ),
          const SizedBox(height: 16),
          _FilterSection(
            label: 'Payment',
            options: const ['Paid', 'Unpaid'],
            selected: _paymentType,
            onSelected: (v) => setState(() => _paymentType = v),
          ),
          const SizedBox(height: 16),
          _FilterSection(
            label: 'Child Gender',
            options: const ['Any', 'Male', 'Female'],
            selected: _targetGender,
            onSelected: (v) => setState(() => _targetGender = v),
          ),
          const SizedBox(height: 16),
          _FilterSection(
            label: 'Caregiver Gender',
            options: const ['Male', 'Female'],
            selected: _caregiverGender,
            onSelected: (v) => setState(() => _caregiverGender = v),
          ),
          const SizedBox(height: 16),
          Text('Child Age', style: AppTextStyles.labelMedium),
          const SizedBox(height: 8),
          SizedBox(
            width: 120,
            child: TextField(
              controller: _ageController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'e.g. 8',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _apply,
              child: const Text('Apply Filters'),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterSection extends StatelessWidget {
  final String label;
  final List<String> options;
  final String? selected;
  final ValueChanged<String?> onSelected;

  const _FilterSection({
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
        Text(label, style: AppTextStyles.labelMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: options.map((opt) {
            final isSelected = selected == opt;
            return ChoiceChip(
              label: Text(opt),
              selected: isSelected,
              onSelected: (_) => onSelected(isSelected ? null : opt),
              selectedColor: AppColors.primary,
              labelStyle: AppTextStyles.labelSmall.copyWith(
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  final SubcategoryModel subcategory;

  const _Header({required this.subcategory});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(subcategory.name, style: AppTextStyles.displaySmall),
        SizedBox(height: AppDimensions.spacing8),
        Text('Available services', style: AppTextStyles.bodyMedium),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;

  const _Chip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacing8,
        vertical: AppDimensions.spacing4,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
      ),
      child: Text(label, style: AppTextStyles.labelSmall),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final ServiceModel service;

  const _ServiceCard({required this.service});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(AppRoutes.serviceDetail, extra: service),
      child: Container(
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
        padding: const EdgeInsets.all(AppDimensions.spacing16),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              ),
              child: const Icon(
                Icons.design_services_outlined,
                color: AppColors.primary,
                size: 26,
              ),
            ),
            const SizedBox(width: AppDimensions.spacing16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.title,
                    style: AppTextStyles.titleSmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (service.description != null) ...[
                    const SizedBox(height: AppDimensions.spacing4),
                    Text(
                      service.description!,
                      style: AppTextStyles.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: AppDimensions.spacing8),
                  Row(
                    children: [
                      _Chip(label: service.serviceType),
                      const SizedBox(width: AppDimensions.spacing8),
                      _Chip(label: service.paymentType),
                      const Spacer(),
                      Row(
                        children: [
                          const Icon(
                            Icons.thumb_up_outlined,
                            size: 13,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${service.upvoteCount}',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppDimensions.spacing8),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: AppColors.textHint,
            ),
          ],
        ),
      ),
    );
  }
}

class _AddServiceCard extends StatelessWidget {
  final SubcategoryModel subcategory;
  const _AddServiceCard({required this.subcategory});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(AppRoutes.createService, extra: subcategory),
      child: DottedBorder(
        options: RoundedRectDottedBorderOptions(
          color: AppColors.primary,
          strokeWidth: 1.8,
          dashPattern: const [8, 4],
          radius: Radius.circular(AppDimensions.radiusXl),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
          ),
          padding: const EdgeInsets.all(AppDimensions.spacing16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 26),
              ),
              const SizedBox(width: AppDimensions.spacing16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Add a Service', style: AppTextStyles.titleSmall),
                    const SizedBox(height: AppDimensions.spacing4),
                    Text(
                      'Offer your expertise to others',
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppDimensions.spacing8),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MyServiceCard extends StatelessWidget {
  final ServiceModel service;
  const _MyServiceCard({required this.service});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () =>
          context.push(AppRoutes.editableServiceDetail, extra: service),
      child: DottedBorder(
        options: RoundedRectDottedBorderOptions(
          color: AppColors.primary,
          strokeWidth: 1.8,
          dashPattern: const [8, 4],
          radius: const Radius.circular(AppDimensions.radiusXl),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
          ),
          padding: const EdgeInsets.all(AppDimensions.spacing16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                ),
                child: const Icon(
                  Icons.design_services_outlined,
                  color: AppColors.primary,
                  size: 26,
                ),
              ),
              const SizedBox(width: AppDimensions.spacing16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Service',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacing2),
                    Text(
                      service.title,
                      style: AppTextStyles.titleSmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (service.description != null) ...[
                      const SizedBox(height: AppDimensions.spacing4),
                      Text(
                        service.description!,
                        style: AppTextStyles.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: AppDimensions.spacing8),
                    Row(
                      children: [
                        _Chip(label: service.serviceType),
                        const SizedBox(width: AppDimensions.spacing8),
                        _Chip(label: service.paymentType),
                        const Spacer(),
                        Row(
                          children: [
                            const Icon(
                              Icons.thumb_up_outlined,
                              size: 13,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '${service.upvoteCount}',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppDimensions.spacing8),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
