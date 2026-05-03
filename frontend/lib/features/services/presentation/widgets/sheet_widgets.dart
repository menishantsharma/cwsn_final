import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/theme/app_dimensions.dart';
import 'package:frontend/core/theme/app_text_styles.dart';

/// Drag handle shown at the top of every bottom sheet.
class SheetHandle extends StatelessWidget {
  const SheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 36,
        height: 4,
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        ),
      ),
    );
  }
}

/// Primary action button used at the bottom of sheets.
class SheetSaveButton extends StatelessWidget {
  final VoidCallback onTap;
  final String label;

  const SheetSaveButton({super.key, required this.onTap, this.label = 'Save'});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: AppDimensions.buttonHeight,
      child: Material(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          child: Center(
            child: Text(
              label,
              style: AppTextStyles.labelLarge.copyWith(color: Colors.white, fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }
}

InputDecoration _sheetFieldDecoration({String? hint, String? label}) => InputDecoration(
      hintText: hint,
      labelText: label,
      hintStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.textHint),
      labelStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
      filled: true,
      fillColor: AppColors.background,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );

class TextSheet extends StatefulWidget {
  final String label;
  final String? value;
  final int maxLines;
  final void Function(String) onSave;

  const TextSheet({
    super.key,
    required this.label,
    required this.onSave,
    this.value,
    this.maxLines = 1,
  });

  @override
  State<TextSheet> createState() => _TextSheetState();
}

class _TextSheetState extends State<TextSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20, 12, 20,
        MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SheetHandle(),
          Text(widget.label, style: AppTextStyles.titleSmall),
          const SizedBox(height: AppDimensions.spacing12),
          TextField(
            controller: _controller,
            maxLines: widget.maxLines,
            autofocus: true,
            style: AppTextStyles.bodyLarge,
            decoration: _sheetFieldDecoration(),
          ),
          const SizedBox(height: AppDimensions.spacing20),
          SheetSaveButton(
            onTap: () {
              widget.onSave(_controller.text.trim());
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}

class ChipSheet extends StatefulWidget {
  final String label;
  final List<String> options;
  final String selected;
  final void Function(String) onSave;

  const ChipSheet({
    super.key,
    required this.label,
    required this.options,
    required this.selected,
    required this.onSave,
  });

  @override
  State<ChipSheet> createState() => _ChipSheetState();
}

class _ChipSheetState extends State<ChipSheet> {
  late String _current;

  @override
  void initState() {
    super.initState();
    _current = widget.selected;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SheetHandle(),
          Text(widget.label, style: AppTextStyles.titleSmall),
          const SizedBox(height: AppDimensions.spacing16),
          Wrap(
            spacing: AppDimensions.spacing8,
            runSpacing: AppDimensions.spacing8,
            children: widget.options.map((opt) {
              final isSelected = opt == _current;
              return GestureDetector(
                onTap: () => setState(() => _current = opt),
                child: Container(
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
                    opt,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppDimensions.spacing24),
          SheetSaveButton(
            onTap: () {
              widget.onSave(_current);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}

class AgeSheet extends StatefulWidget {
  final int? minAge;
  final int? maxAge;
  final void Function(int?, int?) onSave;

  const AgeSheet({super.key, required this.onSave, this.minAge, this.maxAge});

  @override
  State<AgeSheet> createState() => _AgeSheetState();
}

class _AgeSheetState extends State<AgeSheet> {
  late final TextEditingController _minController;
  late final TextEditingController _maxController;

  @override
  void initState() {
    super.initState();
    _minController = TextEditingController(text: widget.minAge?.toString() ?? '');
    _maxController = TextEditingController(text: widget.maxAge?.toString() ?? '');
  }

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20, 12, 20,
        MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SheetHandle(),
          Text('Target Age Range', style: AppTextStyles.titleSmall),
          const SizedBox(height: AppDimensions.spacing16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _minController,
                  keyboardType: TextInputType.number,
                  style: AppTextStyles.bodyLarge,
                  decoration: _sheetFieldDecoration(label: 'Min age'),
                ),
              ),
              const SizedBox(width: AppDimensions.spacing12),
              Expanded(
                child: TextField(
                  controller: _maxController,
                  keyboardType: TextInputType.number,
                  style: AppTextStyles.bodyLarge,
                  decoration: _sheetFieldDecoration(label: 'Max age'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacing20),
          SheetSaveButton(
            onTap: () {
              widget.onSave(
                int.tryParse(_minController.text),
                int.tryParse(_maxController.text),
              );
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
