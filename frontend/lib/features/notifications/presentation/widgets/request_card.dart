import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/theme/app_dimensions.dart';
import 'package:frontend/core/theme/app_text_styles.dart';
import 'package:frontend/features/requests/domain/models/request_model.dart';
import 'package:frontend/features/requests/presentation/providers/request_provider.dart';

void _showNoteSheet(BuildContext context, String note) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimensions.radiusXl)),
    ),
    builder: (_) => Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.spacing20),
          Text('Note from requester', style: AppTextStyles.titleSmall),
          const SizedBox(height: AppDimensions.spacing12),
          Text(
            note,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    ),
  );
}

class RequestCard extends ConsumerStatefulWidget {
  final RequestModel request;

  const RequestCard({super.key, required this.request});

  @override
  ConsumerState<RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends ConsumerState<RequestCard> {
  bool _accepting = false;
  bool _rejecting = false;

  Future<void> _accept() async {
    if (_accepting || _rejecting) return;
    setState(() => _accepting = true);
    try {
      await ref.read(pendingRequestsProvider.notifier).accept(widget.request.id);
    } finally {
      if (mounted) setState(() => _accepting = false);
    }
  }

  Future<void> _reject() async {
    if (_accepting || _rejecting) return;
    setState(() => _rejecting = true);
    try {
      await ref.read(pendingRequestsProvider.notifier).reject(widget.request.id);
    } finally {
      if (mounted) setState(() => _rejecting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = widget.request;
    final isPending = request.status == 'Pending';
    final isAccepted = request.status == 'Accepted';
    final hasNote = request.note != null && request.note!.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppDimensions.spacing16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(request.serviceTitle, style: AppTextStyles.titleSmall),
                    const SizedBox(height: AppDimensions.spacing4),
                    Text(
                      request.cwsnUserName,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${request.childName} · ${request.childAge}y · ${request.childGender}',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textHint),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppDimensions.spacing8),
              _StatusChip(status: request.status),
            ],
          ),
          if (hasNote || isAccepted) ...[
            const SizedBox(height: AppDimensions.spacing12),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: AppDimensions.spacing12),
            Row(
              children: [
                if (hasNote)
                  GestureDetector(
                    onTap: () => _showNoteSheet(context, request.note!),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.sticky_note_2_outlined, size: 13, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            'Note',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (isAccepted && request.caregiverPhone != null) ...[
                  if (hasNote) const SizedBox(width: AppDimensions.spacing8),
                  const Icon(Icons.phone_outlined, size: 13, color: AppColors.primary),
                  const SizedBox(width: AppDimensions.spacing4),
                  Text(
                    request.caregiverPhone!,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ],
          if (isPending) ...[
            const SizedBox(height: AppDimensions.spacing12),
            if (!hasNote) ...[
              const Divider(height: 1, color: AppColors.border),
              const SizedBox(height: AppDimensions.spacing12),
            ],
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    label: 'Decline',
                    onTap: _reject,
                    loading: _rejecting,
                    filled: false,
                  ),
                ),
                const SizedBox(width: AppDimensions.spacing12),
                Expanded(
                  child: _ActionButton(
                    label: 'Accept',
                    onTap: _accept,
                    loading: _accepting,
                    filled: true,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool loading;
  final bool filled;

  const _ActionButton({
    required this.label,
    required this.onTap,
    required this.loading,
    required this.filled,
  });

  @override
  Widget build(BuildContext context) {
    final color = filled ? AppColors.primary : AppColors.errorLight;
    final contentColor = filled ? Colors.white : AppColors.error;
    return SizedBox(
      height: 40,
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        child: InkWell(
          onTap: loading ? null : onTap,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          child: Center(
            child: loading
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: contentColor,
                    ),
                  )
                : Text(
                    label,
                    style: AppTextStyles.labelMedium.copyWith(color: contentColor),
                  ),
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, bg, icon) = switch (status) {
      'Accepted' => (const Color(0xFF2E7D32), const Color(0xFFE8F5E9), Icons.check_rounded),
      'Rejected' => (const Color(0xFFC62828), const Color(0xFFFFEBEE), Icons.close_rounded),
      _ => (AppColors.warning, AppColors.warningLight, Icons.schedule_rounded),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 3),
          Text(
            status,
            style: AppTextStyles.labelSmall.copyWith(color: color, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
