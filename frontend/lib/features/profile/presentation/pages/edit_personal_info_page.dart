import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/theme/app_dimensions.dart';
import 'package:frontend/core/theme/app_text_styles.dart';
import 'package:frontend/features/profile/presentation/pages/edit_form_widgets.dart';
import 'package:frontend/features/profile/presentation/providers/profile_provider.dart';

class EditPersonalInfoPage extends ConsumerStatefulWidget {
  const EditPersonalInfoPage({super.key});

  @override
  ConsumerState<EditPersonalInfoPage> createState() => _EditPersonalInfoPageState();
}

class _EditPersonalInfoPageState extends ConsumerState<EditPersonalInfoPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _streetAddressController;
  late TextEditingController _landmarkController;
  late TextEditingController _postalCodeController;

  String? _selectedGender;
  bool _initialized = false;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _streetAddressController.dispose();
    _landmarkController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }

  void _initialize(ProfileState profile) {
    if (_initialized) return;
    _initialized = true;
    final cwsn = profile.cwsnProfile!;
    _nameController = TextEditingController(text: cwsn.name);
    _ageController = TextEditingController(text: cwsn.age.toString());
    _streetAddressController = TextEditingController(text: cwsn.streetAddress);
    _landmarkController = TextEditingController(text: cwsn.landmark);
    _postalCodeController = TextEditingController(text: cwsn.postalCode);
    _selectedGender = cwsn.gender;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    await ref.read(profileProvider.notifier).updateCwsnProfile({
      'name': _nameController.text.trim(),
      'age': int.parse(_ageController.text.trim()),
      'gender': _selectedGender,
      'street_address': _streetAddressController.text.trim(),
      'landmark': _landmarkController.text.trim(),
      'postal_code': _postalCodeController.text.trim(),
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
                LabeledField(label: 'Name', child: TextFormField(
                  controller: _nameController,
                  decoration: inputDecoration('Your full name'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                )),
                LabeledField(label: 'Age', child: TextFormField(
                  controller: _ageController,
                  decoration: inputDecoration('e.g. 28'),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    if (int.tryParse(v.trim()) == null) return 'Enter a valid age';
                    return null;
                  },
                )),
                LabeledField(label: 'Gender', child: DropdownButtonFormField<String>(
                  initialValue: _selectedGender,
                  decoration: inputDecoration('Select'),
                  items: ['Male', 'Female', 'Other']
                      .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedGender = v),
                  validator: (v) => v == null ? 'Required' : null,
                )),
                LabeledField(label: 'Street Address', child: TextFormField(
                  controller: _streetAddressController,
                  decoration: inputDecoration('House no, street name'),
                )),
                LabeledField(label: 'Landmark', child: TextFormField(
                  controller: _landmarkController,
                  decoration: inputDecoration('Nearby landmark'),
                )),
                LabeledField(label: 'Postal Code', child: TextFormField(
                  controller: _postalCodeController,
                  decoration: inputDecoration('6-digit code'),
                  keyboardType: TextInputType.number,
                )),
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
