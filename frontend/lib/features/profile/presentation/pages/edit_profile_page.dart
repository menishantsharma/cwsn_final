import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/features/profile/presentation/providers/profile_provider.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _streetAddressController;
  late TextEditingController _landmarkController;
  late TextEditingController _postalCodeController;
  late TextEditingController _aboutMeController;
  late TextEditingController _qualificationsController;

  String? _selectedGender;
  bool _initialized = false;

  final List<String> _genderOptions = ['Male', 'Female', 'Other'];

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _streetAddressController.dispose();
    _landmarkController.dispose();
    _postalCodeController.dispose();
    _aboutMeController.dispose();
    _qualificationsController.dispose();
    super.dispose();
  }

  void _initialize(ProfileState profile) {
    if (_initialized) return;
    _initialized = true;

    final cwsn = profile.cwsnProfile!;
    final caregiver = profile.caregiverProfile!;

    _nameController = TextEditingController(text: cwsn.name);
    _ageController = TextEditingController(text: cwsn.age.toString());
    _streetAddressController = TextEditingController(text: cwsn.streetAddress);
    _landmarkController = TextEditingController(text: cwsn.landmark);
    _postalCodeController = TextEditingController(text: cwsn.postalCode);
    _aboutMeController = TextEditingController(text: caregiver.aboutMe);
    _qualificationsController = TextEditingController(
      text: caregiver.qualifications,
    );
    _selectedGender = cwsn.gender;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final cwsnData = {
      'name': _nameController.text.trim(),
      'age': int.parse(_ageController.text.trim()),
      'gender': _selectedGender,
      'street_address': _streetAddressController.text.trim(),
      'landmark': _landmarkController.text.trim(),
      'postal_code': _postalCodeController.text.trim(),
    };

    final caregiverData = {
      'name': _nameController.text.trim(),
      'age': int.parse(_ageController.text.trim()),
      'gender': _selectedGender,
      'about_me': _aboutMeController.text.trim(),
      'qualifications': _qualificationsController.text.trim(),
    };

    await Future.wait([
      ref.read(profileProvider.notifier).updateCwsnProfile(cwsnData),
      ref.read(profileProvider.notifier).updateCaregiverProfile(caregiverData),
    ]);

    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);

    return profileAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (profile) {
        _initialize(profile);
        return Scaffold(
          appBar: AppBar(title: const Text('Edit Profile')),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _SectionTitle('Personal Info'),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Name is required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _ageController,
                  decoration: const InputDecoration(
                    labelText: 'Age',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Age is required';
                    if (int.tryParse(v.trim()) == null)
                      return 'Enter a valid age';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedGender,
                  decoration: const InputDecoration(
                    labelText: 'Gender',
                    border: OutlineInputBorder(),
                  ),
                  items: _genderOptions
                      .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedGender = v),
                  validator: (v) => v == null ? 'Gender is required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _streetAddressController,
                  decoration: const InputDecoration(
                    labelText: 'Street Address',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _landmarkController,
                  decoration: const InputDecoration(
                    labelText: 'Landmark',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _postalCodeController,
                  decoration: const InputDecoration(
                    labelText: 'Postal Code',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 24),
                _SectionTitle('Caregiver Info'),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _aboutMeController,
                  decoration: const InputDecoration(
                    labelText: 'About Me',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _qualificationsController,
                  decoration: const InputDecoration(
                    labelText: 'Qualifications',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _save,
                  child: const Text('Save Changes'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
    );
  }
}
