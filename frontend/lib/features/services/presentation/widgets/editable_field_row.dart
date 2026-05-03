import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/theme/app_dimensions.dart';
import 'package:frontend/core/theme/app_text_styles.dart';

/// Tappable text row with an edit icon — used for title, description, etc.
class EditableFieldRow extends StatelessWidget {
  final String? value;
  final String? hint;
  final TextStyle style;
  final Widget? prefix;
  final VoidCallback onEdit;

  const EditableFieldRow({
    super.key,
    required this.style,
    required this.onEdit,
    this.value,
    this.hint,
    this.prefix,
  });

  @override
  Widget build(BuildContext context) {
    final isEmpty = value == null || value!.isEmpty;
    return GestureDetector(
      onTap: onEdit,
      behavior: HitTestBehavior.opaque,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (prefix != null) ...[
            prefix!,
            const SizedBox(width: AppDimensions.spacing6),
          ],
          Expanded(
            child: isEmpty
                ? Text(
                    hint ?? 'Tap to add',
                    style: style.copyWith(
                      color: AppColors.textHint,
                      fontStyle: FontStyle.italic,
                    ),
                  )
                : Text(value!, style: style),
          ),
          const SizedBox(width: AppDimensions.spacing8),
          const Icon(Icons.edit_outlined, size: 15, color: AppColors.textHint),
        ],
      ),
    );
  }
}

/// Tappable chip with an inline edit icon — used for service type, payment type, etc.
class EditableChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onEdit;

  const EditableChip({
    super.key,
    required this.label,
    required this.icon,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onEdit,
      child: Container(
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
              style: AppTextStyles.labelSmall.copyWith(color: AppColors.primaryDark),
            ),
            const SizedBox(width: AppDimensions.spacing4),
            const Icon(Icons.edit_outlined, size: 11, color: AppColors.primaryDark),
          ],
        ),
      ),
    );
  }
}
