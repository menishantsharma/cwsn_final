import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/app/app_router.dart';
import 'package:frontend/features/auth/presentation/providers/auth_provider.dart';
import 'package:frontend/features/profile/presentation/providers/profile_provider.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => context.push(AppRoutes.editProfile),
          ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load profile: $e')),
        data: (profile) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _AvatarSection(name: profile.cwsnProfile?.name ?? ''),
            const SizedBox(height: 24),
            _InfoCard(
              title: 'Personal Info',
              children: [
                _InfoRow(
                  label: 'Phone',
                  value: profile.cwsnProfile?.phoneNumber ?? '',
                ),
                _InfoRow(
                  label: 'Age',
                  value: profile.cwsnProfile?.age.toString() ?? '',
                ),
                _InfoRow(
                  label: 'Gender',
                  value: profile.cwsnProfile?.gender ?? '',
                ),
                _InfoRow(
                  label: 'Street Address',
                  value: profile.cwsnProfile?.streetAddress ?? '',
                ),
                _InfoRow(
                  label: 'Landmark',
                  value: profile.cwsnProfile?.landmark ?? '',
                ),
                _InfoRow(
                  label: 'Postal Code',
                  value: profile.cwsnProfile?.postalCode ?? '',
                ),
              ],
            ),
            const SizedBox(height: 16),
            _InfoCard(
              title: 'Caregiver Info',
              children: [
                _InfoRow(
                  label: 'About Me',
                  value: profile.caregiverProfile?.aboutMe ?? '',
                ),
                _InfoRow(
                  label: 'Qualifications',
                  value: profile.caregiverProfile?.qualifications ?? '',
                ),
                _InfoRow(
                  label: 'Languages',
                  value: profile.caregiverProfile?.languages.join(', ') ?? '',
                ),
              ],
            ),
            const SizedBox(height: 32),
            OutlinedButton.icon(
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              onPressed: () => _confirmLogout(context, ref),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.delete_forever, color: Colors.red),
              label: const Text(
                'Delete Account',
                style: TextStyle(color: Colors.red),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
              ),
              onPressed: () => _confirmDeleteAccount(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(authProvider.notifier).logout();
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'This will permanently delete your account and all your data. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(profileProvider.notifier).deleteAccount();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _AvatarSection extends StatelessWidget {
  final String name;

  const _AvatarSection({required this.name});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 48,
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: const TextStyle(fontSize: 40, color: Colors.white),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          name,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _InfoCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(child: Text(value.isNotEmpty ? value : '—')),
        ],
      ),
    );
  }
}
