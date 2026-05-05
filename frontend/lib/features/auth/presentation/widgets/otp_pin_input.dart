import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/theme/app_dimensions.dart';
import 'package:frontend/core/theme/app_text_styles.dart';
import 'package:pinput/pinput.dart';

class OtpPinInput extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final bool hasError;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onCompleted;

  const OtpPinInput({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.hasError,
    required this.onChanged,
    required this.onCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final baseDecoration = BoxDecoration(
      color: AppColors.surfaceVariant,
      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
    );

    final defaultTheme = PinTheme(
      width: 48,
      height: 56,
      textStyle: AppTextStyles.titleMedium.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
      decoration: baseDecoration,
    );

    return Pinput(
      controller: controller,
      focusNode: focusNode,
      enabled: enabled,
      length: 6,
      defaultPinTheme: defaultTheme,
      focusedPinTheme: defaultTheme.copyWith(
        decoration: baseDecoration.copyWith(
          color: AppColors.primary.withValues(alpha: 0.08),
          border: Border.all(color: AppColors.primary, width: 1.5),
        ),
      ),
      submittedPinTheme: defaultTheme.copyWith(
        decoration: baseDecoration.copyWith(
          color: AppColors.primaryLight,
          border: Border.all(color: AppColors.primary, width: 1.5),
        ),
      ),
      errorPinTheme: defaultTheme.copyWith(
        decoration: baseDecoration.copyWith(
          color: AppColors.errorLight,
          border: Border.all(color: AppColors.error),
        ),
      ),
      autofocus: true,
      pinputAutovalidateMode: PinputAutovalidateMode.onSubmit,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      showCursor: false,
      onChanged: onChanged,
      onCompleted: onCompleted,
    );
  }
}
