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
    final phone = profile.cwsnProfile?.phoneNumber;

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary, width: 2.5),
              ),
            ),
            CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.primary.withValues(alpha: 0.12),
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: AppTextStyles.displaySmall.copyWith(color: AppColors.primary),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.spacing12),
        Text(name, style: AppTextStyles.titleLarge),
        if (phone != null && phone.isNotEmpty) ...[
          const SizedBox(height: AppDimensions.spacing4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.phone_outlined, size: 13, color: AppColors.textHint),
              const SizedBox(width: 4),
              Text(phone, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
            ],
          ),
        ],
      ],
    );
  }
}

