import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/theme/app_dimensions.dart';
import 'package:frontend/core/theme/app_text_styles.dart';

class InfoRow extends StatelessWidget {
  final String label;
  final String? value;

  const InfoRow(this.label, this.value, {super.key});

  @override
  Widget build(BuildContext context) {
    final isEmpty = value == null || value!.isEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacing12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              isEmpty ? '—' : value!,
              style: AppTextStyles.bodySmall.copyWith(
                color: isEmpty ? AppColors.textHint : AppColors.textPrimary,
                fontWeight: isEmpty ? FontWeight.w400 : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class EmptyRow extends StatelessWidget {
  final String message;
  const EmptyRow(this.message, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacing12),
      child: Text(
        message,
        style: AppTextStyles.bodySmall.copyWith(
          color: AppColors.textHint,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}
