import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/theme/app_dimensions.dart';
import 'package:frontend/core/theme/app_text_styles.dart';
import 'package:frontend/features/profile/domain/models/profile_model.dart';

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
            .showSnackBar(SnackBar(content: Text('Failed to save: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initial != null;
    return Padding(
      padding: EdgeInsets.only(
        left: AppDimensions.spacing20,
        right: AppDimensions.spacing20,
        top: AppDimensions.spacing24,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppDimensions.spacing24,
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
            Text(isEdit ? 'Edit Child' : 'Add Child', style: AppTextStyles.titleMedium),
            const SizedBox(height: AppDimensions.spacing24),
            _SheetField(
              label: 'Name',
              child: TextFormField(
                controller: _nameController,
                decoration: _sheetInputDecoration('Child\'s full name'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
            ),
            _SheetField(
              label: 'Age',
              child: TextFormField(
                controller: _ageController,
                decoration: _sheetInputDecoration('e.g. 7'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  if (int.tryParse(v.trim()) == null) return 'Must be a number';
                  return null;
                },
              ),
            ),
            _SheetField(
              label: 'Gender',
              child: DropdownButtonFormField<String>(
                initialValue: _gender,
                decoration: _sheetInputDecoration('Select'),
                items: ['Male', 'Female', 'Other']
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                onChanged: (v) => setState(() => _gender = v!),
              ),
            ),
            const SizedBox(height: AppDimensions.spacing8),
            SizedBox(
              height: AppDimensions.buttonHeight,
              child: Material(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                child: InkWell(
                  onTap: _loading ? null : _submit,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                  child: Center(
                    child: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            isEdit ? 'Update' : 'Save',
                            style: AppTextStyles.labelLarge.copyWith(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

InputDecoration _sheetInputDecoration(String hint) => InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint),
      filled: true,
      fillColor: AppColors.background,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacing16,
        vertical: AppDimensions.spacing12,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
    );

class _SheetField extends StatelessWidget {
  final String label;
  final Widget child;

  const _SheetField({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: AppDimensions.spacing6),
          child,
        ],
      ),
    );
  }
}
