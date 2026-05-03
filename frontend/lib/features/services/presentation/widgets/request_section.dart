import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/theme/app_dimensions.dart';
import 'package:frontend/core/theme/app_text_styles.dart';
import 'package:frontend/features/interactions/presentation/providers/upvote_provider.dart';
import 'package:frontend/features/profile/domain/models/profile_model.dart'
    hide CaregiverProfileModel;
import 'package:frontend/features/profile/presentation/providers/profile_provider.dart';
import 'package:frontend/features/requests/domain/models/request_model.dart';
import 'package:frontend/features/requests/presentation/providers/request_provider.dart';
import 'package:frontend/features/services/domain/models/service_model.dart';
import 'package:frontend/features/services/presentation/widgets/sheet_widgets.dart';

class RequestButton extends ConsumerWidget {
  final int serviceId;

  const RequestButton({super.key, required this.serviceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      height: AppDimensions.buttonHeight,
      child: Material(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        child: InkWell(
          onTap: () => _showRequestSheet(context, serviceId),
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.phone_outlined, size: 18, color: Colors.white),
              const SizedBox(width: AppDimensions.spacing8),
              Text(
                'Request Contact',
                style: AppTextStyles.labelLarge.copyWith(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRequestSheet(BuildContext context, int serviceId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusXl),
        ),
      ),
      builder: (_) => RequestSheet(serviceId: serviceId),
    );
  }
}

class RequestStatus extends StatelessWidget {
  final RequestModel request;

  const RequestStatus({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    final isAccepted = request.status == 'Accepted';
    final isPending = request.status == 'Pending';

    final (color, bg) = switch (request.status) {
      'Accepted' => (const Color(0xFF2E7D32), const Color(0xFFE8F5E9)),
      'Rejected' => (const Color(0xFFC62828), const Color(0xFFFFEBEE)),
      _ => (AppColors.textSecondary, AppColors.background),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacing12,
            vertical: AppDimensions.spacing6,
          ),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
          ),
          child: Text(
            isPending ? 'Request Pending' : request.status,
            style: AppTextStyles.labelSmall.copyWith(color: color),
          ),
        ),
        if (isAccepted && request.caregiverPhone != null) ...[
          const SizedBox(height: AppDimensions.spacing12),
          GestureDetector(
            onLongPress: () {
              Clipboard.setData(ClipboardData(text: request.caregiverPhone!));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Phone number copied')),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.spacing16,
                vertical: AppDimensions.spacing12,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                border: Border.all(color: const Color(0xFFA5D6A7)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.phone_outlined, size: 16, color: Color(0xFF2E7D32)),
                  const SizedBox(width: AppDimensions.spacing8),
                  Text(
                    request.caregiverPhone!,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: const Color(0xFF2E7D32),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Hold to copy',
                    style: AppTextStyles.labelSmall.copyWith(color: AppColors.textHint),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class RequestSheet extends ConsumerStatefulWidget {
  final int serviceId;

  const RequestSheet({super.key, required this.serviceId});

  @override
  ConsumerState<RequestSheet> createState() => _RequestSheetState();
}

class _RequestSheetState extends ConsumerState<RequestSheet> {
  ChildProfileModel? _selectedChild;
  final _noteController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedChild == null) return;
    setState(() => _loading = true);
    try {
      await ref.read(requestProvider.notifier).sendRequest(
            serviceId: widget.serviceId,
            childId: _selectedChild!.id,
            note: _noteController.text.trim(),
          );
      ref.invalidate(parentRequestsProvider);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);
    final children = profileAsync.value?.cwsnProfile?.children ?? [];

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
          Text('Request Contact', style: AppTextStyles.titleMedium),
          const SizedBox(height: AppDimensions.spacing4),
          Text(
            'Select the child this request is for',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppDimensions.spacing20),
          if (children.isEmpty)
            Container(
              padding: const EdgeInsets.all(AppDimensions.spacing16),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              ),
              child: Text(
                'No children added yet. Add a child from your profile first.',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
              ),
            )
          else
            ...children.map(
              (child) => ChildOption(
                child: child,
                selected: _selectedChild?.id == child.id,
                onTap: () => setState(() => _selectedChild = child),
              ),
            ),
          const SizedBox(height: AppDimensions.spacing12),
          TextField(
            controller: _noteController,
            maxLines: 3,
            style: AppTextStyles.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Add a note (optional)',
              hintStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.textHint),
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
            ),
          ),
          const SizedBox(height: AppDimensions.spacing20),
          SizedBox(
            width: double.infinity,
            height: AppDimensions.buttonHeight,
            child: Material(
              color: _selectedChild == null ? AppColors.border : AppColors.primary,
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              child: InkWell(
                onTap: (_selectedChild == null || _loading) ? null : _submit,
                borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                child: Center(
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          'Send Request',
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
    );
  }
}

class ChildOption extends StatelessWidget {
  final ChildProfileModel child;
  final bool selected;
  final VoidCallback onTap;

  const ChildOption({
    super.key,
    required this.child,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppDimensions.spacing8),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacing16,
          vertical: AppDimensions.spacing12,
        ),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.06)
              : AppColors.background,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              size: 18,
              color: selected ? AppColors.primary : AppColors.textHint,
            ),
            const SizedBox(width: AppDimensions.spacing12),
            Text(
              '${child.name} · ${child.age}y · ${child.gender}',
              style: AppTextStyles.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class ReportSheet extends ConsumerStatefulWidget {
  final ServiceModel service;

  const ReportSheet({super.key, required this.service});

  @override
  ConsumerState<ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends ConsumerState<ReportSheet> {
  final _reasonController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final reason = _reasonController.text.trim();
    if (reason.isEmpty) return;
    setState(() => _loading = true);
    try {
      await ref.read(reportProvider).reportService(
            reportedUserId: widget.service.caregiverId,
            reason: reason,
          );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report submitted. Thank you.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to submit report. Try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20, 12, 20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SheetHandle(),
          Row(
            children: [
              const Icon(Icons.flag_outlined, color: Color(0xFFC62828), size: 18),
              const SizedBox(width: AppDimensions.spacing8),
              Text('Report Service', style: AppTextStyles.titleMedium),
            ],
          ),
          const SizedBox(height: AppDimensions.spacing4),
          Text(
            'Describe the issue. Our team will review it.',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppDimensions.spacing16),
          TextField(
            controller: _reasonController,
            maxLines: 4,
            autofocus: true,
            style: AppTextStyles.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Explain what\'s wrong...',
              hintStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.textHint),
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
            ),
          ),
          const SizedBox(height: AppDimensions.spacing20),
          SizedBox(
            width: double.infinity,
            height: AppDimensions.buttonHeight,
            child: Material(
              color: const Color(0xFFC62828),
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              child: InkWell(
                onTap: _loading ? null : _submit,
                borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                child: Center(
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          'Submit Report',
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
    );
  }
}
