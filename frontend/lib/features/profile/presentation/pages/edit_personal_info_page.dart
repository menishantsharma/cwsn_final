import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/core/widgets/app_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/errors/app_exception.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/theme/app_dimensions.dart';
import 'package:frontend/core/theme/app_text_styles.dart';
import 'package:frontend/features/auth/presentation/pages/map_picker_page.dart';
import 'package:frontend/features/auth/presentation/widgets/otp_pin_input.dart';
import 'package:frontend/features/profile/data/profile_repository.dart';
import 'package:frontend/features/profile/presentation/widgets/edit_form_widgets.dart';
import 'package:frontend/features/profile/presentation/controllers/profile_controller.dart';

class EditPersonalInfoPage extends ConsumerStatefulWidget {
  const EditPersonalInfoPage({super.key});

  @override
  ConsumerState<EditPersonalInfoPage> createState() =>
      _EditPersonalInfoPageState();
}

class _EditPersonalInfoPageState extends ConsumerState<EditPersonalInfoPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _ageController;

  String? _selectedGender;
  String _currentPhone = '';
  LocationPickerResult? _location;
  bool _initialized = false;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  void _initialize(ProfileState profile) {
    if (_initialized) return;
    _initialized = true;
    final cwsn = profile.cwsnProfile!;
    _nameController = TextEditingController(text: cwsn.name);
    _ageController = TextEditingController(text: cwsn.age.toString());
    _currentPhone = cwsn.phoneNumber;
    _selectedGender = cwsn.gender;
    if (cwsn.streetAddress.isNotEmpty) {
      _location = LocationPickerResult(
        address: cwsn.streetAddress,
        subLocality: '',
        city: '',
        state: '',
        latitude: cwsn.latitude ?? 0,
        longitude: cwsn.longitude ?? 0,
      );
    }
  }

  Future<void> _openMapPicker() async {
    final result = await Navigator.of(context).push<LocationPickerResult>(
      MaterialPageRoute(
        builder: (_) => MapPickerPage(
          initialLat: _location?.latitude,
          initialLng: _location?.longitude,
        ),
      ),
    );
    if (result != null) setState(() => _location = result);
  }

  Future<void> _openChangePhoneSheet() async {
    final source = ref.read(profileRepositoryProvider);
    final newPhone = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ChangePhoneSheet(source: source),
    );
    if (newPhone != null && mounted) {
      setState(() => _currentPhone = newPhone);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Phone number updated successfully.'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
          margin: const EdgeInsets.all(AppDimensions.spacing16),
        ),
      );
      ref.invalidate(profileProvider);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    await ref.read(profileProvider.notifier).updateCwsnProfile({
      'name': _nameController.text.trim(),
      'age': int.parse(_ageController.text.trim()),
      'gender': _selectedGender,
      if (_location != null) ...{
        'street_address': _location!.displayLocation,
        'latitude': double.parse(_location!.latitude.toStringAsFixed(6)),
        'longitude': double.parse(_location!.longitude.toStringAsFixed(6)),
      },
    });
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);

    return profileAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      ),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (profile) {
        _initialize(profile);
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: const AppTopBar(title: 'Personal Info'),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.spacing20,
                AppDimensions.spacing24,
                AppDimensions.spacing20,
                AppDimensions.spacing40,
              ),
              children: [
                LabeledField(
                  label: 'Full Name',
                  child: TextFormField(
                    controller: _nameController,
                    decoration: inputDecoration('Your full name'),
                    textCapitalization: TextCapitalization.words,
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                ),
                LabeledField(
                  label: 'Age',
                  child: TextFormField(
                    controller: _ageController,
                    decoration: inputDecoration('e.g. 28'),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      final age = int.tryParse(v.trim());
                      if (age == null || age < 1 || age > 120) return 'Enter a valid age';
                      return null;
                    },
                  ),
                ),
                LabeledField(
                  label: 'Gender',
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedGender,
                    decoration: inputDecoration('Select gender'),
                    items: ['Male', 'Female', 'Other']
                        .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedGender = v),
                    validator: (v) => v == null ? 'Required' : null,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: AppDimensions.spacing20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Phone Number',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spacing8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.spacing16,
                          vertical: AppDimensions.spacing16,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.phone_rounded,
                              size: 18,
                              color: AppColors.textHint,
                            ),
                            const SizedBox(width: AppDimensions.spacing12),
                            Expanded(
                              child: Text(
                                _currentPhone.isNotEmpty ? _currentPhone : '—',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: _openChangePhoneSheet,
                              child: Text(
                                'Change',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                LabeledField(
                  label: 'Your Area',
                  child: _LocationPickerField(
                    location: _location,
                    onTap: _openMapPicker,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacing12),
                SaveButton(saving: _saving, onTap: _save),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Change Phone Bottom Sheet
// ---------------------------------------------------------------------------

enum _PhoneChangeStep { enterPhone, enterOtp }

class _ChangePhoneSheet extends StatefulWidget {
  final ProfileRepository source;
  const _ChangePhoneSheet({required this.source});

  @override
  State<_ChangePhoneSheet> createState() => _ChangePhoneSheetState();
}

class _ChangePhoneSheetState extends State<_ChangePhoneSheet> {
  final _phoneController = TextEditingController();
  final _pinController = TextEditingController();
  final _pinFocusNode = FocusNode();

  _PhoneChangeStep _step = _PhoneChangeStep.enterPhone;
  bool _loading = false;
  String? _errorText;
  String _newPhone = '';

  static const _timerDuration = 30;
  int _secondsLeft = 0;
  Timer? _timer;

  bool get _phoneValid => _phoneController.text.trim().length == 10;

  @override
  void dispose() {
    _phoneController.dispose();
    _pinController.dispose();
    _pinFocusNode.dispose();
    _timer?.cancel();
    super.dispose();
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

  Future<void> _sendOtp() async {
    setState(() {
      _loading = true;
      _errorText = null;
    });
    _newPhone = '+91${_phoneController.text.trim()}';
    try {
      debugPrint('[ChangePhone] sending OTP to $_newPhone');
      await widget.source.changePhoneRequest(_newPhone);
      debugPrint('[ChangePhone] OTP sent, mounted=$mounted');
      if (mounted) {
        setState(() {
          _step = _PhoneChangeStep.enterOtp;
          _loading = false;
        });
        debugPrint('[ChangePhone] step set to enterOtp');
        _startTimer();
        _pinFocusNode.requestFocus();
      }
    } catch (e, st) {
      debugPrint('[ChangePhone] _sendOtp error: $e\n$st');
      if (mounted) setState(() { _loading = false; _errorText = _parseError(e); });
    }
  }

  Future<void> _resendOtp() async {
    setState(() {
      _loading = true;
      _errorText = null;
      _pinController.clear();
    });
    try {
      await widget.source.changePhoneRequest(_newPhone);
      if (mounted) {
        setState(() => _loading = false);
        _startTimer();
        _pinFocusNode.requestFocus();
      }
    } catch (e) {
      if (mounted) setState(() { _loading = false; _errorText = _parseError(e); });
    }
  }

  Future<void> _confirmOtp(String code) async {
    setState(() { _loading = true; _errorText = null; });
    try {
      await widget.source.changePhoneConfirm(_newPhone, code);
      if (mounted) Navigator.of(context).pop(_newPhone);
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _errorText = 'Invalid code. Please try again.';
          _pinController.clear();
        });
        _pinFocusNode.requestFocus();
      }
    }
  }

  String _parseError(Object e) {
    final String msg;
    if (e is DioException && e.error is AppException) {
      msg = (e.error as AppException).message;
    } else {
      msg = e.toString();
    }
    final lower = msg.toLowerCase();
    if (lower.contains('already in use')) return 'This number is already registered.';
    if (lower.contains('timeout')) return 'Request timed out. Please try again.';
    return 'Something went wrong. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(
          AppDimensions.spacing20,
          AppDimensions.spacing24,
          AppDimensions.spacing20,
          AppDimensions.spacing24,
        ),
        child: SingleChildScrollView(
          child: _step == _PhoneChangeStep.enterPhone
              ? _buildEnterPhone()
              : _buildEnterOtp(),
        ),
      ),
    );
  }

  Widget _buildEnterPhone() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Change Phone Number', style: AppTextStyles.titleMedium),
        const SizedBox(height: AppDimensions.spacing4),
        Text(
          'Enter your new 10-digit mobile number.',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppDimensions.spacing20),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacing16),
                child: Text('+91', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
              ),
              Container(width: 1, height: 24, color: AppColors.border),
              Expanded(
                child: TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
                  onChanged: (_) => setState(() {}),
                  style: AppTextStyles.bodyMedium,
                  decoration: InputDecoration(
                    hintText: 'New phone number',
                    hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacing16, vertical: AppDimensions.spacing16),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_errorText != null) ...[
          const SizedBox(height: AppDimensions.spacing8),
          Text(_errorText!, style: AppTextStyles.bodySmall.copyWith(color: AppColors.error)),
        ],
        const SizedBox(height: AppDimensions.spacing20),
        SaveButton(
          saving: _loading,
          onTap: _sendOtp,
          label: 'Send OTP',
          enabled: _phoneValid,
        ),
      ],
    );
  }

  Widget _buildEnterOtp() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text('Verify new number', style: AppTextStyles.titleMedium),
        ),
        const SizedBox(height: AppDimensions.spacing4),
        Align(
          alignment: Alignment.centerLeft,
          child: RichText(
            text: TextSpan(
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
              children: [
                const TextSpan(text: 'Code sent to '),
                TextSpan(
                  text: _newPhone,
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppDimensions.spacing24),
        OtpPinInput(
          controller: _pinController,
          focusNode: _pinFocusNode,
          enabled: !_loading,
          hasError: _errorText != null,
          onChanged: (v) { if (_errorText != null) setState(() => _errorText = null); },
          onCompleted: _confirmOtp,
        ),
        if (_errorText != null) ...[
          const SizedBox(height: AppDimensions.spacing8),
          Text(_errorText!, style: AppTextStyles.bodySmall.copyWith(color: AppColors.error)),
        ],
        const SizedBox(height: AppDimensions.spacing20),
        if (_loading)
          const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
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
            onTap: _resendOtp,
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
    );
  }
}

// ---------------------------------------------------------------------------
// Location picker field
// ---------------------------------------------------------------------------

class _LocationPickerField extends StatelessWidget {
  final LocationPickerResult? location;
  final VoidCallback onTap;

  const _LocationPickerField({required this.location, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasLocation = location != null;

    return Material(
      color: AppColors.surfaceVariant,
      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacing16,
            vertical: AppDimensions.spacing16,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            border: hasLocation
                ? Border.all(color: AppColors.primary, width: 1.5)
                : null,
          ),
          child: Row(
            children: [
              Icon(
                hasLocation ? Icons.location_on_rounded : Icons.map_outlined,
                color: hasLocation ? AppColors.primary : AppColors.textHint,
                size: 20,
              ),
              const SizedBox(width: AppDimensions.spacing12),
              Expanded(
                child: Text(
                  location?.displayLocation ?? 'Tap to pick on map',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: hasLocation ? AppColors.textPrimary : AppColors.textHint,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppDimensions.spacing8),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textHint,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
