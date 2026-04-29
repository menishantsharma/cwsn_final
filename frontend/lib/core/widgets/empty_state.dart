import 'package:flutter/cupertino.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/theme/app_dimensions.dart';
import 'package:frontend/core/theme/app_text_styles.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: AppColors.textHint),
          SizedBox(height: AppDimensions.spacing16),
          Text(title, style: AppTextStyles.titleSmall),
          if (subtitle != null) ...[
            const SizedBox(height: AppDimensions.spacing8),
            Text(subtitle!, style: AppTextStyles.bodyMedium),
          ],
        ],
      ),
    );
  }
}
