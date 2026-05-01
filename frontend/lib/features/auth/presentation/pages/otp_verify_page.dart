import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/theme/app_dimensions.dart';
import 'package:frontend/core/theme/app_text_styles.dart';
import 'package:frontend/features/auth/presentation/providers/auth_provider.dart';
import 'package:pinput/pinput.dart';

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

    final baseDecoration = BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      border: Border.all(color: AppColors.border),
    );

    final defaultTheme = PinTheme(
      width: 46,
      height: 52,
      textStyle: AppTextStyles.bodyLarge.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w500,
      ),
      decoration: baseDecoration,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text('OTP Verification', style: AppTextStyles.titleMedium),
      ),
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

              Center(child: Pinput(
                controller: _pinController,
                focusNode: _focusNode,
                enabled: !isLoading,
                length: 6,
                defaultPinTheme: defaultTheme,
                focusedPinTheme: defaultTheme.copyWith(
                  decoration: baseDecoration.copyWith(
                    border: Border.all(color: AppColors.primary, width: 1.5),
                  ),
                ),
                submittedPinTheme: defaultTheme.copyWith(
                  decoration: baseDecoration.copyWith(
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
                onChanged: (_) {
                  if (_errorText != null) setState(() => _errorText = null);
                },
                onCompleted: (code) {
                  ref.read(authProvider.notifier).verifyOtp(code);
                },
              )),

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
