import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/theme/app_dimensions.dart';
import 'package:frontend/core/theme/app_text_styles.dart';

class SendOtpButton extends StatelessWidget {
  final bool isValid;
  final bool isLoading;
  final VoidCallback onTap;

  const SendOtpButton({
    super.key,
    required this.isValid,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppDimensions.buttonHeight,
      width: double.infinity,
      child: Material(
        color: isValid ? AppColors.primary : AppColors.disabled,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        child: InkWell(
          onTap: isLoading || !isValid ? null : onTap,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    'Send OTP',
                    style: AppTextStyles.labelLarge.copyWith(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
