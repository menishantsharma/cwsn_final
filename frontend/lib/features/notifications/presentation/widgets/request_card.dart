import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/theme/app_dimensions.dart';
import 'package:frontend/core/theme/app_text_styles.dart';
import 'package:frontend/features/requests/domain/models/request_model.dart';
import 'package:frontend/features/requests/presentation/providers/request_provider.dart';

class RequestCard extends ConsumerWidget {
  final RequestModel request;

  const RequestCard({super.key, required this.request});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPending = request.status == 'Pending';
    final isAccepted = request.status == 'Accepted';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: AppColors.border),
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
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                    ),
                    Text(
                      '${request.childName} · ${request.childAge}y · ${request.childGender}',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppDimensions.spacing8),
              _StatusChip(status: request.status),
            ],
          ),
          if (request.note != null && request.note!.isNotEmpty) ...[
            const SizedBox(height: AppDimensions.spacing12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppDimensions.spacing12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              ),
              child: Text(
                request.note!,
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
              ),
            ),
          ],
          if (isPending) ...[
            const SizedBox(height: AppDimensions.spacing16),
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    label: 'Decline',
                    onTap: () => ref.read(requestProvider.notifier).reject(request.id),
                    filled: false,
                  ),
                ),
                const SizedBox(width: AppDimensions.spacing12),
                Expanded(
                  child: _ActionButton(
                    label: 'Accept',
                    onTap: () => ref.read(requestProvider.notifier).accept(request.id),
                    filled: true,
                  ),
                ),
              ],
            ),
          ],
          if (isAccepted && request.caregiverPhone != null) ...[
            const SizedBox(height: AppDimensions.spacing12),
            Row(
              children: [
                const Icon(Icons.phone_outlined, size: 13, color: AppColors.primary),
                const SizedBox(width: AppDimensions.spacing6),
                Text(
                  request.caregiverPhone!,
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary),
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
  final bool filled;

  const _ActionButton({required this.label, required this.onTap, required this.filled});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: Material(
        color: filled ? AppColors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          child: Container(
            decoration: filled
                ? null
                : BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  ),
            child: Center(
              child: Text(
                label,
                style: AppTextStyles.labelMedium.copyWith(
                  color: filled ? Colors.white : AppColors.textSecondary,
                ),
              ),
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
    final (color, bg) = switch (status) {
      'Accepted' => (const Color(0xFF2E7D32), const Color(0xFFE8F5E9)),
      'Rejected' => (const Color(0xFFC62828), const Color(0xFFFFEBEE)),
      _ => (AppColors.textSecondary, AppColors.background),
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacing8,
        vertical: AppDimensions.spacing4,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      ),
      child: Text(
        status,
        style: AppTextStyles.labelSmall.copyWith(color: color, fontSize: 11),
      ),
    );
  }
}
