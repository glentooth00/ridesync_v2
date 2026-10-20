import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../models/motorcycle.dart';
import '../models/ride.dart';
import 'main_shell.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.motorcycles,
    required this.rides,
    required this.selectedMotorcycle,
    required this.onGoToGarage,
    required this.onAddRide,
  });

  final List<Motorcycle> motorcycles;
  final List<RideRecord> rides;
  final Motorcycle? selectedMotorcycle;
  final VoidCallback onGoToGarage;
  final Future<void> Function(RideRecord) onAddRide;

  double get totalDistance => rides.fold(0, (sum, ride) => sum + ride.distanceKm);

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      children: [
        Row(
          children: [
            Container(
              height: 42, width: 42,
              decoration: BoxDecoration(color: AppTheme.orange, borderRadius: BorderRadius.circular(13)),
              child: const Icon(Icons.two_wheeler, color: Colors.black, size: 26),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('RIDESYNC', style: TextStyle(letterSpacing: 2.6, fontWeight: FontWeight.w900, fontSize: 17)),
                Text('YOUR RIDE. YOUR STORY.', style: TextStyle(color: AppTheme.muted, fontSize: 9, letterSpacing: 1.4)),
              ]),
            ),
            IconButton(onPressed: onGoToGarage, icon: const Icon(Icons.add_circle_outline), tooltip: 'Add motorcycle'),
          ],
        ),
        const SizedBox(height: 28),
        Text('READY TO RIDE?', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppTheme.orange, letterSpacing: 2, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Text('Every mile\\nhas a story.', style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w900, height: 1.05)),
        const SizedBox(height: 22),
        _MotorcycleHero(motorcycle: selectedMotorcycle, onTap: onGoToGarage),
        const SizedBox(height: 18),
        Row(children: [
          Expanded(child: _StatCard(icon: Icons.route, label: 'TOTAL DISTANCE', value: '${totalDistance.toStringAsFixed(1)} km')),
          const SizedBox(width: 12),
          Expanded(child: _StatCard(icon: Icons.history, label: 'RECORDED RIDES', value: '${rides.length}')),
        ]),
        const SizedBox(height: 26),
        SectionTitle('Quick actions'),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _ActionTile(icon: Icons.add_road, label: 'Log a ride', onTap: () => _showLogRide(context))),
          const SizedBox(width: 12),
          Expanded(child: _ActionTile(icon: Icons.garage_outlined, label: 'My garage', onTap: onGoToGarage)),
        ]),
        const SizedBox(height: 26),
        SectionTitle('Recent rides'),
        const SizedBox(height: 10),
        if (rides.isEmpty)
          const _EmptyPanel(icon: Icons.route, title: 'No rides recorded yet', subtitle: 'After your next ride, add a record to start building your history.')
        else
          ...rides.take(3).map((ride) => _RideTile(ride: ride)),
        const SizedBox(height: 16),
        const Text('RideSync keeps your garage and ride records on this device.', style: TextStyle(color: AppTheme.muted, fontSize: 12)),
      ],
    );
  }

  Future<void> _showLogRide(BuildContext context) async {
    if (selectedMotorcycle == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add a motorcycle to your garage first.')));
      onGoToGarage();
      return;
    }
    final distanceController = TextEditingController();
    final durationController = TextEditingController();
    final noteController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log a ride'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(
              controller: distanceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Distance (km)', prefixIcon: Icon(Icons.route)),
              validator: (value) => (double.tryParse(value ?? '') ?? 0) <= 0 ? 'Enter a distance greater than zero' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: durationController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Duration (minutes)', prefixIcon: Icon(Icons.timer_outlined)),
              validator: (value) => (int.tryParse(value ?? '') ?? 0) <= 0 ? 'Enter duration in minutes' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(controller: noteController, decoration: const InputDecoration(labelText: 'Note (optional)', prefixIcon: Icon(Icons.notes))),
          ])),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          FilledButton(onPressed: () {
            if (formKey.currentState!.validate()) {
              Navigator.pop(dialogContext, {
                'distance': double.parse(distanceController.text.trim()),
                'duration': int.parse(durationController.text.trim()),
                'note': noteController.text.trim(),
              });
            }
          }, child: const Text('Save ride')),
        ],
      ),
    );
    distanceController.dispose();
    durationController.dispose();
    noteController.dispose();
    if (result == null) return;
    await onAddRide(RideRecord(
      id: DateTime.now().microsecondsSinceEpoch,
      motorcycleId: selectedMotorcycle!.id,
      date: DateTime.now(),
      distanceKm: result['distance'] as double,
      durationMinutes: result['duration'] as int,
      note: result['note'] as String,
    ));
  }
}

class _MotorcycleHero extends StatelessWidget {
  const _MotorcycleHero({required this.motorcycle, required this.onTap});
  final Motorcycle? motorcycle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF303235), Color(0xFF191A1C)]),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Expanded(child: Text('ACTIVE MOTORCYCLE', style: TextStyle(color: AppTheme.muted, letterSpacing: 1.4, fontSize: 10, fontWeight: FontWeight.w800))),
          const Icon(Icons.bolt, color: AppTheme.orange),
        ]),
        const SizedBox(height: 18),
        const Icon(Icons.two_wheeler, size: 66, color: AppTheme.orange),
        const SizedBox(height: 12),
        Text(motorcycle?.displayName ?? 'No motorcycle yet', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
        const SizedBox(height: 5),
        Text(
          motorcycle == null
              ? 'Build your garage to get started.'
              : '${motorcycle!.year}  •  ${motorcycle!.engineCc.isEmpty ? 'Engine size not set' : '${motorcycle!.engineCc} cc'}',
          style: const TextStyle(color: AppTheme.muted),
        ),
        const SizedBox(height: 18),
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('ODOMETER', style: TextStyle(color: AppTheme.muted, fontSize: 10, letterSpacing: 1.2)),
            const SizedBox(height: 4),
            Text('${(motorcycle?.odometerKm ?? 0).toStringAsFixed(0)} km', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
          ])),
          FilledButton.icon(onPressed: onTap, icon: const Icon(Icons.arrow_forward, size: 18), label: Text(motorcycle == null ? 'Add bike' : 'Garage')),
        ]),
      ]),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(18)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: AppTheme.orange, size: 20),
          const SizedBox(height: 14),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: AppTheme.muted, fontSize: 9, letterSpacing: 0.7)),
        ]),
      );
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white.withValues(alpha: 0.05))),
          child: Row(children: [
            Icon(icon, color: AppTheme.orange),
            const SizedBox(width: 10),
            Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800))),
            const Icon(Icons.chevron_right, color: AppTheme.muted, size: 18),
          ]),
        ),
      );
}

class _RideTile extends StatelessWidget {
  const _RideTile({required this.ride});
  final RideRecord ride;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(16)),
        child: Row(children: [
          Container(padding: const EdgeInsets.all(11), decoration: BoxDecoration(color: AppTheme.surfaceRaised, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.route, color: AppTheme.orange)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(ride.note.isEmpty ? 'Ride record' : ride.note, style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text('${ride.date.day}/${ride.date.month}/${ride.date.year}  •  ${ride.durationMinutes} min', style: const TextStyle(color: AppTheme.muted, fontSize: 12)),
          ])),
          Text('${ride.distanceKm.toStringAsFixed(1)} km', style: const TextStyle(fontWeight: FontWeight.w900, color: AppTheme.orange)),
        ]),
      );
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({required this.icon, required this.title, required this.subtitle});
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(18)),
        child: Column(children: [
          Icon(icon, size: 34, color: AppTheme.orange),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.muted, fontSize: 12, height: 1.4)),
        ]),
      );
}
