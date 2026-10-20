
import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../models/motorcycle.dart';
import '../models/ride.dart';

class RidesScreen extends StatelessWidget {
  const RidesScreen({
    super.key,
    required this.rides,
    required this.motorcycles,
  });

  final List<RideRecord> rides;
  final List<Motorcycle> motorcycles;

  String _bikeName(int id) {
    for (final bike in motorcycles) {
      if (bike.id == id) return bike.displayName;
    }
    return 'Motorcycle';
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];

    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatTime(DateTime? time) {
    if (time == null) return '--:--';

    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';

    return '$hour:$minute $period';
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) return '$minutes min';

    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;

    if (remainingMinutes == 0) return '${hours}h';
    return '${hours}h ${remainingMinutes}m';
  }

  @override
  Widget build(BuildContext context) {
    final sortedRides = [...rides]
      ..sort((a, b) => b.date.compareTo(a.date));

    final distance = rides.fold<double>(
      0,
      (sum, ride) => sum + ride.distanceKm,
    );

    final minutes = rides.fold<int>(
      0,
      (sum, ride) => sum + ride.durationMinutes,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 32),
      children: [
        const Text(
          'YOUR JOURNEY',
          style: TextStyle(
            color: AppTheme.orange,
            letterSpacing: 2.2,
            fontWeight: FontWeight.w900,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Ride history',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Every kilometer has a story.',
          style: TextStyle(color: AppTheme.muted),
        ),
        const SizedBox(height: 22),

        Row(
          children: [
            Expanded(
              child: _Summary(
                label: 'TOTAL DISTANCE',
                value: '${distance.toStringAsFixed(1)} km',
                icon: Icons.route_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _Summary(
                label: 'TIME ON ROAD',
                value: '${(minutes / 60).toStringAsFixed(1)} hr',
                icon: Icons.timer_outlined,
              ),
            ),
          ],
        ),

        const SizedBox(height: 28),

        Row(
          children: [
            const Expanded(
              child: Text(
                'Recent rides',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Text(
              '${rides.length} ${rides.length == 1 ? 'RIDE' : 'RIDES'}',
              style: const TextStyle(
                color: AppTheme.muted,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        if (sortedRides.isEmpty)
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Column(
              children: [
                Icon(
                  Icons.route_rounded,
                  size: 46,
                  color: AppTheme.orange,
                ),
                SizedBox(height: 12),
                Text(
                  'Your story starts here',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Finish your first tracked ride and it will appear here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.muted,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          )
        else
          ...sortedRides.map((ride) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppTheme.surfaceRaised.withValues(alpha: 0.65),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceRaised,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.two_wheeler_rounded,
                          color: AppTheme.orange,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ride.note.isEmpty
                                  ? _bikeName(ride.motorcycleId)
                                  : ride.note,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              _bikeName(ride.motorcycleId),
                              style: const TextStyle(
                                color: AppTheme.muted,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              _formatDate(ride.date),
                              style: const TextStyle(
                                color: AppTheme.muted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${ride.distanceKm.toStringAsFixed(1)}',
                            style: const TextStyle(
                              color: AppTheme.orange,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const Text(
                            'KILOMETERS',
                            style: TextStyle(
                              color: AppTheme.muted,
                              fontSize: 9,
                              letterSpacing: 0.6,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  Divider(
                    height: 1,
                    color: AppTheme.surfaceRaised.withValues(alpha: 0.8),
                  ),
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        child: _RideDetail(
                          icon: Icons.play_arrow_rounded,
                          label: 'START',
                          value: _formatTime(ride.startTime),
                        ),
                      ),
                      Expanded(
                        child: _RideDetail(
                          icon: Icons.flag_outlined,
                          label: 'END',
                          value: _formatTime(ride.endTime),
                        ),
                      ),
                      Expanded(
                        child: _RideDetail(
                          icon: Icons.timer_outlined,
                          label: 'DURATION',
                          value: _formatDuration(ride.durationMinutes),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }
}

class _RideDetail extends StatelessWidget {
  const _RideDetail({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: AppTheme.orange),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppTheme.muted,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.orange),
          const SizedBox(height: 14),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.muted,
              fontSize: 9,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}
