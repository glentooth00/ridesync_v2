import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../models/motorcycle.dart';
import '../models/ride.dart';
import 'odometer_screen.dart';

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

  double get totalDistance =>
      rides.fold(0.0, (sum, ride) => sum + ride.distanceKm);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
        children: [
          _buildHeader(),
          const SizedBox(height: 30),

          Text(
            'READY TO RIDE?',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppTheme.orange,
                  letterSpacing: 2.4,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 8),

          Text(
            'Every mile\nhas a story.',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  height: 1.04,
                  letterSpacing: -1.1,
                ),
          ),
          const SizedBox(height: 22),

          _MotorcycleHero(
            motorcycle: selectedMotorcycle,
            onGarage: onGoToGarage,
            onStartRide: () => _openOdometer(context),
          ),

          const SizedBox(height: 18),

          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.route_rounded,
                  label: 'TOTAL DISTANCE',
                  value: '${totalDistance.toStringAsFixed(1)} km',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  icon: Icons.history_rounded,
                  label: 'RECORDED RIDES',
                  value: '${rides.length}',
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          const _SectionTitle('Quick actions'),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _ActionTile(
                  icon: Icons.add_road_rounded,
                  label: 'Log a ride',
                  onTap: () => _showLogRide(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionTile(
                  icon: Icons.garage_outlined,
                  label: 'My garage',
                  onTap: onGoToGarage,
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          Row(
            children: [
              const Expanded(child: _SectionTitle('Recent rides')),
              Text(
                '${rides.length} TOTAL',
                style: const TextStyle(
                  color: AppTheme.muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (rides.isEmpty)
            const _EmptyPanel(
              icon: Icons.route_rounded,
              title: 'Your road starts here',
              subtitle:
                  'Record your first ride and start building your personal riding history.',
            )
          else
            ...rides.take(3).map((ride) => _RideTile(ride: ride)),

          const SizedBox(height: 20),

          const Center(
            child: Text(
              'BUILT FOR THE ROAD.',
              style: TextStyle(
                color: AppTheme.muted,
                fontSize: 10,
                letterSpacing: 2,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          height: 46,
          width: 46,
          decoration: BoxDecoration(
            color: AppTheme.orange,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.two_wheeler_rounded,
            color: Colors.black,
            size: 28,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'RIDESYNC',
                style: TextStyle(
                  letterSpacing: 2.8,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'YOUR RIDE. YOUR STORY.',
                style: TextStyle(
                  color: AppTheme.muted,
                  fontSize: 9,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: onGoToGarage,
          tooltip: 'My garage',
          style: IconButton.styleFrom(
            backgroundColor: AppTheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(13),
            ),
          ),
          icon: const Icon(Icons.add_rounded),
        ),
      ],
    );
  }

  void _openOdometer(BuildContext context) {
    final bike = selectedMotorcycle;

    if (bike == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add a motorcycle to your garage first.'),
        ),
      );
      onGoToGarage();
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => OdometerScreen(
          motorcycleName: bike.displayName,
          year: '${bike.year}',
          engineCc: int.tryParse(bike.engineCc) ?? 0,
          odometerKm: bike.odometerKm.toDouble(),
        ),
      ),
    );
  }

  Future<void> _showLogRide(BuildContext context) async {
    final bike = selectedMotorcycle;

    if (bike == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add a motorcycle to your garage first.'),
        ),
      );
      onGoToGarage();
      return;
    }

    final distanceController = TextEditingController();
    final durationController = TextEditingController();
    final noteController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    try {
      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Log a ride'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: distanceController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Distance (km)',
                      prefixIcon: Icon(Icons.route_rounded),
                    ),
                    validator: (value) {
                      final distance = double.tryParse(value ?? '');
                      if (distance == null || distance <= 0) {
                        return 'Enter a distance greater than zero';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: durationController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Duration (minutes)',
                      prefixIcon: Icon(Icons.timer_outlined),
                    ),
                    validator: (value) {
                      final duration = int.tryParse(value ?? '');
                      if (duration == null || duration <= 0) {
                        return 'Enter duration in minutes';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: noteController,
                    decoration: const InputDecoration(
                      labelText: 'Note (optional)',
                      prefixIcon: Icon(Icons.notes_rounded),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(dialogContext, {
                    'distance':
                        double.parse(distanceController.text.trim()),
                    'duration':
                        int.parse(durationController.text.trim()),
                    'note': noteController.text.trim(),
                  });
                }
              },
              child: const Text('Save ride'),
            ),
          ],
        ),
      );

      if (result == null || !context.mounted) return;

      await onAddRide(
        RideRecord(
          id: DateTime.now().microsecondsSinceEpoch,
          motorcycleId: bike.id,
          date: DateTime.now(),
          distanceKm: result['distance'] as double,
          durationMinutes: result['duration'] as int,
          note: result['note'] as String,
        ),
      );
    } finally {
      distanceController.dispose();
      durationController.dispose();
      noteController.dispose();
    }
  }
}

class _MotorcycleHero extends StatelessWidget {
  const _MotorcycleHero({
    required this.motorcycle,
    required this.onGarage,
    required this.onStartRide,
  });

  final Motorcycle? motorcycle;
  final VoidCallback onGarage;
  final VoidCallback onStartRide;

  @override
  Widget build(BuildContext context) {
    final bike = motorcycle;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF303235),
            Color(0xFF191A1C),
            Color(0xFF151617),
          ],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.circle,
                color: AppTheme.orange,
                size: 8,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'ACTIVE MOTORCYCLE',
                  style: TextStyle(
                    color: AppTheme.muted,
                    letterSpacing: 1.7,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                onPressed: onGarage,
                tooltip: 'Manage garage',
                visualDensity: VisualDensity.compact,
                icon: const Icon(
                  Icons.tune_rounded,
                  color: AppTheme.muted,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Container(
            height: 112,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(17),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: 8,
                  bottom: -18,
                  child: Icon(
                    Icons.two_wheeler_rounded,
                    size: 142,
                    color: AppTheme.orange.withValues(alpha: 0.13),
                  ),
                ),
                Positioned(
                  left: 15,
                  top: 17,
                  child: Icon(
                    Icons.two_wheeler_rounded,
                    size: 70,
                    color: AppTheme.orange.withValues(alpha: 0.95),
                  ),
                ),
                Positioned(
                  right: 14,
                  top: 14,
                  child: Text(
                    'RS / 01',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.3),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          Text(
            bike?.displayName ?? 'No motorcycle yet',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.w900,
              height: 1.1,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 7),

          Text(
            bike == null
                ? 'Add your motorcycle to start your journey.'
                : '${bike.year}  •  ${bike.engineCc.isEmpty ? 'Engine size not set' : '${bike.engineCc} cc'}',
            style: const TextStyle(
              color: AppTheme.muted,
              fontSize: 12,
            ),
          ),

          const SizedBox(height: 20),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.08)),
          const SizedBox(height: 17),

          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TOTAL ODOMETER',
                      style: TextStyle(
                        color: AppTheme.muted,
                        fontSize: 9,
                        letterSpacing: 1.4,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Flexible(
                          child: Text(
                            (bike?.odometerKm ?? 0).toStringAsFixed(1),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.7,
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),
                        const Text(
                          'KM',
                          style: TextStyle(
                            color: AppTheme.orange,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              FilledButton.icon(
                onPressed: bike == null ? onGarage : onStartRide,
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.orange,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 13,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: Icon(
                  bike == null
                      ? Icons.add_rounded
                      : Icons.play_arrow_rounded,
                  size: 21,
                ),
                label: Text(
                  bike == null ? 'Add bike' : 'START RIDE',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.045),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.orange, size: 21),
          const SizedBox(height: 14),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 21,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            maxLines: 2,
            style: const TextStyle(
              color: AppTheme.muted,
              fontSize: 9,
              letterSpacing: 0.7,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 13,
            vertical: 17,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.05),
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppTheme.orange, size: 21),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppTheme.muted,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RideTile extends StatelessWidget {
  const _RideTile({required this.ride});

  final RideRecord ride;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.04),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: AppTheme.surfaceRaised,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.route_rounded,
              color: AppTheme.orange,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ride.note.isEmpty ? 'Ride record' : ride.note,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 5),
                Text(
                  '${ride.date.day}/${ride.date.month}/${ride.date.year}  •  ${ride.durationMinutes} min',
                  style: const TextStyle(
                    color: AppTheme.muted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${ride.distanceKm.toStringAsFixed(1)} km',
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: AppTheme.orange,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.orange.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 29, color: AppTheme.orange),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.muted,
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w900,
          ),
    );
  }
}