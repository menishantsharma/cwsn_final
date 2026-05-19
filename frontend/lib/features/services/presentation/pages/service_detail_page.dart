import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/theme/app_dimensions.dart';
import 'package:frontend/core/theme/app_text_styles.dart';
import 'package:frontend/features/interactions/presentation/controllers/upvote_controller.dart';
import 'package:frontend/features/services/domain/service_models.dart';
import 'package:frontend/features/services/presentation/controllers/service_controller.dart';
import 'package:frontend/features/services/presentation/widgets/read_provider_section.dart';
import 'package:frontend/features/services/presentation/widgets/request_section.dart';
import 'package:frontend/features/services/presentation/widgets/section_label.dart';
import 'package:frontend/features/services/presentation/widgets/service_chip.dart';
import 'package:frontend/features/services/presentation/widgets/service_hero.dart';

class ServiceDetailPage extends ConsumerWidget {
  final int serviceId;

  const ServiceDetailPage({super.key, required this.serviceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(serviceDetailProvider(serviceId));

    final service = detailAsync.value;

    final appBar = SliverAppBar(
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
      actions: service == null ? null : [
        IconButton(
          icon: const Icon(Icons.flag_outlined, color: AppColors.textHint),
          tooltip: 'Report service',
          onPressed: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.white,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppDimensions.radiusXl),
              ),
            ),
            builder: (_) => ReportSheet(serviceId: service.id, caregiverId: service.caregiverId),
          ),
        ),
      ],
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: detailAsync.when(
        loading: () => CustomScrollView(
          slivers: [
            appBar,
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
            ),
          ],
        ),
        error: (e, _) => CustomScrollView(
          slivers: [
            appBar,
            SliverFillRemaining(
              child: Center(
                child: Text(
                  'Could not load service details. Please go back and try again.',
                  style: AppTextStyles.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
        data: (service) => CustomScrollView(
          slivers: [
            appBar,
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
                        _ServiceInfoSection(service: service),
                        if (service.caregiverProfile != null) ...[
                          const SizedBox(height: AppDimensions.spacing32),
                          ReadProviderSection(service: service),
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
      ),
    );
  }
}

class _ServiceInfoSection extends ConsumerWidget {
  final ServiceDetailModel service;
  const _ServiceInfoSection({required this.service});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isUpvoted = ref.watch(isUpvotedProvider(service.id));
    final delta = ref.watch(upvoteCountDeltaProvider(service.id));
    final upvoteAsync = ref.watch(upvoteProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(service.title, style: AppTextStyles.displaySmall),
            ),
            const SizedBox(width: AppDimensions.spacing12),
            GestureDetector(
              onTap: () async {
                try {
                  await ref.read(upvoteProvider.notifier).toggle(service.id);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          e.toString().contains('400')
                              ? 'You need to accept a request before upvoting.'
                              : 'Could not upvote. Please try again.',
                        ),
                      ),
                    );
                  }
                }
              },
              child: upvoteAsync.when(
                loading: () => _UpvotePill(count: service.upvoteCount, isUpvoted: false, loading: true),
                error: (_, e) => _UpvotePill(count: service.upvoteCount, isUpvoted: false),
                data: (_) => _UpvotePill(count: service.upvoteCount + delta, isUpvoted: isUpvoted),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.spacing12),
        Row(
          children: [
            ServiceDetailChip(label: service.serviceType),
            const SizedBox(width: AppDimensions.spacing8),
            ServiceDetailChip(label: service.paymentType),
          ],
        ),
        if (service.description != null) ...[
          const SizedBox(height: AppDimensions.spacing20),
          SectionLabel('About this service'),
          const SizedBox(height: AppDimensions.spacing8),
          _ExpandableText(text: service.description!),
        ],
        const SizedBox(height: AppDimensions.spacing20),
        _InfoGrid(service: service),
      ],
    );
  }
}

class _UpvotePill extends StatelessWidget {
  final int count;
  final bool isUpvoted;
  final bool loading;

  const _UpvotePill({required this.count, required this.isUpvoted, this.loading = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacing12,
        vertical: AppDimensions.spacing6,
      ),
      decoration: BoxDecoration(
        color: isUpvoted ? AppColors.primary.withValues(alpha: 0.1) : Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        border: Border.all(color: isUpvoted ? AppColors.primary : AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          loading
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.primary),
                )
              : Icon(
                  isUpvoted ? Icons.thumb_up : Icons.thumb_up_outlined,
                  size: 14,
                  color: isUpvoted ? AppColors.primary : AppColors.textSecondary,
                ),
          const SizedBox(width: AppDimensions.spacing4),
          Text(
            '$count',
            style: AppTextStyles.labelMedium.copyWith(
              color: isUpvoted ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpandableText extends StatefulWidget {
  final String text;
  const _ExpandableText({required this.text});

  @override
  State<_ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<_ExpandableText> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final style = AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary, height: 1.5);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.text,
          style: style,
          maxLines: _expanded ? null : 3,
          overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final tp = TextPainter(
              text: TextSpan(text: widget.text, style: style),
              maxLines: 3,
              textDirection: TextDirection.ltr,
            )..layout(maxWidth: constraints.maxWidth);
            if (!tp.didExceedMaxLines) return const SizedBox.shrink();
            return GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  _expanded ? 'See less' : 'See more',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _InfoGrid extends StatelessWidget {
  final ServiceDetailModel service;
  const _InfoGrid({required this.service});

  @override
  Widget build(BuildContext context) {
    final hasAge = service.targetAgeMin != null || service.targetAgeMax != null;
    final items = <_InfoItem>[];

    if (hasAge) {
      final min = service.targetAgeMin;
      final max = service.targetAgeMax;
      final label = min != null && max != null
          ? '$min – $max years'
          : min != null
          ? '$min+ years'
          : 'Up to $max years';
      items.add(_InfoItem(icon: Icons.cake_outlined, label: 'Age', value: label));
    }

    if (service.targetGender != 'Any') {
      items.add(_InfoItem(icon: Icons.person_outline, label: 'Gender', value: service.targetGender));
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel('Target audience'),
        const SizedBox(height: AppDimensions.spacing12),
        Wrap(
          spacing: AppDimensions.spacing12,
          runSpacing: AppDimensions.spacing12,
          children: items.map((item) => _InfoTile(item: item)).toList(),
        ),
      ],
    );
  }
}

class _InfoItem {
  final IconData icon;
  final String label;
  final String value;
  const _InfoItem({required this.icon, required this.label, required this.value});
}

class _InfoTile extends StatelessWidget {
  final _InfoItem item;
  const _InfoTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacing12,
        vertical: AppDimensions.spacing8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(item.icon, size: 15, color: AppColors.primary),
          const SizedBox(width: AppDimensions.spacing6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.label.toUpperCase(),
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textHint,
                  fontSize: 9,
                  letterSpacing: 0.8,
                ),
              ),
              Text(item.value, style: AppTextStyles.labelMedium),
            ],
          ),
        ],
      ),
    );
  }
}
