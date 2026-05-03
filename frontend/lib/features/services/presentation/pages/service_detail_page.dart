import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/theme/app_dimensions.dart';
import 'package:frontend/core/theme/app_text_styles.dart';
import 'package:frontend/features/profile/domain/models/profile_model.dart'
    hide CaregiverProfileModel;
import 'package:frontend/features/profile/presentation/providers/profile_provider.dart';
import 'package:frontend/features/requests/domain/models/request_model.dart';
import 'package:frontend/features/requests/presentation/providers/request_provider.dart';
import 'package:frontend/features/services/domain/models/service_model.dart';
import 'package:frontend/features/interactions/presentation/providers/upvote_provider.dart';

class ServiceDetailPage extends ConsumerWidget {
  final ServiceModel service;

  const ServiceDetailPage({super.key, required this.service});

  void _showReportSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusXl),
        ),
      ),
      builder: (_) => _ReportSheet(service: service),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AppColors.background,
            elevation: 0,
            scrolledUnderElevation: 0,
            pinned: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.flag_outlined, color: AppColors.textHint),
                tooltip: 'Report service',
                onPressed: () => _showReportSheet(context),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ServiceHero(image: service.image),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ServiceInfoSection(service: service),
                      if (service.caregiverProfile != null) ...[
                        const SizedBox(height: AppDimensions.spacing32),
                        _ProviderSection(service: service),
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

// ── Service Hero ──────────────────────────────────────────

class _ServiceHero extends StatelessWidget {
  final String? image;
  const _ServiceHero({required this.image});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      width: double.infinity,
      color: AppColors.primary.withValues(alpha: 0.08),
      child: image != null
          ? Image.network(image!, fit: BoxFit.cover)
          : Center(
              child: Icon(
                Icons.design_services_outlined,
                size: 56,
                color: AppColors.primary.withValues(alpha: 0.4),
              ),
            ),
    );
  }
}

// ── Service Info ──────────────────────────────────────────

class _ServiceInfoSection extends ConsumerWidget {
  final ServiceModel service;
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
                              ? 'Accept a request first to upvote'
                              : 'Could not upvote. Try again.',
                        ),
                      ),
                    );
                  }
                }
              },
              child: upvoteAsync.when(
                loading: () => _UpvotePill(
                  count: service.upvoteCount,
                  isUpvoted: false,
                  loading: true,
                ),
                error: (_, e) =>
                    _UpvotePill(count: service.upvoteCount, isUpvoted: false),
                data: (_) => _UpvotePill(
                  count: service.upvoteCount + delta,
                  isUpvoted: isUpvoted,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.spacing12),
        Row(
          children: [
            _Chip(label: service.serviceType, icon: Icons.location_on_outlined),
            const SizedBox(width: AppDimensions.spacing8),
            _Chip(label: service.paymentType, icon: Icons.payments_outlined),
          ],
        ),
        if (service.description != null) ...[
          const SizedBox(height: AppDimensions.spacing20),
          _SectionLabel('About this service'),
          const SizedBox(height: AppDimensions.spacing8),
          Text(
            service.description!,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
        const SizedBox(height: AppDimensions.spacing20),
        _InfoGrid(service: service),
      ],
    );
  }
}

// ── Upvote Pill ───────────────────────────────────────────

class _UpvotePill extends StatelessWidget {
  final int count;
  final bool isUpvoted;
  final bool loading;

  const _UpvotePill({
    required this.count,
    required this.isUpvoted,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacing12,
        vertical: AppDimensions.spacing6,
      ),
      decoration: BoxDecoration(
        color: isUpvoted
            ? AppColors.primary.withValues(alpha: 0.1)
            : Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        border: Border.all(
          color: isUpvoted ? AppColors.primary : AppColors.border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          loading
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: AppColors.primary,
                  ),
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

// ── Info Grid ─────────────────────────────────────────────

class _InfoGrid extends StatelessWidget {
  final ServiceModel service;
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
      items.add(_InfoItem(
        icon: Icons.person_outline,
        label: 'Gender',
        value: service.targetGender,
      ));
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel('Target audience'),
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

// ── Provider Section ──────────────────────────────────────

class _ProviderSection extends ConsumerWidget {
  final ServiceModel service;
  const _ProviderSection({required this.service});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = service.caregiverProfile!;
    final requestAsync = ref.watch(parentRequestsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel('About the provider'),
        const SizedBox(height: AppDimensions.spacing12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppDimensions.spacing20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ProviderHeader(profile: profile),
              if (profile.aboutMe != null && profile.aboutMe!.isNotEmpty ||
                  profile.qualifications != null &&
                      profile.qualifications!.isNotEmpty ||
                  profile.languages.isNotEmpty) ...[
                const SizedBox(height: AppDimensions.spacing16),
                const Divider(height: 1, color: AppColors.border),
                const SizedBox(height: AppDimensions.spacing16),
                _ProviderDetails(profile: profile),
              ],
              const SizedBox(height: AppDimensions.spacing16),
              requestAsync.when(
                loading: () => const Center(
                  child: SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                error: (_, e) => _RequestButton(serviceId: service.id),
                data: (allRequests) {
                  final serviceRequest = allRequests
                      .where((r) => r.serviceId == service.id)
                      .firstOrNull;
                  final acceptedForCaregiver = allRequests
                      .where(
                        (r) =>
                            r.caregiverId == service.caregiverId &&
                            r.status == 'Accepted',
                      )
                      .firstOrNull;

                  if (acceptedForCaregiver != null) {
                    return _RequestStatus(request: acceptedForCaregiver);
                  }
                  if (serviceRequest != null) {
                    return _RequestStatus(request: serviceRequest);
                  }
                  return _RequestButton(serviceId: service.id);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProviderHeader extends StatelessWidget {
  final CaregiverProfileModel profile;
  const _ProviderHeader({required this.profile});

  String _initials(String name) {
    final parts = name.trim().split(' ');
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
              _initials(profile.name),
              style: AppTextStyles.titleMedium.copyWith(color: AppColors.primary),
            ),
          ),
        ),
        const SizedBox(width: AppDimensions.spacing12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(profile.name, style: AppTextStyles.titleSmall),
              if (profile.gender != null && profile.gender!.isNotEmpty) ...[
                const SizedBox(height: AppDimensions.spacing4),
                Text(
                  profile.gender!,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              if (profile.streetAddress != null && profile.streetAddress!.isNotEmpty) ...[
                const SizedBox(height: AppDimensions.spacing4),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 12, color: AppColors.textHint),
                    const SizedBox(width: 3),
                    Text(
                      profile.streetAddress!,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ProviderDetails extends StatelessWidget {
  final CaregiverProfileModel profile;
  const _ProviderDetails({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (profile.aboutMe != null && profile.aboutMe!.isNotEmpty) ...[
          _DetailRow(label: 'About', value: profile.aboutMe!),
          const SizedBox(height: AppDimensions.spacing16),
        ],
        if (profile.qualifications != null &&
            profile.qualifications!.isNotEmpty) ...[
          _DetailRow(label: 'Qualifications', value: profile.qualifications!),
          const SizedBox(height: AppDimensions.spacing16),
        ],
        if (profile.languages.isNotEmpty) _LanguagesRow(languages: profile.languages),
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
        Text(
          label.toUpperCase(),
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textSecondary,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: AppDimensions.spacing6),
        Text(
          value,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
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
        Text(
          'LANGUAGES',
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textSecondary,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: AppDimensions.spacing8),
        Wrap(
          spacing: AppDimensions.spacing6,
          runSpacing: AppDimensions.spacing6,
          children: languages
              .map((lang) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.spacing12,
                      vertical: AppDimensions.spacing4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusFull),
                    ),
                    child: Text(
                      lang,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }
}

// ── Request Button ────────────────────────────────────────

class _RequestButton extends ConsumerWidget {
  final int serviceId;
  const _RequestButton({required this.serviceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      height: AppDimensions.buttonHeight,
      child: Material(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        child: InkWell(
          onTap: () => _showRequestSheet(context, ref, serviceId),
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.phone_outlined, size: 18, color: Colors.white),
              const SizedBox(width: AppDimensions.spacing8),
              Text(
                'Request Contact',
                style: AppTextStyles.labelLarge
                    .copyWith(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRequestSheet(BuildContext context, WidgetRef ref, int serviceId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusXl),
        ),
      ),
      builder: (_) => _RequestSheet(serviceId: serviceId),
    );
  }
}

// ── Request Status ────────────────────────────────────────

class _RequestStatus extends StatelessWidget {
  final RequestModel request;
  const _RequestStatus({required this.request});

  @override
  Widget build(BuildContext context) {
    final isAccepted = request.status == 'Accepted';
    final isPending = request.status == 'Pending';

    final (color, bg) = switch (request.status) {
      'Accepted' => (const Color(0xFF2E7D32), const Color(0xFFE8F5E9)),
      'Rejected' => (const Color(0xFFC62828), const Color(0xFFFFEBEE)),
      _ => (AppColors.textSecondary, AppColors.background),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacing12,
            vertical: AppDimensions.spacing6,
          ),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
          ),
          child: Text(
            isPending ? 'Request Pending' : request.status,
            style: AppTextStyles.labelSmall.copyWith(color: color),
          ),
        ),
        if (isAccepted && request.caregiverPhone != null) ...[
          const SizedBox(height: AppDimensions.spacing12),
          GestureDetector(
            onLongPress: () {
              Clipboard.setData(ClipboardData(text: request.caregiverPhone!));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Phone number copied')),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.spacing16,
                vertical: AppDimensions.spacing12,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                border: Border.all(color: const Color(0xFFA5D6A7)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.phone_outlined,
                      size: 16, color: Color(0xFF2E7D32)),
                  const SizedBox(width: AppDimensions.spacing8),
                  Text(
                    request.caregiverPhone!,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: const Color(0xFF2E7D32),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Hold to copy',
                    style: AppTextStyles.labelSmall
                        .copyWith(color: AppColors.textHint),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ── Request Sheet ─────────────────────────────────────────

class _RequestSheet extends ConsumerStatefulWidget {
  final int serviceId;
  const _RequestSheet({required this.serviceId});

  @override
  ConsumerState<_RequestSheet> createState() => _RequestSheetState();
}

class _RequestSheetState extends ConsumerState<_RequestSheet> {
  ChildProfileModel? _selectedChild;
  final _noteController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedChild == null) return;
    setState(() => _loading = true);
    try {
      await ref.read(requestProvider.notifier).sendRequest(
            serviceId: widget.serviceId,
            childId: _selectedChild!.id,
            note: _noteController.text.trim(),
          );
      ref.invalidate(parentRequestsProvider);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);
    final children = profileAsync.value?.cwsnProfile?.children ?? [];

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).viewInsets.bottom + 32,
      ),
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
          Text('Request Contact', style: AppTextStyles.titleMedium),
          const SizedBox(height: AppDimensions.spacing4),
          Text(
            'Select the child this request is for',
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppDimensions.spacing20),
          if (children.isEmpty)
            Container(
              padding: const EdgeInsets.all(AppDimensions.spacing16),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              ),
              child: Text(
                'No children added yet. Add a child from your profile first.',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary),
              ),
            )
          else
            ...children.map(
              (child) => _ChildOption(
                child: child,
                selected: _selectedChild?.id == child.id,
                onTap: () => setState(() => _selectedChild = child),
              ),
            ),
          const SizedBox(height: AppDimensions.spacing12),
          TextField(
            controller: _noteController,
            maxLines: 3,
            style: AppTextStyles.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Add a note (optional)',
              hintStyle: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textHint),
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.spacing20),
          SizedBox(
            width: double.infinity,
            height: AppDimensions.buttonHeight,
            child: Material(
              color: _selectedChild == null
                  ? AppColors.border
                  : AppColors.primary,
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              child: InkWell(
                onTap: (_selectedChild == null || _loading) ? null : _submit,
                borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                child: Center(
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Send Request',
                          style: AppTextStyles.labelLarge.copyWith(
                            color: Colors.white,
                            fontSize: 16,
                          ),
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

class _ChildOption extends StatelessWidget {
  final ChildProfileModel child;
  final bool selected;
  final VoidCallback onTap;

  const _ChildOption({
    required this.child,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppDimensions.spacing8),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacing16,
          vertical: AppDimensions.spacing12,
        ),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.06)
              : AppColors.background,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              size: 18,
              color: selected ? AppColors.primary : AppColors.textHint,
            ),
            const SizedBox(width: AppDimensions.spacing12),
            Text(
              '${child.name} · ${child.age}y · ${child.gender}',
              style: AppTextStyles.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Section Label ─────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: AppTextStyles.labelSmall.copyWith(
        color: AppColors.textSecondary,
        letterSpacing: 1,
      ),
    );
  }
}

// ── Shared Chip ───────────────────────────────────────────

class _Chip extends StatelessWidget {
  final String label;
  final IconData icon;
  const _Chip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
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
        ],
      ),
    );
  }
}

// ── Report Sheet ──────────────────────────────────────────

class _ReportSheet extends ConsumerStatefulWidget {
  final ServiceModel service;
  const _ReportSheet({required this.service});

  @override
  ConsumerState<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends ConsumerState<_ReportSheet> {
  final _reasonController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final reason = _reasonController.text.trim();
    if (reason.isEmpty) return;

    setState(() => _loading = true);
    try {
      await ref.read(reportProvider).reportService(
            reportedUserId: widget.service.caregiverId,
            reason: reason,
          );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report submitted. Thank you.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to submit report. Try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
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
            children: [
              const Icon(Icons.flag_outlined, color: Color(0xFFC62828), size: 18),
              const SizedBox(width: AppDimensions.spacing8),
              Text('Report Service', style: AppTextStyles.titleMedium),
            ],
          ),
          const SizedBox(height: AppDimensions.spacing4),
          Text(
            'Describe the issue. Our team will review it.',
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppDimensions.spacing16),
          TextField(
            controller: _reasonController,
            maxLines: 4,
            autofocus: true,
            style: AppTextStyles.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Explain what\'s wrong...',
              hintStyle: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textHint),
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.spacing20),
          SizedBox(
            width: double.infinity,
            height: AppDimensions.buttonHeight,
            child: Material(
              color: const Color(0xFFC62828),
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              child: InkWell(
                onTap: _loading ? null : _submit,
                borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                child: Center(
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Submit Report',
                          style: AppTextStyles.labelLarge.copyWith(
                            color: Colors.white,
                            fontSize: 16,
                          ),
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
