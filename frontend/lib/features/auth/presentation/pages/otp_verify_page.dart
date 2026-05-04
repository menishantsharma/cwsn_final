import 'package:flutter/material.dart';
import 'package:frontend/core/widgets/app_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/theme/app_dimensions.dart';
import 'package:frontend/core/theme/app_text_styles.dart';
import 'package:frontend/features/auth/presentation/providers/auth_provider.dart';
import 'package:frontend/features/auth/presentation/widgets/otp_pin_input.dart';

class OtpVerifyPage extends ConsumerStatefulWidget {
  const OtpVerifyPage({super.key});

  @override
  ConsumerState<OtpVerifyPage> createState() => _OtpVerifyPageState();
}

class _OtpVerifyPageState extends ConsumerState<OtpVerifyPage> {
  final _pinController = TextEditingController();
  final _focusNode = FocusNode();
  String? _errorText;

  @override
  void dispose() {
    _pinController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState.isLoading;
    final phoneNumber = authState.value?.phoneNumber ?? '';

    ref.listen<AsyncValue<AuthState>>(authProvider, (_, next) {
      next.whenOrNull(
        error: (error, _) {
          setState(() => _errorText = 'Invalid code. Please try again.');
          _focusNode.requestFocus();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error.toString()),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              ),
              margin: const EdgeInsets.all(AppDimensions.spacing16),
            ),
          );
        },
      );
    });

    return Scaffold(
      appBar: const AppTopBar(title: 'OTP Verification'),
      body: SafeArea(
        child: Padding(
          padding: AppDimensions.pagePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: AppDimensions.spacing32),

              Text(
                'Enter the code sent to\n$phoneNumber',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium,
              ),

              const SizedBox(height: AppDimensions.spacing32),

              Center(
                child: OtpPinInput(
                  controller: _pinController,
                  focusNode: _focusNode,
                  enabled: !isLoading,
                  hasError: _errorText != null,
                  onChanged: (val) {
                    if (_errorText != null) setState(() => _errorText = null);
                  },
                  onCompleted: (code) {
                    ref.read(authProvider.notifier).verifyOtp(code);
                  },
                ),
              ),

              if (_errorText != null) ...[
                const SizedBox(height: AppDimensions.spacing8),
                Text(
                  _errorText!,
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
                ),
              ],

              if (isLoading) ...[
                const SizedBox(height: AppDimensions.spacing24),
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
