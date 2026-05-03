import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/theme/app_dimensions.dart';
import 'package:frontend/core/theme/app_text_styles.dart';
import 'package:frontend/features/profile/presentation/providers/profile_provider.dart';

class ProfileAvatar extends StatelessWidget {
  final ProfileState profile;

  const ProfileAvatar({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final name = profile.cwsnProfile?.name ?? '';
    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: AppTextStyles.displaySmall.copyWith(color: AppColors.primary),
            ),
          ),
          const SizedBox(height: AppDimensions.spacing12),
          Text(name, style: AppTextStyles.titleLarge),
          if (profile.cwsnProfile?.phoneNumber != null)
            Text(profile.cwsnProfile!.phoneNumber, style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }
}
