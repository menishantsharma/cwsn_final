import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/theme/app_dimensions.dart';
import 'package:frontend/core/theme/app_text_styles.dart';
import 'package:frontend/features/profile/domain/profile_models.dart';
import 'package:frontend/features/profile/presentation/widgets/edit_form_widgets.dart';

class AddChildSheet extends StatefulWidget {
  final Future<void> Function(Map<String, dynamic>) onSave;
  final ChildProfileModel? initial;

  const AddChildSheet({super.key, required this.onSave, this.initial});

  @override
  State<AddChildSheet> createState() => _AddChildSheetState();
}

class _AddChildSheetState extends State<AddChildSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _ageController;
  late String _gender;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initial?.name ?? '');
    _ageController = TextEditingController(
      text: widget.initial != null ? widget.initial!.age.toString() : '',
    );
    _gender = widget.initial?.gender ?? 'Male';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await widget.onSave({
        'name': _nameController.text.trim(),
        'age': int.parse(_ageController.text.trim()),
        'gender': _gender,
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Could not save child. Please try again.')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initial != null;

    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: AppDimensions.spacing20,
          right: AppDimensions.spacing20,
          top: AppDimensions.spacing20,
          bottom: keyboardHeight + AppDimensions.spacing32,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppDimensions.spacing20),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                  ),
                ),
              ),
              Text(
                isEdit ? 'Edit Child' : 'Add Child',
                style: AppTextStyles.titleMedium,
              ),
              const SizedBox(height: AppDimensions.spacing24),
              LabeledField(
                label: 'Name',
                child: TextFormField(
                  controller: _nameController,
                  decoration: inputDecoration("Child's full name"),
                  textCapitalization: TextCapitalization.words,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
              ),
              LabeledField(
                label: 'Age',
                child: TextFormField(
                  controller: _ageController,
                  decoration: inputDecoration('e.g. 7'),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    final age = int.tryParse(v.trim());
                    if (age == null || age < 1 || age > 18) return 'Enter a valid age (1–18)';
                    return null;
                  },
                ),
              ),
              _GenderField(
                selected: _gender,
                onChanged: (g) => setState(() => _gender = g),
              ),
              const SizedBox(height: AppDimensions.spacing20),
              SaveButton(
                saving: _loading,
                onTap: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GenderField extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  static const _options = ['Male', 'Female', 'Other'];

  const _GenderField({required this.selected, required this.onChanged});

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
                      padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacing12),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                      ),
                      child: Center(
                        child: Text(
                          g,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: isSelected ? Colors.white : AppColors.textSecondary,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
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
