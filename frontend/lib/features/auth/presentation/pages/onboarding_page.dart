import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/theme/app_dimensions.dart';
import 'package:frontend/core/theme/app_text_styles.dart';
import 'package:frontend/features/auth/presentation/pages/map_picker_page.dart';
import 'package:frontend/features/auth/presentation/controllers/auth_controller.dart';
import 'package:frontend/features/auth/presentation/widgets/location_picker_field.dart';
import 'package:frontend/features/profile/data/profile_repository.dart';
import 'package:frontend/features/profile/presentation/widgets/edit_form_widgets.dart';

final _onboardingProvider =
    AsyncNotifierProvider.autoDispose<_OnboardingNotifier, void>(
      _OnboardingNotifier.new,
    );

class _OnboardingNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> submit({
    required String name,
    required int age,
    required String gender,
    required String streetAddress,
    required double latitude,
    required double longitude,
  }) async {
    final source = ref.read(profileRepositoryProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final cwsn = await source.getCwsnProfile();
      final caregiver = await source.getCaregiverProfile();

      final data = <String, dynamic>{
        'name': name,
        'age': age,
        'gender': gender,
        'street_address': streetAddress,
        'latitude': double.parse(latitude.toStringAsFixed(6)),
        'longitude': double.parse(longitude.toStringAsFixed(6)),
      };

      await Future.wait<Object>([
        source.updateCwsnProfile(cwsn.id, data),
        source.updateCaregiverProfile(caregiver.id, data),
      ]);
    });
  }
}

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  String _gender = 'Male';
  LocationPickerResult? _location;

  void _onTextChanged() => setState(() {});

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_location == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please pick your area on the map.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
          margin: const EdgeInsets.all(AppDimensions.spacing16),
        ),
      );
      return;
    }

    await ref.read(_onboardingProvider.notifier).submit(
      name: _nameController.text.trim(),
      age: int.parse(_ageController.text.trim()),
      gender: _gender,
      streetAddress: _location!.displayLocation,
      latitude: _location!.latitude,
      longitude: _location!.longitude,
    );

    if (!mounted) return;
    ref.read(_onboardingProvider).when(
      data: (_) async {
        try {
          await ref.read(authProvider.notifier).completeOnboarding();
        } catch (_) {
          if (!mounted) return;
          _showError("Couldn't finish setup. Please try again.");
        }
      },
      error: (_, _) => _showError('Something went wrong. Please try again.'),
      loading: () {},
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        ),
        margin: const EdgeInsets.all(AppDimensions.spacing16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(_onboardingProvider).isLoading;
    final canSubmit = _nameController.text.trim().isNotEmpty &&
        _ageController.text.trim().isNotEmpty &&
        _location != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.spacing20,
                AppDimensions.spacing32,
                AppDimensions.spacing20,
                AppDimensions.spacing40,
              ),
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.waving_hand_rounded,
                    color: AppColors.primary,
                    size: 26,
                  ),
                ),

                const SizedBox(height: AppDimensions.spacing20),

                Text('Welcome!', style: AppTextStyles.displaySmall),

                const SizedBox(height: AppDimensions.spacing8),

                Text(
                  'Tell us a bit about yourself to get started.',
                  style: AppTextStyles.bodyMedium,
                ),

                const SizedBox(height: AppDimensions.spacing32),

                LabeledField(
                  label: 'Full Name',
                  child: TextFormField(
                    controller: _nameController,
                    decoration: inputDecoration('Enter your full name'),
                    textCapitalization: TextCapitalization.words,
                    onChanged: (_) => _onTextChanged(),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                ),

                LabeledField(
                  label: 'Age',
                  child: TextFormField(
                    controller: _ageController,
                    decoration: inputDecoration('e.g. 28'),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (_) => _onTextChanged(),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      final n = int.tryParse(v.trim());
                      if (n == null || n < 1 || n > 120) return 'Enter a valid age';
                      return null;
                    },
                  ),
                ),

                _GenderSelector(
                  selected: _gender,
                  onChanged: (g) => setState(() => _gender = g),
                ),

                LabeledField(
                  label: 'Your Area',
                  child: LocationPickerField(
                    location: _location,
                    onTap: _openMapPicker,
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.only(
                    top: AppDimensions.spacing4,
                    bottom: AppDimensions.spacing32,
                  ),
                  child: Text(
                    'Move the pin to your neighbourhood — exact address not needed.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textHint,
                      fontSize: 11,
                    ),
                  ),
                ),

                SaveButton(
                  saving: isLoading,
                  onTap: _submit,
                  label: 'Get Started',
                  enabled: canSubmit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GenderSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  static const _options = ['Male', 'Female', 'Other'];

  const _GenderSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spacing20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Gender',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppDimensions.spacing8),
          Row(
            children: _options.map((g) {
              final isSelected = g == selected;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: g != _options.last ? AppDimensions.spacing8 : 0,
                  ),
                  child: GestureDetector(
                    onTap: () => onChanged(g),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                        vertical: AppDimensions.spacing12,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                      ),
                      child: Center(
                        child: Text(
                          g,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: isSelected
                                ? Colors.white
                                : AppColors.textSecondary,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
