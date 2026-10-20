import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.onClearLocalData});
  final Future<void> Function() onClearLocalData;

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
        children: [
          const Text('PREFERENCES', style: TextStyle(color: AppTheme.orange, letterSpacing: 2.2, fontWeight: FontWeight.w900, fontSize: 11)),
          const SizedBox(height: 8),
          Text('Settings', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(20)),
            child: const Row(children: [
              CircleAvatar(radius: 25, backgroundColor: AppTheme.orange, child: Icon(Icons.two_wheeler, color: Colors.black, size: 28)),
              SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('RideSync Rider', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
                SizedBox(height: 4),
                Text('Personal motorcycle companion', style: TextStyle(color: AppTheme.muted, fontSize: 12)),
              ])),
            ]),
          ),
          const SizedBox(height: 18),
          _SettingsTile(icon: Icons.storage_outlined, title: 'Offline-first storage', subtitle: 'Your data is saved on this device.'),
          _SettingsTile(icon: Icons.palette_outlined, title: 'Racing dark theme', subtitle: 'Matte black, charcoal and racing orange.'),
          _SettingsTile(icon: Icons.cloud_outlined, title: 'Cloud sync', subtitle: 'Planned for a future release.', trailing: const Text('LATER', style: TextStyle(color: AppTheme.orange, fontSize: 10, fontWeight: FontWeight.w900))),
          _SettingsTile(icon: Icons.groups_outlined, title: 'Rider community', subtitle: 'Planned for a future release.', trailing: const Text('LATER', style: TextStyle(color: AppTheme.orange, fontSize: 10, fontWeight: FontWeight.w900))),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: () => _confirmClear(context),
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            label: const Text('Clear all local data', style: TextStyle(color: Colors.redAccent)),
          ),
          const SizedBox(height: 20),
          const Center(child: Text('RIDESYNC • FOUNDATION 1.0.0', style: TextStyle(color: AppTheme.muted, fontSize: 10, letterSpacing: 1.1))),
        ],
      );

  Future<void> _confirmClear(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Clear local data?'),
        content: const Text('This permanently removes saved motorcycles and ride records from this device. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Clear data'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await onClearLocalData();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Local data cleared.')));
      }
    }
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({required this.icon, required this.title, required this.subtitle, this.trailing});
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(16)),
        child: Row(children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppTheme.surfaceRaised, borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: AppTheme.orange)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(color: AppTheme.muted, fontSize: 12)),
          ])),
          if (trailing != null) trailing!,
        ]),
      );
}
