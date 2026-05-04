import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_colors.dart';

class ServiceHero extends StatelessWidget {
  final String? image;

  const ServiceHero({super.key, this.image});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
      child: Container(
        height: 220,
        width: double.infinity,
        color: AppColors.primary.withValues(alpha: 0.08),
        child: image != null
            ? CachedNetworkImage(
                imageUrl: image!,
                fit: BoxFit.cover,
                placeholder: (_, _) => const _HeroPlaceholder(),
                errorWidget: (_, _, _) => const _HeroPlaceholder(),
              )
            : const _HeroPlaceholder(),
      ),
    );
  }
}

class _HeroPlaceholder extends StatelessWidget {
  const _HeroPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(
        Icons.design_services_outlined,
        size: 56,
        color: AppColors.primary.withValues(alpha: 0.35),
      ),
    );
  }
}
