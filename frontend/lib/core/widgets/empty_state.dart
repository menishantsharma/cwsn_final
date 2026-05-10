import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/theme/app_dimensions.dart';
import 'package:frontend/core/theme/app_text_styles.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;

  /// When provided, the empty state is wrapped in a [RefreshIndicator] so the
  /// user can pull to refresh even when the list is empty.
  final Future<void> Function()? onRefresh;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final content = Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: AppColors.textHint),
          const SizedBox(height: AppDimensions.spacing16),
          Text(title, style: AppTextStyles.titleSmall),
          if (subtitle != null) ...[
            const SizedBox(height: AppDimensions.spacing8),
            Text(subtitle!, style: AppTextStyles.bodyMedium),
          ],
        ],
      ),
    );

    if (onRefresh == null) return content;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: onRefresh!,
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: content,
          ),
        ),
      ),
    );
  }
}
