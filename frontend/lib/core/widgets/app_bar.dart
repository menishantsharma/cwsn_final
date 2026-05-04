import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/theme/app_text_styles.dart';

class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final Widget? leading;

  const AppTopBar({
    super.key,
    this.title,
    this.actions,
    this.bottom,
    this.leading,
  });

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight + (bottom?.preferredSize.height ?? 0),
      );

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();

    return AppBar(
      title: title != null ? Text(title!, style: AppTextStyles.titleMedium) : null,
      leading: leading ?? (canPop
          ? IconButton(
              icon: const Icon(Icons.chevron_left, size: 28),
              color: AppColors.textPrimary,
              onPressed: () => Navigator.of(context).pop(),
            )
          : null),
      automaticallyImplyLeading: false,
      actions: actions,
      bottom: bottom,
    );
  }
}
