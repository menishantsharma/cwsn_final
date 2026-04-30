import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/theme/app_dimensions.dart';
import 'package:frontend/core/theme/app_text_styles.dart';
import 'package:frontend/features/categories/domain/models/subcategory_model.dart';
import 'package:frontend/features/services/presentation/providers/service_provider.dart';

class CreateServicePage extends ConsumerStatefulWidget {
  final SubcategoryModel subcategory;

  const CreateServicePage({super.key, required this.subcategory});

  @override
  ConsumerState<CreateServicePage> createState() => _CreateServicePageState();
}

class _CreateServicePageState extends ConsumerState<CreateServicePage> {
  String _title = '';
  String _description = '';
  String _serviceType = 'Online';
  String _paymentType = 'Paid';
  String _targetGender = 'Any';
  int? _targetAgeMin;
  int? _targetAgeMax;
  bool _isLoading = false;

  bool get _canCreate =>
      _title.trim().isNotEmpty && _description.trim().isNotEmpty;

  Future<void> _create() async {
    final navigator = Navigator.of(context);
    setState(() => _isLoading = true);
    try {
      await ref
          .read(serviceRepositoryProvider)
          .createService(
            fields: {
              'title': _title.trim(),
              'description': _description.trim(),
              'service_type': _serviceType,
              'payment_type': _paymentType,
              'target_gender': _targetGender,
              'target_age_min': _targetAgeMin,
              'target_age_max': _targetAgeMax,
              'category': widget.subcategory.categoryId,
              'sub_category': widget.subcategory.id,
            }..removeWhere((_, v) => v == null),
          );
      // Invalidate so services_page refreshes
      ref.invalidate(
        myServiceProvider((
          widget.subcategory.categoryId,
          widget.subcategory.id,
        )),
      );
      ref.invalidate(
        serviceProvider((widget.subcategory.categoryId, widget.subcategory.id)),
      );
      navigator.pop();
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('New Service', style: AppTextStyles.titleSmall),
        actions: [
          _isLoading
              ? const Padding(
                  padding: EdgeInsets.only(right: 16),
                  child: Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              : TextButton(
                  onPressed: _canCreate ? _create : null,
                  child: Text(
                    'Create',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: _canCreate
                          ? AppColors.primary
                          : AppColors.textHint,
                    ),
                  ),
                ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: AppDimensions.spacing8,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Placeholder hero
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
              ),
              child: Center(
                child: Icon(
                  Icons.design_services_outlined,
                  size: 64,
                  color: AppColors.primary.withValues(alpha: 0.5),
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.spacing20),

            // Title
            _FieldRow(
              value: _title.isEmpty ? null : _title,
              hint: 'Add title *',
              style: AppTextStyles.displaySmall,
              onEdit: () => _showTextSheet(
                context,
                label: 'Title',
                value: _title,
                onSave: (v) => setState(() => _title = v),
              ),
            ),
            const SizedBox(height: AppDimensions.spacing12),

            // Service type + payment type
            Row(
              children: [
                _ChipField(
                  label: _serviceType,
                  icon: Icons.location_on_outlined,
                  onEdit: () => _showChipSheet(
                    context,
                    label: 'Service Type',
                    options: const ['Online', 'Offline', 'Hybrid'],
                    selected: _serviceType,
                    onSave: (v) => setState(() => _serviceType = v),
                  ),
                ),
                const SizedBox(width: AppDimensions.spacing8),
                _ChipField(
                  label: _paymentType,
                  icon: Icons.payments_outlined,
                  onEdit: () => _showChipSheet(
                    context,
                    label: 'Payment Type',
                    options: const ['Paid', 'Unpaid'],
                    selected: _paymentType,
                    onSave: (v) => setState(() => _paymentType = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spacing20),

            // Description
            Text('About this service', style: AppTextStyles.titleSmall),
            const SizedBox(height: AppDimensions.spacing8),
            _FieldRow(
              value: _description.isEmpty ? null : _description,
              hint: 'Add a description *',
              style: AppTextStyles.bodyMedium,
              onEdit: () => _showTextSheet(
                context,
                label: 'Description',
                value: _description,
                maxLines: 5,
                onSave: (v) => setState(() => _description = v),
              ),
            ),
            const SizedBox(height: AppDimensions.spacing20),

            // Target audience
            Text('Target audience', style: AppTextStyles.titleSmall),
            const SizedBox(height: AppDimensions.spacing12),
            _FieldRow(
              value: _targetGender == 'Any' ? null : _targetGender,
              hint: 'Set target gender',
              style: AppTextStyles.bodyMedium,
              prefix: const Icon(
                Icons.person_outline,
                size: 16,
                color: AppColors.primary,
              ),
              onEdit: () => _showChipSheet(
                context,
                label: 'Target Gender',
                options: const ['Male', 'Female', 'Any'],
                selected: _targetGender,
                onSave: (v) => setState(() => _targetGender = v),
              ),
            ),
            const SizedBox(height: AppDimensions.spacing8),
            _FieldRow(
              value: _ageLabel(_targetAgeMin, _targetAgeMax),
              hint: 'Set age range',
              style: AppTextStyles.bodyMedium,
              prefix: const Icon(
                Icons.cake_outlined,
                size: 16,
                color: AppColors.primary,
              ),
              onEdit: () => _showAgeSheet(
                context,
                minAge: _targetAgeMin,
                maxAge: _targetAgeMax,
                onSave: (min, max) => setState(() {
                  _targetAgeMin = min;
                  _targetAgeMax = max;
                }),
              ),
            ),
            const SizedBox(height: AppDimensions.spacing32),
          ],
        ),
      ),
    );
  }

  String? _ageLabel(int? min, int? max) {
    if (min == null && max == null) return null;
    if (min != null && max != null) return '$min – $max years';
    if (min != null) return '$min+ years';
    return 'Up to $max years';
  }

  void _showTextSheet(
    BuildContext context, {
    required String label,
    required String value,
    required void Function(String) onSave,
    int maxLines = 1,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusXl),
        ),
      ),
      builder: (_) => _TextSheet(
        label: label,
        value: value,
        maxLines: maxLines,
        onSave: onSave,
      ),
    );
  }

  void _showChipSheet(
    BuildContext context, {
    required String label,
    required List<String> options,
    required String selected,
    required void Function(String) onSave,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusXl),
        ),
      ),
      builder: (_) => _ChipSheet(
        label: label,
        options: options,
        selected: selected,
        onSave: onSave,
      ),
    );
  }

  void _showAgeSheet(
    BuildContext context, {
    required void Function(int?, int?) onSave,
    int? minAge,
    int? maxAge,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusXl),
        ),
      ),
      builder: (_) => _AgeSheet(minAge: minAge, maxAge: maxAge, onSave: onSave),
    );
  }
}

// ── Field Row (same as _EditableRow) ─────────────────────

class _FieldRow extends StatelessWidget {
  final String? value;
  final String? hint;
  final TextStyle style;
  final Widget? prefix;
  final VoidCallback onEdit;

  const _FieldRow({
    required this.style,
    required this.onEdit,
    this.value,
    this.hint,
    this.prefix,
  });

  @override
  Widget build(BuildContext context) {
    final isEmpty = value == null || value!.isEmpty;
    return GestureDetector(
      onTap: onEdit,
      behavior: HitTestBehavior.opaque,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (prefix != null) ...[
            prefix!,
            const SizedBox(width: AppDimensions.spacing6),
          ],
          Expanded(
            child: isEmpty
                ? Text(
                    hint ?? 'Tap to add',
                    style: style.copyWith(
                      color: AppColors.textHint,
                      fontStyle: FontStyle.italic,
                    ),
                  )
                : Text(value!, style: style),
          ),
          const SizedBox(width: AppDimensions.spacing8),
          const Icon(Icons.edit_outlined, size: 16, color: AppColors.textHint),
        ],
      ),
    );
  }
}

// ── Chip Field ────────────────────────────────────────────

class _ChipField extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onEdit;

  const _ChipField({
    required this.label,
    required this.icon,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onEdit,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacing12,
          vertical: AppDimensions.spacing6,
        ),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: AppColors.primaryDark),
            const SizedBox(width: AppDimensions.spacing4),
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(width: AppDimensions.spacing4),
            const Icon(
              Icons.edit_outlined,
              size: 11,
              color: AppColors.primaryDark,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Text Sheet ────────────────────────────────────────────

class _TextSheet extends StatefulWidget {
  final String label;
  final String value;
  final int maxLines;
  final void Function(String) onSave;

  const _TextSheet({
    required this.label,
    required this.value,
    required this.onSave,
    this.maxLines = 1,
  });

  @override
  State<_TextSheet> createState() => _TextSheetState();
}

class _TextSheetState extends State<_TextSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.label, style: AppTextStyles.titleSmall),
          const SizedBox(height: AppDimensions.spacing12),
          TextField(
            controller: _controller,
            maxLines: widget.maxLines,
            autofocus: true,
            style: AppTextStyles.bodyLarge,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.spacing16),
          SizedBox(
            width: double.infinity,
            height: AppDimensions.buttonHeight,
            child: ElevatedButton(
              onPressed: () {
                widget.onSave(_controller.text.trim());
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                ),
              ),
              child: Text(
                'Save',
                style: AppTextStyles.labelLarge.copyWith(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Chip Sheet ────────────────────────────────────────────

class _ChipSheet extends StatefulWidget {
  final String label;
  final List<String> options;
  final String selected;
  final void Function(String) onSave;

  const _ChipSheet({
    required this.label,
    required this.options,
    required this.selected,
    required this.onSave,
  });

  @override
  State<_ChipSheet> createState() => _ChipSheetState();
}

class _ChipSheetState extends State<_ChipSheet> {
  late String _current;

  @override
  void initState() {
    super.initState();
    _current = widget.selected;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(
                      AppDimensions.radiusFull,
                    ),
                  ),
                  child: Text(
                    opt,
                    style: AppTextStyles.labelMedium.copyWith(
                      color: isSelected
                          ? Colors.white
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppDimensions.spacing20),
          SizedBox(
            width: double.infinity,
            height: AppDimensions.buttonHeight,
            child: ElevatedButton(
              onPressed: () {
                widget.onSave(_current);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                ),
              ),
              child: Text(
                'Save',
                style: AppTextStyles.labelLarge.copyWith(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Age Sheet ─────────────────────────────────────────────

class _AgeSheet extends StatefulWidget {
  final int? minAge;
  final int? maxAge;
  final void Function(int?, int?) onSave;

  const _AgeSheet({required this.onSave, this.minAge, this.maxAge});

  @override
  State<_AgeSheet> createState() => _AgeSheetState();
}

class _AgeSheetState extends State<_AgeSheet> {
  late final TextEditingController _minController;
  late final TextEditingController _maxController;

  @override
  void initState() {
    super.initState();
    _minController = TextEditingController(
      text: widget.minAge?.toString() ?? '',
    );
    _maxController = TextEditingController(
      text: widget.maxAge?.toString() ?? '',
    );
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
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Target Age Range', style: AppTextStyles.titleSmall),
          const SizedBox(height: AppDimensions.spacing12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _minController,
                  keyboardType: TextInputType.number,
                  style: AppTextStyles.bodyLarge,
                  decoration: InputDecoration(
                    labelText: 'Min age',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusMd,
                      ),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusMd,
                      ),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppDimensions.spacing12),
              Expanded(
                child: TextField(
                  controller: _maxController,
                  keyboardType: TextInputType.number,
                  style: AppTextStyles.bodyLarge,
                  decoration: InputDecoration(
                    labelText: 'Max age',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusMd,
                      ),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusMd,
                      ),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacing16),
          SizedBox(
            width: double.infinity,
            height: AppDimensions.buttonHeight,
            child: ElevatedButton(
              onPressed: () {
                widget.onSave(
                  int.tryParse(_minController.text),
                  int.tryParse(_maxController.text),
                );
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                ),
              ),
              child: Text(
                'Save',
                style: AppTextStyles.labelLarge.copyWith(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
