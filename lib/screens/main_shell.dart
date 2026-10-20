
import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../models/motorcycle.dart';
import '../models/ride.dart';
import 'garage_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'rides_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({
    super.key,
    required this.motorcycles,
    required this.rides,
    required this.selectedMotorcycleId,
    required this.onAddMotorcycle,
    required this.onUpdateMotorcycle,
    required this.onSelectMotorcycle,
    required this.onAddRide,
    required this.onRefreshRides,
    required this.onClearLocalData,
  });

  final List<Motorcycle> motorcycles;
  final List<RideRecord> rides;
  final int selectedMotorcycleId;

  final Future<void> Function(Motorcycle) onAddMotorcycle;
  final Future<void> Function(Motorcycle) onUpdateMotorcycle;
  final Future<void> Function(int) onSelectMotorcycle;
  final Future<void> Function(RideRecord) onAddRide;
  final Future<void> Function() onRefreshRides;
  final Future<void> Function() onClearLocalData;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final selected = widget.motorcycles
        .where((motorcycle) =>
            motorcycle.id == widget.selectedMotorcycleId)
        .firstOrNull;

    final pages = [
      HomeScreen(
        motorcycles: widget.motorcycles,
        rides: widget.rides,
        selectedMotorcycle: selected,
        onGoToGarage: () => setState(() => _index = 1),
        onAddRide: widget.onAddRide,
        onRefreshRides: widget.onRefreshRides,
      ),
      GarageScreen(
        motorcycles: widget.motorcycles,
        selectedMotorcycleId: widget.selectedMotorcycleId,
        onAddMotorcycle: widget.onAddMotorcycle,
        onUpdateMotorcycle: widget.onUpdateMotorcycle,
        onSelectMotorcycle: widget.onSelectMotorcycle,
      ),
      RidesScreen(
        rides: widget.rides,
        motorcycles: widget.motorcycles,
      ),
      ProfileScreen(
        onClearLocalData: widget.onClearLocalData,
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: IndexedStack(
          index: _index,
          children: pages,
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) {
          setState(() => _index = value);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.two_wheeler_outlined),
            selectedIcon: Icon(Icons.two_wheeler),
            label: 'Garage',
          ),
          NavigationDestination(
            icon: Icon(Icons.route_outlined),
            selectedIcon: Icon(Icons.route),
            label: 'Rides',
          ),
          NavigationDestination(
            icon: Icon(Icons.tune_outlined),
            selectedIcon: Icon(Icons.tune),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

extension FirstOrNullExtension<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(
    this.title, {
    super.key,
    this.action,
    this.onAction,
  });

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
          ),
          if (action != null)
            TextButton(
              onPressed: onAction,
              child: Text(
                action!,
                style: const TextStyle(color: AppTheme.orange),
              ),
            ),
        ],
      );
}
