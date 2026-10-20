import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    super.key,
    required this.onClearLocalData,
  });

  final Future<void> Function() onClearLocalData;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 30),
      children: [
        const Text(
          'RIDER ACCOUNT',
          style: TextStyle(
            color: AppTheme.orange,
            letterSpacing: 2.2,
            fontWeight: FontWeight.w900,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          'My Profile',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 20),

        // Rider profile header
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: AppTheme.orange.withValues(alpha: 0.22),
            ),
          ),
          child: Column(
            children: [
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.orange,
                        width: 2,
                      ),
                    ),
                    child: const CircleAvatar(
                      radius: 39,
                      backgroundColor: AppTheme.surfaceRaised,
                      child: Icon(
                        Icons.person_rounded,
                        color: AppTheme.orange,
                        size: 43,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(
                      color: AppTheme.orange,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.edit_rounded,
                      size: 14,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 13),
              const Text(
                'Your Rider Profile',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Make your RideSync experience personal.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.muted,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 17),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _showProfileSetupInfo(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.orange,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.person_add_alt_1_rounded),
                  label: const Text(
                    'Set Up Rider Profile',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        _sectionHeader(
          title: 'PERSONAL INFORMATION',
          action: 'EDITABLE IN NEXT STEP',
        ),
        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 5,
          ),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Column(
            children: [
              _ProfileInfoTile(
                icon: Icons.badge_outlined,
                title: 'Full name',
                value: 'Not added yet',
              ),
              _ProfileInfoTile(
                icon: Icons.wc_rounded,
                title: 'Gender',
                value: 'Not added yet',
              ),
              _ProfileInfoTile(
                icon: Icons.calendar_month_outlined,
                title: 'Date of birth',
                value: 'Not added yet',
              ),
              _ProfileInfoTile(
                icon: Icons.phone_outlined,
                title: 'Contact number',
                value: 'Not added yet',
              ),
              _ProfileInfoTile(
                icon: Icons.mail_outline_rounded,
                title: 'Email address',
                value: 'Not added yet',
                showDivider: false,
              ),
            ],
          ),
        ),

        const SizedBox(height: 25),

        // Garage preview
        _sectionHeader(
          title: 'MY GARAGE',
          action: 'MOTORCYCLES',
        ),
        const SizedBox(height: 12),

        _EmptySectionCard(
          icon: Icons.two_wheeler_rounded,
          title: 'Your motorcycles',
          description:
              'Your saved motorcycles will appear here with their photos, model names, and odometer readings.',
        ),

        const SizedBox(height: 25),

        // Recent ride history
        _sectionHeader(
          title: 'RECENT RIDES',
          action: 'RIDE HISTORY',
        ),
        const SizedBox(height: 12),

        _EmptySectionCard(
          icon: Icons.route_rounded,
          title: 'Your riding journey',
          description:
              'Your recent rides will appear here with the date, distance, duration, and motorcycle used.',
        ),

        const SizedBox(height: 25),

        _sectionHeader(title: 'PREFERENCES'),
        const SizedBox(height: 12),

        const _SettingsTile(
          icon: Icons.storage_outlined,
          title: 'Offline-first storage',
          subtitle: 'Your data is saved on this device.',
        ),
        const _SettingsTile(
          icon: Icons.palette_outlined,
          title: 'Racing dark theme',
          subtitle: 'Matte black, charcoal and racing orange.',
        ),
        const _SettingsTile(
          icon: Icons.cloud_outlined,
          title: 'Cloud sync',
          subtitle: 'Planned for a future release.',
          trailing: _LaterLabel(),
        ),
        const _SettingsTile(
          icon: Icons.groups_outlined,
          title: 'Rider community',
          subtitle: 'Planned for a future release.',
          trailing: _LaterLabel(),
        ),

        const SizedBox(height: 15),

        OutlinedButton.icon(
          onPressed: () => _confirmClear(context),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.redAccent,
            side: BorderSide(
              color: Colors.redAccent.withValues(alpha: 0.4),
            ),
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(13),
            ),
          ),
          icon: const Icon(Icons.delete_outline_rounded),
          label: const Text('Clear all local data'),
        ),

        const SizedBox(height: 24),

        const Center(
          child: Text(
            'RIDESYNC  •  FOUNDATION 1.0.0',
            style: TextStyle(
              color: AppTheme.muted,
              fontSize: 10,
              letterSpacing: 1.1,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionHeader({
    required String title,
    String? action,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w900,
              color: AppTheme.orange,
            ),
          ),
        ),
        if (action != null)
          Text(
            action,
            style: const TextStyle(
              color: AppTheme.muted,
              fontSize: 9,
              letterSpacing: 0.6,
              fontWeight: FontWeight.w800,
            ),
          ),
      ],
    );
  }

  void _showProfileSetupInfo(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Rider profile'),
        content: const Text(
          'The profile layout is ready. The next step is to connect '
          'the edit form, profile photo, and personal details to '
          'your existing local storage.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Clear local data?'),
        content: const Text(
          'This permanently removes saved motorcycles and ride '
          'records from this device. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Clear data'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await onClearLocalData();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Local data cleared.'),
          ),
        );
      }
    }
  }
}

class _ProfileInfoTile extends StatelessWidget {
  const _ProfileInfoTile({
    required this.icon,
    required this.title,
    required this.value,
    this.showDivider = true,
  });

  final IconData icon;
  final String title;
  final String value;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceRaised,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: AppTheme.orange,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: const TextStyle(
                        color: AppTheme.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            color: AppTheme.muted.withValues(alpha: 0.12),
          ),
      ],
    );
  }
}

class _EmptySectionCard extends StatelessWidget {
  const _EmptySectionCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppTheme.muted.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.surfaceRaised,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: AppTheme.orange,
              size: 25,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: const TextStyle(
                    color: AppTheme.muted,
                    height: 1.5,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.surfaceRaised,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppTheme.orange),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppTheme.muted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing!,
          ],
        ],
      ),
    );
  }
}

class _LaterLabel extends StatelessWidget {
  const _LaterLabel();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'LATER',
      style: TextStyle(
        color: AppTheme.orange,
        fontSize: 10,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}