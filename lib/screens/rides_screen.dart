import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../models/motorcycle.dart';
import '../models/ride.dart';

class RidesScreen extends StatelessWidget {
  const RidesScreen({super.key, required this.rides, required this.motorcycles});
  final List<RideRecord> rides;
  final List<Motorcycle> motorcycles;

  String _bikeName(int id) {
    for (final bike in motorcycles) {
      if (bike.id == id) return bike.displayName;
    }
    return 'Motorcycle';
  }

  @override
  Widget build(BuildContext context) {
    final distance = rides.fold<double>(0, (sum, ride) => sum + ride.distanceKm);
    final minutes = rides.fold<int>(0, (sum, ride) => sum + ride.durationMinutes);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
      children: [
        const Text('YOUR JOURNEY', style: TextStyle(color: AppTheme.orange, letterSpacing: 2.2, fontWeight: FontWeight.w900, fontSize: 11)),
        const SizedBox(height: 8),
        Text('Ride history', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(child: _Summary(label: 'TOTAL DISTANCE', value: '${distance.toStringAsFixed(1)} km', icon: Icons.route)),
          const SizedBox(width: 10),
          Expanded(child: _Summary(label: 'TIME ON ROAD', value: '${(minutes / 60).toStringAsFixed(1)} hr', icon: Icons.timer_outlined)),
        ]),
        const SizedBox(height: 24),
        if (rides.isEmpty)
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(20)),
            child: const Column(children: [
              Icon(Icons.route, size: 46, color: AppTheme.orange),
              SizedBox(height: 12),
              Text('Your story starts here', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
              SizedBox(height: 8),
              Text('Log a ride from the Home tab to see your history and statistics here.', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.muted, height: 1.4)),
            ]),
          )
        else
          ...rides.map((ride) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(18)),
                child: Row(children: [
                  Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppTheme.surfaceRaised, borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.route, color: AppTheme.orange)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(ride.note.isEmpty ? _bikeName(ride.motorcycleId) : ride.note, style: const TextStyle(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Text('${_bikeName(ride.motorcycleId)} • ${ride.date.day}/${ride.date.month}/${ride.date.year}', style: const TextStyle(color: AppTheme.muted, fontSize: 11)),
                    const SizedBox(height: 4),
                    Text('${ride.durationMinutes} minutes', style: const TextStyle(color: AppTheme.muted, fontSize: 12)),
                  ])),
                  Text('${ride.distanceKm.toStringAsFixed(1)} km', style: const TextStyle(color: AppTheme.orange, fontWeight: FontWeight.w900)),
                ]),
              )),
      ],
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.label, required this.value, required this.icon});
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(18)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: AppTheme.orange),
          const SizedBox(height: 14),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: AppTheme.muted, fontSize: 9, letterSpacing: 0.6)),
        ]),
      );
}
