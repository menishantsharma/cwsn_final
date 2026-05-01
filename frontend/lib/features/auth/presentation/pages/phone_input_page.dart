import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/theme/app_dimensions.dart';
import 'package:frontend/core/theme/app_text_styles.dart';
import 'package:frontend/features/auth/presentation/providers/auth_provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

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
    ref
        .read(authProvider.notifier)
        .sendOtp('+91${_phoneNumberController.text}');
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
                      style: TextStyle(color: AppColors.primary),
                    ),
                    TextSpan(
                      text: ' starts with\nconnection.',
                      style: TextStyle(color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 3),

              Container(
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
                          Container(
                            width: 1,
                            height: 18,
                            color: AppColors.border,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _phoneNumberController,
                        keyboardType: TextInputType.numberWithOptions(
                          signed: false,
                          decimal: false,
                        ),
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _submit(),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        maxLength: 10,
                        onChanged: (_) => setState(() {}),
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
              ),

              const SizedBox(height: AppDimensions.spacing16),

              SizedBox(
                height: AppDimensions.buttonHeight,
                width: double.infinity,
                child: Material(
                  color: _isValid ? AppColors.primary : AppColors.disabled,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                  child: InkWell(
                    onTap: isLoading || !_isValid ? null : _submit,
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
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const FaIcon(
                                  FontAwesomeIcons.whatsapp,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                const SizedBox(width: AppDimensions.spacing8),
                                Text(
                                  'Send OTP via WhatsApp',
                                  style: AppTextStyles.labelLarge.copyWith(
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
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
