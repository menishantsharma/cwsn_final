import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/app/app_router.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/theme/app_dimensions.dart';
import 'package:frontend/core/theme/app_text_styles.dart';
import 'package:frontend/features/profile/presentation/providers/profile_provider.dart';

/// Editable provider card — used in CreateServicePage and EditableServiceDetailPage.
class ProviderSection extends ConsumerWidget {
  const ProviderSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);

    return profileAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, e) => const SizedBox.shrink(),
      data: (profile) {
        final cwsn = profile.cwsnProfile;
        final caregiver = profile.caregiverProfile;
        final name = cwsn?.name ?? '';
        final gender = cwsn?.gender;

        return Container(
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
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ProviderHeader(
                      name: name,
                      gender: gender,
                      streetAddress: caregiver?.streetAddress,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.push(AppRoutes.editPersonalInfo),
                    child: Text(
                      'Edit',
                      style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.spacing16),
              const Divider(height: 1, color: AppColors.border),
              const SizedBox(height: AppDimensions.spacing16),
              ProviderDetailRow(label: 'About', value: caregiver?.aboutMe),
              const SizedBox(height: AppDimensions.spacing16),
              ProviderDetailRow(label: 'Qualifications', value: caregiver?.qualifications),
              const SizedBox(height: AppDimensions.spacing16),
              LanguagesBlock(languages: caregiver?.languages ?? []),
              const SizedBox(height: AppDimensions.spacing16),
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () => context.push(AppRoutes.editCaregiverInfo),
                  child: Text(
                    'Edit caregiver info',
                    style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary),
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

class ProviderHeader extends StatelessWidget {
  final String name;
  final String? gender;
  final String? streetAddress;

  const ProviderHeader({
    super.key,
    required this.name,
    required this.gender,
    this.streetAddress,
  });

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
                Text(
                  gender!,
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
              ],
              if (streetAddress != null && streetAddress!.isNotEmpty) ...[
                const SizedBox(height: AppDimensions.spacing4),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 13, color: AppColors.textHint),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        streetAddress!,
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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

class ProviderDetailRow extends StatelessWidget {
  final String label;
  final String? value;

  const ProviderDetailRow({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final isEmpty = value == null || value!.isEmpty;
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
          isEmpty ? 'Not provided' : value!,
          style: AppTextStyles.bodyMedium.copyWith(
            color: isEmpty ? AppColors.textHint : AppColors.textSecondary,
            height: 1.5,
            fontStyle: isEmpty ? FontStyle.italic : FontStyle.normal,
          ),
        ),
      ],
    );
  }
}

class LanguagesBlock extends StatelessWidget {
  final List<String> languages;

  const LanguagesBlock({super.key, required this.languages});

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
        if (languages.isEmpty)
          Text(
            'Not provided',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textHint,
              fontStyle: FontStyle.italic,
              height: 1.5,
            ),
          )
        else
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
