import 'package:flutter/material.dart';
import 'package:frontend/core/widgets/app_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/theme/app_dimensions.dart';
import 'package:frontend/core/theme/app_text_styles.dart';
import 'package:frontend/features/profile/presentation/controllers/profile_controller.dart';
import 'package:frontend/features/profile/presentation/widgets/edit_form_widgets.dart';

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
  Set<int> _selectedLanguageIds = {};

  @override
  void dispose() {
    _aboutMeController.dispose();
    _qualificationsController.dispose();
    super.dispose();
  }

  void _initialize(ProfileState profile, List<LanguageOption> allLanguages) {
    if (_initialized) return;
    _initialized = true;
    final caregiver = profile.caregiverProfile!;
    _aboutMeController = TextEditingController(text: caregiver.aboutMe);
    _qualificationsController = TextEditingController(text: caregiver.qualifications);
    // Pre-select languages that are currently on the profile
    final currentNames = caregiver.languages.map((l) => l.toLowerCase()).toSet();
    _selectedLanguageIds = allLanguages
        .where((l) => currentNames.contains(l.name.toLowerCase()))
        .map((l) => l.id)
        .toSet();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    await ref.read(profileProvider.notifier).updateCaregiverProfile({
      'about_me': _aboutMeController.text.trim(),
      'qualifications': _qualificationsController.text.trim(),
      'language_ids': _selectedLanguageIds.toList(),
    });
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);
    final languagesAsync = ref.watch(supportedLanguagesProvider);

    return profileAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      ),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (profile) => languagesAsync.when(
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
        ),
        error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
        data: (allLanguages) {
          _initialize(profile, allLanguages);
          return Scaffold(
            appBar: const AppTopBar(title: 'Caregiver Info'),
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
                  _LanguagePicker(
                    allLanguages: allLanguages,
                    selectedIds: _selectedLanguageIds,
                    onToggle: (id) => setState(() {
                      if (_selectedLanguageIds.contains(id)) {
                        _selectedLanguageIds.remove(id);
                      } else {
                        _selectedLanguageIds.add(id);
                      }
                    }),
                  ),
                  const SizedBox(height: AppDimensions.spacing32),
                  SaveButton(saving: _saving, onTap: _save),
                  const SizedBox(height: AppDimensions.spacing40),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _LanguagePicker extends StatelessWidget {
  final List<LanguageOption> allLanguages;
  final Set<int> selectedIds;
  final ValueChanged<int> onToggle;

  const _LanguagePicker({
    required this.allLanguages,
    required this.selectedIds,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Languages',
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: AppDimensions.spacing6),
          Wrap(
            spacing: AppDimensions.spacing8,
            runSpacing: AppDimensions.spacing8,
            children: allLanguages.map((lang) {
              final isSelected = selectedIds.contains(lang.id);
              return GestureDetector(
                onTap: () => onToggle(lang.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.spacing16,
                    vertical: AppDimensions.spacing8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.border,
                    ),
                  ),
                  child: Text(
                    lang.name,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
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
