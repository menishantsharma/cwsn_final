import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/theme/app_dimensions.dart';
import 'package:frontend/core/theme/app_text_styles.dart';

class PhoneInputField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSubmitted;
  final VoidCallback onChanged;

  const PhoneInputField({
    super.key,
    required this.controller,
    required this.onSubmitted,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spacing12,
              vertical: AppDimensions.spacing16,
            ),
            child: Row(
              children: [
                SizedBox(
                  height: 18,
                  width: 26,
                  child: CountryFlag.fromCountryCode('IN'),
                ),
                const SizedBox(width: AppDimensions.spacing6),
                Text('+91', style: AppTextStyles.titleSmall),
                const SizedBox(width: AppDimensions.spacing8),
                Container(width: 1, height: 18, color: AppColors.border),
              ],
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                signed: false,
                decimal: false,
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => onSubmitted(),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              maxLength: 10,
              onChanged: (_) => onChanged(),
              decoration: InputDecoration(
                hintText: '98765 43210',
                hintStyle: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textHint,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w400,
                ),
                counterText: '',
                contentPadding: const EdgeInsets.symmetric(
                  vertical: AppDimensions.spacing16,
                  horizontal: AppDimensions.spacing4,
                ),
                border: InputBorder.none,
              ),
              style: AppTextStyles.bodyLarge.copyWith(
                letterSpacing: 2,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
