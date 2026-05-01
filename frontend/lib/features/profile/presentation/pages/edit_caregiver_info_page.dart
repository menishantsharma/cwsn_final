import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/features/profile/presentation/providers/profile_provider.dart';

class EditCaregiverInfoPage extends ConsumerStatefulWidget {
  const EditCaregiverInfoPage({super.key});

  @override
  ConsumerState<EditCaregiverInfoPage> createState() =>
      _EditCaregiverInfoPageState();
}

class _EditCaregiverInfoPageState extends ConsumerState<EditCaregiverInfoPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _aboutMeController;
  late TextEditingController _qualificationsController;

  bool _initialized = false;
  bool _saving = false;

  @override
  void dispose() {
    _aboutMeController.dispose();
    _qualificationsController.dispose();
    super.dispose();
  }

  void _initialize(ProfileState profile) {
    if (_initialized) return;
    _initialized = true;

    final caregiver = profile.caregiverProfile!;
    _aboutMeController = TextEditingController(text: caregiver.aboutMe);
    _qualificationsController = TextEditingController(
      text: caregiver.qualifications,
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    await ref.read(profileProvider.notifier).updateCaregiverProfile({
      'about_me': _aboutMeController.text.trim(),
      'qualifications': _qualificationsController.text.trim(),
    });

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
          appBar: AppBar(title: const Text('Edit Caregiver Info')),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
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
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save Changes'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
