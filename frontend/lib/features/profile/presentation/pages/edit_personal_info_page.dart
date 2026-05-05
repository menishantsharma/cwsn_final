import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/core/widgets/app_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/theme/app_dimensions.dart';
import 'package:frontend/core/theme/app_text_styles.dart';
import 'package:frontend/features/auth/presentation/pages/map_picker_page.dart';
import 'package:frontend/features/profile/presentation/widgets/edit_form_widgets.dart';
import 'package:frontend/features/profile/presentation/providers/profile_provider.dart';

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
  late TextEditingController _phoneController;

  String? _selectedGender;
  LocationPickerResult? _location;
  bool _initialized = false;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _initialize(ProfileState profile) {
    if (_initialized) return;
    _initialized = true;
    final cwsn = profile.cwsnProfile!;
    _nameController = TextEditingController(text: cwsn.name);
    _ageController = TextEditingController(text: cwsn.age.toString());
    _phoneController = TextEditingController(text: cwsn.phoneNumber);
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    await ref.read(profileProvider.notifier).updateCwsnProfile({
      'name': _nameController.text.trim(),
      'age': int.parse(_ageController.text.trim()),
      'gender': _selectedGender,
      'phone_number': _phoneController.text.trim(),
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
                LabeledField(
                  label: 'Phone Number',
                  child: TextFormField(
                    controller: _phoneController,
                    decoration: inputDecoration('e.g. +91 98765 43210'),
                    keyboardType: TextInputType.phone,
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+\- ]'))],
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
