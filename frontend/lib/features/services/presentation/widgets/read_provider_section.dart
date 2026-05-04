import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/theme/app_dimensions.dart';
import 'package:frontend/core/theme/app_text_styles.dart';
import 'package:frontend/features/requests/presentation/providers/request_provider.dart';
import 'package:frontend/features/services/domain/models/service_model.dart';
import 'package:frontend/features/services/presentation/widgets/provider_section.dart';
import 'package:frontend/features/services/presentation/widgets/request_section.dart';
import 'package:frontend/features/services/presentation/widgets/section_label.dart';

/// Read-only provider card shown on ServiceDetailPage.
class ReadProviderSection extends ConsumerWidget {
  final ServiceModel service;

  const ReadProviderSection({super.key, required this.service});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = service.caregiverProfile!;
    final requestAsync = ref.watch(parentRequestsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel('About the provider'),
        const SizedBox(height: AppDimensions.spacing12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppDimensions.spacing20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProviderHeader(
                name: profile.name,
                gender: profile.gender,
                streetAddress: profile.streetAddress,
              ),
              if (profile.aboutMe != null && profile.aboutMe!.isNotEmpty ||
                  profile.qualifications != null && profile.qualifications!.isNotEmpty ||
                  profile.languages.isNotEmpty) ...[
                const SizedBox(height: AppDimensions.spacing16),
                const Divider(height: 1, color: AppColors.border),
                const SizedBox(height: AppDimensions.spacing16),
                _ReadProviderDetails(profile: profile),
              ],
              const SizedBox(height: AppDimensions.spacing16),
              requestAsync.when(
                loading: () => const Center(
                  child: SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                  ),
                ),
                error: (_, e) => RequestButton(serviceId: service.id),
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
                    return RequestStatus(request: acceptedForCaregiver);
                  }
                  if (serviceRequest != null) {
                    return RequestStatus(request: serviceRequest);
                  }
                  return RequestButton(serviceId: service.id);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReadProviderDetails extends StatelessWidget {
  final CaregiverProfileModel profile;

  const _ReadProviderDetails({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (profile.aboutMe != null && profile.aboutMe!.isNotEmpty) ...[
          _ReadDetailRow(label: 'About', value: profile.aboutMe!),
          const SizedBox(height: AppDimensions.spacing16),
        ],
        if (profile.qualifications != null && profile.qualifications!.isNotEmpty) ...[
          _ReadDetailRow(label: 'Qualifications', value: profile.qualifications!),
          const SizedBox(height: AppDimensions.spacing16),
        ],
        if (profile.languages.isNotEmpty) _ReadLanguagesRow(languages: profile.languages),
      ],
    );
  }
}

class _ReadDetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _ReadDetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
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

class _ReadLanguagesRow extends StatelessWidget {
  final List<String> languages;

  const _ReadLanguagesRow({required this.languages});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Languages',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
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
                      borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                    ),
                    child: Text(
                      lang,
                      style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary),
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }
}
