import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/theme/app_dimensions.dart';
import 'package:frontend/core/theme/app_text_styles.dart';
import 'package:frontend/features/auth/presentation/providers/auth_provider.dart';
import 'package:frontend/features/auth/presentation/widgets/phone_input_field.dart';
import 'package:frontend/features/auth/presentation/widgets/send_otp_button.dart';

class PhoneInputPage extends ConsumerStatefulWidget {
  const PhoneInputPage({super.key});

  @override
  ConsumerState<PhoneInputPage> createState() => _PhoneInputPageState();
}

class _PhoneInputPageState extends ConsumerState<PhoneInputPage> {
  final TextEditingController _phoneNumberController = TextEditingController();
  bool get _isValid => _phoneNumberController.text.length == 10;

  @override
  void dispose() {
    _phoneNumberController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_isValid) return;
    ref.read(authProvider.notifier).sendOtp('+91${_phoneNumberController.text}');
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authProvider.select((s) => s.isLoading));

    ref.listen<AsyncValue<AuthState>>(authProvider, (_, next) {
      next.whenOrNull(
        error: (error, _) {
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
      backgroundColor: AppColors.background,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: Padding(
            padding: AppDimensions.pagePadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Spacer(flex: 3),

                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: AppTextStyles.displayMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 28,
                    ),
                    children: [
                      TextSpan(
                        text: 'Care',
                        style: const TextStyle(color: AppColors.primary),
                      ),
                      TextSpan(
                        text: ' starts with\nconnection.',
                        style: const TextStyle(color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ),

                const Spacer(flex: 3),

                PhoneInputField(
                  controller: _phoneNumberController,
                  onSubmitted: _submit,
                  onChanged: () => setState(() {}),
                ),

                const SizedBox(height: AppDimensions.spacing16),

                SendOtpButton(
                  isValid: _isValid,
                  isLoading: isLoading,
                  onTap: _submit,
                ),

                const SizedBox(height: AppDimensions.spacing16),

                Text(
                  'By continuing, you agree to our Terms & Privacy Policy',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textHint,
                    fontSize: 11,
                    height: 1.5,
                  ),
                ),

                const Spacer(flex: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
