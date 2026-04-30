import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/theme/app_dimensions.dart';
import 'package:frontend/core/theme/app_text_styles.dart';
import 'package:frontend/features/services/domain/models/service_model.dart';

class ServiceDetailPage extends StatelessWidget {
  final ServiceModel service;

  const ServiceDetailPage({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(backgroundColor: AppColors.background, elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: AppDimensions.spacing8,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ServiceInfoSection(service: service),
            const SizedBox(height: AppDimensions.spacing24),
            if (service.caregiverProfile != null) ...[
              const _Divider(),
              const SizedBox(height: AppDimensions.spacing24),
              _ProviderSection(profile: service.caregiverProfile!),
              const SizedBox(height: AppDimensions.spacing32),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Service Info ──────────────────────────────────────────

class _ServiceInfoSection extends StatelessWidget {
  final ServiceModel service;
  const _ServiceInfoSection({required this.service});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ServiceHero(image: service.image),
        const SizedBox(height: AppDimensions.spacing20),
        Text(service.title, style: AppTextStyles.displaySmall),
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
          Text('About this service', style: AppTextStyles.titleSmall),
          const SizedBox(height: AppDimensions.spacing8),
          Text(service.description!, style: AppTextStyles.bodyMedium),
        ],
        const SizedBox(height: AppDimensions.spacing20),
        _InfoGrid(service: service),
      ],
    );
  }
}

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
      items.add(
        _InfoItem(icon: Icons.cake_outlined, label: 'Age', value: label),
      );
    }

    if (service.targetGender != 'Any') {
      items.add(
        _InfoItem(
          icon: Icons.person_outline,
          label: 'Gender',
          value: service.targetGender,
        ),
      );
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Target audience', style: AppTextStyles.titleSmall),
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
  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });
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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(item.icon, size: 16, color: AppColors.primary),
          const SizedBox(width: AppDimensions.spacing6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.label, style: AppTextStyles.labelSmall),
              Text(item.value, style: AppTextStyles.labelMedium),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Divider ───────────────────────────────────────────────

class _Divider extends StatelessWidget {
  const _Divider();

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

// ── Provider Section ──────────────────────────────────────

class _ProviderSection extends StatelessWidget {
  final CaregiverProfileModel profile;
  const _ProviderSection({required this.profile});

  bool _hasContent() =>
      (profile.aboutMe?.isNotEmpty ?? false) ||
      (profile.qualifications?.isNotEmpty ?? false) ||
      profile.languages.isNotEmpty;

  @override
  Widget build(BuildContext context) {
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
          _ProviderHeader(profile: profile),
          if (_hasContent()) ...[
            const SizedBox(height: AppDimensions.spacing16),
            const Divider(color: AppColors.border),
            const SizedBox(height: AppDimensions.spacing16),
            _ProviderDetails(profile: profile),
          ],
        ],
      ),
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
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.primary,
              ),
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
                Text(profile.gender!, style: AppTextStyles.bodySmall),
              ],
            ],
          ),
        ),
        if (profile.upvoteCount > 0)
          Row(
            children: [
              const Icon(
                Icons.thumb_up_outlined,
                size: 14,
                color: AppColors.primary,
              ),
              const SizedBox(width: AppDimensions.spacing4),
              Text(
                '${profile.upvoteCount}',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ],
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
          const SizedBox(height: AppDimensions.spacing12),
        ],
        if (profile.qualifications != null &&
            profile.qualifications!.isNotEmpty) ...[
          _DetailRow(label: 'Qualifications', value: profile.qualifications!),
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
