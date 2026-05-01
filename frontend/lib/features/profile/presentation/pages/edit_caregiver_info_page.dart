import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/theme/app_dimensions.dart';
import 'package:frontend/core/theme/app_text_styles.dart';
import 'package:frontend/features/profile/presentation/providers/profile_provider.dart';
import 'package:frontend/features/profile/presentation/pages/edit_form_widgets.dart';

class EditCaregiverInfoPage extends ConsumerStatefulWidget {
  const EditCaregiverInfoPage({super.key});

  @override
  ConsumerState<EditCaregiverInfoPage> createState() => _EditCaregiverInfoPageState();
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
    _qualificationsController = TextEditingController(text: caregiver.qualifications);
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
            title: Text('Caregiver Info', style: AppTextStyles.titleMedium),
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(AppDimensions.spacing20),
              children: [
                const SizedBox(height: AppDimensions.spacing8),
                LabeledField(label: 'About Me', child: TextFormField(
                  controller: _aboutMeController,
                  decoration: inputDecoration('Tell families about yourself'),
                  maxLines: 4,
                )),
                LabeledField(label: 'Qualifications', child: TextFormField(
                  controller: _qualificationsController,
                  decoration: inputDecoration('Your certifications, degrees, experience'),
                  maxLines: 4,
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
