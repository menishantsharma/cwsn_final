import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/app/app_router.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/theme/app_dimensions.dart';
import 'package:frontend/core/theme/app_text_styles.dart';
import 'package:frontend/features/categories/domain/models/subcategory_model.dart';
import 'package:frontend/features/interactions/presentation/providers/upvote_provider.dart';
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
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.tune_rounded),
                color: AppColors.textPrimary,
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
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          error: (e, _) => const Center(child: Text('Something went wrong')),
          data: (services) => myServiceAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
            error: (e, _) => const Center(child: Text('Something went wrong')),
            data: (myService) => ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              itemCount: services.length + 2,
              separatorBuilder: (_, i) => SizedBox(
                height: i == 0
                    ? AppDimensions.spacing20
                    : AppDimensions.spacing8,
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

  void _showFilterSheet(
      BuildContext context, WidgetRef ref, ServiceFilter filter) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppDimensions.radiusXl)),
      ),
      builder: (_) => _FilterSheet(initialFilter: filter),
    );
  }
}

// ── Filter Sheet ──────────────────────────────────────────

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

  @override
  void initState() {
    super.initState();
    _serviceType = widget.initialFilter.serviceType;
    _paymentType = widget.initialFilter.paymentType;
    _targetGender = widget.initialFilter.targetGender;
    _caregiverGender = widget.initialFilter.caregiverGender;
  }

  void _apply() {
    final notifier = ref.read(serviceFilterProvider.notifier);
    notifier.setServiceType(_serviceType);
    notifier.setPaymentType(_paymentType);
    notifier.setTargetGender(_targetGender);
    notifier.setCaregiverGender(_caregiverGender);
    notifier.setChildAge(null);
    Navigator.of(context).pop();
  }

  void _clear() {
    setState(() {
      _serviceType = null;
      _paymentType = null;
      _targetGender = null;
      _caregiverGender = null;
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
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Filter Services', style: AppTextStyles.titleMedium),
              GestureDetector(
                onTap: _clear,
                child: Text(
                  'Clear all',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacing20),
          _FilterSection(
            label: 'Service Type',
            options: const ['Online', 'Offline', 'Hybrid'],
            selected: _serviceType,
            onSelected: (v) => setState(() => _serviceType = v),
          ),
          const SizedBox(height: AppDimensions.spacing16),
          _FilterSection(
            label: 'Payment',
            options: const ['Paid', 'Unpaid'],
            selected: _paymentType,
            onSelected: (v) => setState(() => _paymentType = v),
          ),
          const SizedBox(height: AppDimensions.spacing16),
          _FilterSection(
            label: 'Child Gender',
            options: const ['Any', 'Male', 'Female'],
            selected: _targetGender,
            onSelected: (v) => setState(() => _targetGender = v),
          ),
          const SizedBox(height: AppDimensions.spacing16),
          _FilterSection(
            label: 'Caregiver Gender',
            options: const ['Male', 'Female'],
            selected: _caregiverGender,
            onSelected: (v) => setState(() => _caregiverGender = v),
          ),
          const SizedBox(height: AppDimensions.spacing24),
          SizedBox(
            width: double.infinity,
            height: AppDimensions.buttonHeight,
            child: Material(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              child: InkWell(
                onTap: _apply,
                borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                child: Center(
                  child: Text(
                    'Apply Filters',
                    style: AppTextStyles.labelLarge
                        .copyWith(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
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
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusFull),
                  border: Border.all(
                    color:
                        isSelected ? AppColors.primary : AppColors.border,
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

// ── Header ────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final SubcategoryModel subcategory;

  const _Header({required this.subcategory});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(subcategory.name, style: AppTextStyles.displaySmall),
        const SizedBox(height: AppDimensions.spacing4),
        Text(
          'Available services',
          style: AppTextStyles.bodyMedium
              .copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppDimensions.spacing16),
      ],
    );
  }
}

// ── Chips ─────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  final String label;

  const _Chip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacing8,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(
          color: AppColors.primary,
          fontSize: 11,
        ),
      ),
    );
  }
}

// ── Caregiver Avatar ──────────────────────────────────────

class _CaregiverAvatar extends StatelessWidget {
  final String name;
  final String? imageUrl;

  const _CaregiverAvatar({required this.name, this.imageUrl});

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null) {
      return ClipOval(
        child: Image.network(
          imageUrl!,
          width: 28,
          height: 28,
          fit: BoxFit.cover,
          errorBuilder: (_, e, s) => _initials(),
        ),
      );
    }
    return _initials();
  }

  Widget _initials() {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primary.withValues(alpha: 0.12),
      ),
      child: Center(
        child: Text(
          initial,
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.primary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ── Service Card ──────────────────────────────────────────

class _ServiceCard extends ConsumerWidget {
  final ServiceModel service;

  const _ServiceCard({required this.service});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final delta = ref.watch(upvoteCountDeltaProvider(service.id));
    final caregiver = service.caregiverProfile;

    return GestureDetector(
      onTap: () => context.push(AppRoutes.serviceDetail, extra: service),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          border: Border.all(color: AppColors.border),
        ),
        padding: const EdgeInsets.all(AppDimensions.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    service.title,
                    style: AppTextStyles.titleSmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppDimensions.spacing8),
                Row(
                  children: [
                    const Icon(Icons.thumb_up_outlined,
                        size: 13, color: AppColors.primary),
                    const SizedBox(width: 3),
                    Text(
                      '${service.upvoteCount + delta}',
                      style: AppTextStyles.labelSmall
                          .copyWith(color: AppColors.primary),
                    ),
                  ],
                ),
              ],
            ),
            if (service.description != null) ...[
              const SizedBox(height: AppDimensions.spacing6),
              Text(
                service.description!,
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: AppDimensions.spacing12),
            Row(
              children: [
                _Chip(label: service.serviceType),
                const SizedBox(width: AppDimensions.spacing6),
                _Chip(label: service.paymentType),
              ],
            ),
            if (caregiver != null) ...[
              const SizedBox(height: AppDimensions.spacing12),
              const Divider(height: 1, color: AppColors.border),
              const SizedBox(height: AppDimensions.spacing12),
              Row(
                children: [
                  _CaregiverAvatar(
                    name: caregiver.name,
                    imageUrl: service.image,
                  ),
                  const SizedBox(width: AppDimensions.spacing8),
                  Expanded(
                    child: Text(
                      caregiver.name,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded,
                      size: 13, color: AppColors.textHint),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Add Service Card ──────────────────────────────────────

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
          strokeWidth: 1.5,
          dashPattern: const [6, 4],
          radius: Radius.circular(AppDimensions.radiusLg),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          ),
          padding: const EdgeInsets.all(AppDimensions.spacing16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 22),
              ),
              const SizedBox(width: AppDimensions.spacing12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Offer a Service', style: AppTextStyles.titleSmall),
                    const SizedBox(height: AppDimensions.spacing2),
                    Text(
                      'Share your expertise with families',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppDimensions.spacing8),
              const Icon(Icons.arrow_forward_ios_rounded,
                  size: 13, color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }
}

// ── My Service Card ───────────────────────────────────────

class _MyServiceCard extends ConsumerWidget {
  final ServiceModel service;
  const _MyServiceCard({required this.service});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final delta = ref.watch(upvoteCountDeltaProvider(service.id));

    return GestureDetector(
      onTap: () =>
          context.push(AppRoutes.editableServiceDetail, extra: service),
      child: DottedBorder(
        options: RoundedRectDottedBorderOptions(
          color: AppColors.primary,
          strokeWidth: 1.5,
          dashPattern: const [6, 4],
          radius: const Radius.circular(AppDimensions.radiusLg),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          ),
          padding: const EdgeInsets.all(AppDimensions.spacing16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'YOUR SERVICE',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.primary,
                            fontSize: 10,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: AppDimensions.spacing4),
                        Text(
                          service.title,
                          style: AppTextStyles.titleSmall,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spacing8),
                  Row(
                    children: [
                      const Icon(Icons.thumb_up_outlined,
                          size: 13, color: AppColors.primary),
                      const SizedBox(width: 3),
                      Text(
                        '${service.upvoteCount + delta}',
                        style: AppTextStyles.labelSmall
                            .copyWith(color: AppColors.primary),
                      ),
                    ],
                  ),
                ],
              ),
              if (service.description != null) ...[
                const SizedBox(height: AppDimensions.spacing8),
                Text(
                  service.description!,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: AppDimensions.spacing12),
              Row(
                children: [
                  _Chip(label: service.serviceType),
                  const SizedBox(width: AppDimensions.spacing6),
                  _Chip(label: service.paymentType),
                  const Spacer(),
                  const Icon(Icons.arrow_forward_ios_rounded,
                      size: 13, color: AppColors.primary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
