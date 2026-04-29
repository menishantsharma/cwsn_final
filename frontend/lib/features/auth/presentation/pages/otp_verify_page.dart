import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/theme/app_dimensions.dart';
import 'package:frontend/core/theme/app_text_styles.dart';
import 'package:frontend/features/auth/presentation/providers/auth_provider.dart';
import 'package:pinput/pinput.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class OtpVerifyPage extends ConsumerStatefulWidget {
  const OtpVerifyPage({super.key});

  @override
  ConsumerState<OtpVerifyPage> createState() => _OtpVerifyPageState();
}

class _OtpVerifyPageState extends ConsumerState<OtpVerifyPage> {
  final _pinController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _pinController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  PinTheme get _defaultTheme => PinTheme(
    width: 48,
    height: 52,
    textStyle: AppTextStyles.titleLarge.copyWith(
      color: AppColors.textPrimary, // ✅
    ),
    decoration: BoxDecoration(
      color: AppColors.surfaceVariant,
      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      border: Border.all(color: AppColors.border, width: 1.5),
    ),
  );

  PinTheme get _focusedTheme => _defaultTheme.copyWith(
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      border: Border.all(color: AppColors.border, width: 1.5),
    ),
  );

  PinTheme get _submittedTheme => _defaultTheme.copyWith(
    decoration: BoxDecoration(
      color: AppColors.primaryLight,
      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      border: Border.all(color: AppColors.border, width: 1.5),
    ),
  );

  PinTheme get _errorTheme => _defaultTheme.copyWith(
    decoration: BoxDecoration(
      color: AppColors.errorLight,
      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      border: Border.all(color: AppColors.border, width: 1.5),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState.isLoading;
    final phoneNumber = authState.value?.phoneNumber ?? '';

    ref.listen<AsyncValue<AuthState>>(authProvider, (_, next) {
      next.whenOrNull(
        error: (error, _) {
          _pinController.clear();
          _focusNode.requestFocus();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error.toString()),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              ),
              margin: EdgeInsets.all(AppDimensions.spacing16),
            ),
          );
        },
      );
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Verification'),
      ),
      body: SafeArea(
        child: Padding(
          padding: AppDimensions.pagePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppDimensions.spacing32),
              Text('Enter the code', style: AppTextStyles.displayMedium),
              const SizedBox(height: AppDimensions.spacing8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppDimensions.spacing6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusSm,
                      ),
                    ),
                    child: const FaIcon(
                      FontAwesomeIcons.whatsapp,
                      color: AppColors.primary,
                      size: 14,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spacing8),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: AppTextStyles.bodySmall,
                        children: [
                          const TextSpan(text: 'Code sent to '),
                          TextSpan(
                            text:
                                phoneNumber, // ✅ ADDED — shows actual phone number
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const TextSpan(text: ' via WhatsApp'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppDimensions.spacing40),

              Pinput(
                controller: _pinController,
                focusNode: _focusNode,
                enabled: !isLoading,
                length: 6,
                defaultPinTheme: _defaultTheme,
                focusedPinTheme: _focusedTheme,
                submittedPinTheme: _submittedTheme,
                autofocus: true,
                errorPinTheme: _errorTheme,
                pinputAutovalidateMode: PinputAutovalidateMode.onSubmit,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                showCursor: true,
                cursor: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(width: 2, height: 22, color: AppColors.primary),
                  ],
                ),
                onCompleted: (code) {
                  ref.read(authProvider.notifier).verifyOtp(code);
                },
              ),
              const SizedBox(height: AppDimensions.spacing16),
              if (isLoading)
                const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
