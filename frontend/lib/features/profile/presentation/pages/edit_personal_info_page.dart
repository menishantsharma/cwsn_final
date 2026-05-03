import 'package:flutter/material.dart';
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

  String? _selectedGender;
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
    _selectedGender = cwsn.gender;
    // Pre-populate location from existing profile data
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
          appBar: AppBar(
            backgroundColor: AppColors.background,
            elevation: 0,
            scrolledUnderElevation: 0,
            title: Text('Personal Info', style: AppTextStyles.titleMedium),
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(AppDimensions.spacing20),
              children: [
                const SizedBox(height: AppDimensions.spacing8),
                LabeledField(
                  label: 'Name',
                  child: TextFormField(
                    controller: _nameController,
                    decoration: inputDecoration('Your full name'),
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
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      if (int.tryParse(v.trim()) == null) return 'Enter a valid age';
                      return null;
                    },
                  ),
                ),
                LabeledField(
                  label: 'Gender',
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedGender,
                    decoration: inputDecoration('Select'),
                    items: ['Male', 'Female', 'Other']
                        .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedGender = v),
                    validator: (v) => v == null ? 'Required' : null,
                  ),
                ),
                LabeledField(
                  label: 'Your Area',
                  child: InkWell(
                    onTap: _openMapPicker,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _location == null
                              ? AppColors.border
                              : AppColors.primary,
                          width: _location == null ? 1 : 1.5,
                        ),
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusMd),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _location == null
                                ? Icons.map_outlined
                                : Icons.location_on,
                            color: _location == null
                                ? AppColors.textHint
                                : AppColors.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _location?.displayLocation ??
                                  'Tap to pick on map',
                              style: TextStyle(
                                color: _location == null
                                    ? AppColors.textHint
                                    : AppColors.textPrimary,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            color: AppColors.textHint,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppDimensions.spacing32),
                SaveButton(saving: _saving, onTap: _save),
                const SizedBox(height: AppDimensions.spacing40),
              ],
            ),
          ),
        );
      },
    );
  }
}
