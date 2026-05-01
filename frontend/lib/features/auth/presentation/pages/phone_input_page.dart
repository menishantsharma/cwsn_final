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
    final authState = ref.watch(authProvider);
    final isLoading = authState.isLoading;

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
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        title: Text('Verification', style: AppTextStyles.titleMedium),
      ),
      body: SafeArea(
        child: Padding(
          padding: AppDimensions.pagePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppDimensions.spacing32),
              Text(
                'Enter your\nphone number',
                style: AppTextStyles.displayMedium,
              ),

              const SizedBox(height: AppDimensions.spacing12),
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
                          TextSpan(text: 'We will send you an '),
                          TextSpan(
                            text: 'one-time password ',
                            style: AppTextStyles.bodySmall.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                          TextSpan(text: ' via WhatsApp'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.spacing40),
              Text('Mobile Number', style: AppTextStyles.labelMedium),

              const SizedBox(height: AppDimensions.spacing8),

              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                  border: Border.all(
                    color: _isValid ? AppColors.primary : AppColors.border,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _isValid
                          ? AppColors.primary.withValues(alpha: 0.12)
                          : Colors.black.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.spacing12,
                        vertical: AppDimensions.spacing16,
                      ),
                      decoration: BoxDecoration(
                        border: Border(
                          right: BorderSide(
                            color: _isValid
                                ? AppColors.primary.withValues(alpha: 0.3)
                                : AppColors.border,
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            height: 20,
                            width: 28,
                            child: CountryFlag.fromCountryCode('IN'),
                          ),
                          const SizedBox(width: AppDimensions.spacing4),
                          Text('+91', style: AppTextStyles.titleSmall),
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
                          contentPadding: EdgeInsets.symmetric(
                            vertical: AppDimensions.spacing16,
                            horizontal: AppDimensions.spacing16,
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
              const Spacer(),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: AppDimensions.buttonHeight,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _isValid
                        ? [AppColors.primary, AppColors.primaryDark]
                        : [AppColors.disabled, AppColors.disabled],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                  boxShadow: _isValid
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ]
                      : [],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: isLoading || !_isValid ? null : _submit,
                    splashColor: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                    child: Center(
                      child: isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                FaIcon(
                                  FontAwesomeIcons.whatsapp,
                                  color: _isValid
                                      ? Colors.white
                                      : AppColors.disabledText,
                                  size: 20,
                                ),
                                const SizedBox(width: AppDimensions.spacing8),
                                Text(
                                  'Send OTP',
                                  style: AppTextStyles.labelLarge.copyWith(
                                    fontSize: 16,
                                    color: _isValid
                                        ? Colors.white
                                        : AppColors.disabledText,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.spacing32),
            ],
          ),
        ),
      ),
    );
  }
}
