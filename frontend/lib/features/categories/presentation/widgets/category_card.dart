import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:frontend/app/app_router.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/theme/app_dimensions.dart';
import 'package:frontend/core/theme/app_text_styles.dart';
import 'package:frontend/features/categories/domain/models/category_model.dart';
import 'package:go_router/go_router.dart';

const _kIconColors = [
  (bg: Color(0xFFE8F5E9), fg: Color(0xFF2E7D32)),
  (bg: Color(0xFFE3F2FD), fg: Color(0xFF1565C0)),
  (bg: Color(0xFFFFF3E0), fg: Color(0xFFE65100)),
  (bg: Color(0xFFF3E5F5), fg: Color(0xFF6A1B9A)),
  (bg: Color(0xFFE0F7FA), fg: Color(0xFF00695C)),
  (bg: Color(0xFFFCE4EC), fg: Color(0xFFC62828)),
];

const _kIconData = [
  Icons.design_services_outlined,
  Icons.build_outlined,
  Icons.school_outlined,
  Icons.health_and_safety_outlined,
  Icons.computer_outlined,
  Icons.home_repair_service_outlined,
];

void _showDescriptionSheet(BuildContext context, String title, String description) {
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
          Text(title, style: AppTextStyles.titleMedium),
          const SizedBox(height: AppDimensions.spacing12),
          Text(description, style: AppTextStyles.bodyMedium.copyWith(height: 1.6)),
        ],
      ),
    ),
  );
}

class _CategoryIcon extends StatelessWidget {
  final String? imageUrl;
  final IconData fallbackIcon;
  final Color bg;
  final Color fg;

  const _CategoryIcon({
    required this.imageUrl,
    required this.fallbackIcon,
    required this.bg,
    required this.fg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      ),
      clipBehavior: Clip.antiAlias,
      child: imageUrl != null
          ? CachedNetworkImage(
              imageUrl: imageUrl!,
              fit: BoxFit.cover,
              placeholder: (_, _) => Icon(fallbackIcon, color: fg, size: 24),
              errorWidget: (_, _, _) => Icon(fallbackIcon, color: fg, size: 24),
            )
          : Icon(fallbackIcon, color: fg, size: 24),
    );
  }
}

class CategoryCard extends StatelessWidget {
  final CategoryModel category;
  final int index;

  const CategoryCard({super.key, required this.category, this.index = 0});

  @override
  Widget build(BuildContext context) {
    final colorPair = _kIconColors[index % _kIconColors.length];
    final iconData = _kIconData[index % _kIconData.length];
    final desc = category.shortDescription;

    return GestureDetector(
      onTap: () => context.push(AppRoutes.subcategories, extra: category),
      child: Container(
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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _CategoryIcon(
              imageUrl: category.imageUrl,
              fallbackIcon: iconData,
              bg: colorPair.bg,
              fg: colorPair.fg,
            ),
            const SizedBox(width: AppDimensions.spacing16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(category.name, style: AppTextStyles.titleSmall),
                  if (desc != null) ...[
                    const SizedBox(height: AppDimensions.spacing6),
                    GestureDetector(
                      onTap: () => _showDescriptionSheet(context, category.name, desc),
                      behavior: HitTestBehavior.opaque,
                      child: Text(
                        'Learn more',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.primaryDark,
                          decoration: TextDecoration.underline,
                          decorationColor: AppColors.primaryDark,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppDimensions.spacing8),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 13,
              color: AppColors.textHint,
            ),
          ],
        ),
      ),
    );
  }
}
