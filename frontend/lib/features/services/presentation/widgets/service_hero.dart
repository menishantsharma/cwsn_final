import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_colors.dart';

class ServiceHero extends StatelessWidget {
  final String? image;

  const ServiceHero({super.key, this.image});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      width: double.infinity,
      color: AppColors.primary.withValues(alpha: 0.08),
      child: image != null
          ? Image.network(image!, fit: BoxFit.cover)
          : Center(
              child: Icon(
                Icons.design_services_outlined,
                size: 56,
                color: AppColors.primary.withValues(alpha: 0.4),
              ),
            ),
    );
  }
}
