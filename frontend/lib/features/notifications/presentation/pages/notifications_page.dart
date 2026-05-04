import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/theme/app_text_styles.dart';
import 'package:frontend/core/widgets/app_bar.dart';
import 'package:frontend/features/notifications/presentation/widgets/notifications_tab.dart';
import 'package:frontend/features/notifications/presentation/widgets/requests_tab.dart';

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppTopBar(
          title: 'Inbox',
          bottom: TabBar(
            labelStyle: AppTextStyles.labelMedium,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            indicatorWeight: 2,
            dividerColor: AppColors.border,
            tabs: [
              const Tab(text: 'Notifications'),
              const RequestsTab(),
            ],
          ),
        ),
        body: const TabBarView(
          children: [NotificationsTab(), RequestsTabView()],
        ),
      ),
    );
  }
}
