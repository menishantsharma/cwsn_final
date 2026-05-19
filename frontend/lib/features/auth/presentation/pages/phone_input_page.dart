import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/features/legal/presentation/pages/legal_page.dart';
import 'package:frontend/core/theme/app_dimensions.dart';
import 'package:frontend/core/theme/app_text_styles.dart';
import 'package:frontend/features/auth/presentation/controllers/auth_controller.dart';
import 'package:frontend/features/auth/presentation/widgets/otp_pin_input.dart';
import 'package:frontend/features/auth/presentation/widgets/phone_input_field.dart';
import 'package:frontend/features/auth/presentation/widgets/send_otp_button.dart';

class PhoneInputPage extends ConsumerStatefulWidget {
  const PhoneInputPage({super.key});

  @override
  ConsumerState<PhoneInputPage> createState() => _PhoneInputPageState();
}

class _PhoneInputPageState extends ConsumerState<PhoneInputPage> {
  final _phoneController = TextEditingController();
  bool get _isValid => _phoneController.text.length == 10;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!_isValid) return;
    final phone = '+91${_phoneController.text}';
    try {
      await ref.read(authProvider.notifier).sendOtp(phone);
      if (!mounted) return;
      _showOtpSheet(phone);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Could not send OTP. Please try again.'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusMd)),
        margin: const EdgeInsets.all(AppDimensions.spacing16),
      ));
    }
  }

  void _showLegal(BuildContext context, LegalMode mode) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: Scaffold(
            body: LegalPage(mode: mode, scrollController: controller),
          ),
        ),
      ),
    );
  }

  void _showOtpSheet(String phone) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _OtpSheet(phone: phone),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authProvider.select((s) => s.isLoading));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacing20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Spacer(flex: 2),

                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.favorite_rounded, color: AppColors.primary, size: 30),
                ),

                const SizedBox(height: AppDimensions.spacing24),

                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: AppTextStyles.displayMedium.copyWith(fontWeight: FontWeight.w700, fontSize: 28),
                    children: const [
                      TextSpan(text: 'Care', style: TextStyle(color: AppColors.primary)),
                      TextSpan(text: ' starts with\nconnection.', style: TextStyle(color: AppColors.textPrimary)),
                    ],
                  ),
                ),

                const SizedBox(height: AppDimensions.spacing12),

                Text(
                  'Enter your phone number to get started',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint),
                ),

                const Spacer(flex: 2),

                PhoneInputField(
                  controller: _phoneController,
                  onSubmitted: _sendOtp,
                  onChanged: () => setState(() {}),
                ),

                const SizedBox(height: AppDimensions.spacing12),

                SendOtpButton(isValid: _isValid, isLoading: isLoading, onTap: _sendOtp),

                const SizedBox(height: AppDimensions.spacing16),

                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.textHint, fontSize: 11, height: 1.5),
                    children: [
                      const TextSpan(text: 'By continuing, you agree to our '),
                      TextSpan(
                        text: 'Terms of Service',
                        style: AppTextStyles.bodySmall.copyWith(
                          fontSize: 11,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () => _showLegal(context, LegalMode.terms),
                      ),
                      const TextSpan(text: ' and '),
                      TextSpan(
                        text: 'Privacy Policy',
                        style: AppTextStyles.bodySmall.copyWith(
                          fontSize: 11,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () => _showLegal(context, LegalMode.privacy),
                      ),
                    ],
                  ),
                ),

                const Spacer(flex: 1),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OtpSheet extends ConsumerStatefulWidget {
  final String phone;
  const _OtpSheet({required this.phone});

  @override
  ConsumerState<_OtpSheet> createState() => _OtpSheetState();
}

class _OtpSheetState extends ConsumerState<_OtpSheet> {
  final _pinController = TextEditingController();
  final _focusNode = FocusNode();
  String? _errorText;
  bool _resending = false;

  static const _timerDuration = 30;
  int _secondsLeft = _timerDuration;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pinController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _secondsLeft = _timerDuration);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft == 0) {
        t.cancel();
      } else {
        if (mounted) setState(() => _secondsLeft--);
      }
    });
  }

  Future<void> _resend() async {
    setState(() { _resending = true; _errorText = null; _pinController.clear(); });
    try {
      await ref.read(authProvider.notifier).sendOtp(widget.phone);
    } catch (_) {
      // Silently ignore — user can tap resend again.
    }
    if (mounted) {
      setState(() => _resending = false);
      _startTimer();
      _focusNode.requestFocus();
    }
  }

  Future<void> _verify(String code) async {
    try {
      await ref.read(authProvider.notifier).verifyOtp(code);
      // On success the router redirect handles navigation automatically.
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().contains('network')
          ? 'Network error. Check your connection.'
          : e.toString().contains('invalid-verification-code') || e.toString().contains('invalid-verification-id')
              ? 'Invalid code. Please try again.'
              : 'Verification failed. Please try again.';
      setState(() => _errorText = msg);
      _pinController.clear();
      _focusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authProvider.select((s) => s.isLoading));
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        AppDimensions.spacing24,
        AppDimensions.spacing16,
        AppDimensions.spacing24,
        AppDimensions.spacing32 + bottomInset,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          const SizedBox(height: AppDimensions.spacing24),

          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lock_open_rounded, color: AppColors.primary, size: 26),
          ),

          const SizedBox(height: AppDimensions.spacing16),

          Text('Verify your number', style: AppTextStyles.titleLarge),

          const SizedBox(height: AppDimensions.spacing8),

          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: AppTextStyles.bodyMedium,
              children: [
                const TextSpan(text: 'Code sent to '),
                TextSpan(
                  text: widget.phone,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppDimensions.spacing32),

          OtpPinInput(
            controller: _pinController,
            focusNode: _focusNode,
            enabled: !isLoading,
            hasError: _errorText != null,
            onChanged: (val) { if (_errorText != null) setState(() => _errorText = null); },
            onCompleted: _verify,
          ),

          if (_errorText != null) ...[
            const SizedBox(height: AppDimensions.spacing8),
            Text(_errorText!, style: AppTextStyles.bodySmall.copyWith(color: AppColors.error)),
          ],

          const SizedBox(height: AppDimensions.spacing24),

          if (isLoading)
            const SizedBox(
              width: 22, height: 22,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
            )
          else if (_resending)
            const SizedBox(
              width: 18, height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
            )
          else if (_secondsLeft > 0)
            RichText(
              text: TextSpan(
                style: AppTextStyles.bodySmall,
                children: [
                  const TextSpan(text: 'Resend OTP in '),
                  TextSpan(
                    text: '0:${_secondsLeft.toString().padLeft(2, '0')}',
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            )
          else
            GestureDetector(
              onTap: _resend,
              child: RichText(
                text: TextSpan(
                  style: AppTextStyles.bodySmall,
                  children: [
                    const TextSpan(text: "Didn't receive it? "),
                    TextSpan(
                      text: 'Resend OTP',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
