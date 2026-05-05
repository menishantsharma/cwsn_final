import 'dart:async';

import 'package:flutter/material.dart';
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
  bool _resending = false;

  static const _timerDuration = 30;
  int _secondsLeft = _timerDuration;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _secondsLeft = _timerDuration);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft == 0) {
        t.cancel();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pinController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _resend(String phoneNumber) async {
    setState(() {
      _resending = true;
      _errorText = null;
      _pinController.clear();
    });
    await ref.read(authProvider.notifier).sendOtp(phoneNumber);
    if (mounted) {
      setState(() => _resending = false);
      _startTimer();
      _focusNode.requestFocus();
    }
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
        },
      );
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacing20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: AppDimensions.spacing8),
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                  color: AppColors.textPrimary,
                  onPressed: () => Navigator.of(context).pop(),
                  padding: EdgeInsets.zero,
                ),
              ),

              const Spacer(flex: 2),

              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_open_rounded,
                  color: AppColors.primary,
                  size: 28,
                ),
              ),

              const SizedBox(height: AppDimensions.spacing20),

              Text('Verify your number', style: AppTextStyles.titleLarge),

              const SizedBox(height: AppDimensions.spacing8),

              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: AppTextStyles.bodyMedium,
                  children: [
                    const TextSpan(text: 'Code sent to '),
                    TextSpan(
                      text: phoneNumber,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 2),

              OtpPinInput(
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

              if (_errorText != null) ...[
                const SizedBox(height: AppDimensions.spacing8),
                Text(
                  _errorText!,
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
                ),
              ],

              const SizedBox(height: AppDimensions.spacing32),

              if (isLoading)
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                )
              else if (_resending)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                )
              else if (_secondsLeft > 0)
                RichText(
                  text: TextSpan(
                    style: AppTextStyles.bodySmall,
                    children: [
                      const TextSpan(text: "Resend OTP in "),
                      TextSpan(
                        text: '0:${_secondsLeft.toString().padLeft(2, '0')}',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )
              else
                GestureDetector(
                  onTap: () => _resend(phoneNumber),
                  child: RichText(
                    text: TextSpan(
                      style: AppTextStyles.bodySmall,
                      children: [
                        const TextSpan(text: "Didn't receive it? "),
                        TextSpan(
                          text: 'Resend OTP',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }
}
