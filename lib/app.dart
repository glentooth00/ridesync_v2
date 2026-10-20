
import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'models/motorcycle.dart';
import 'models/ride.dart';
import 'screens/main_shell.dart';
import 'services/app_storage.dart';

class RideSyncApp extends StatefulWidget {
  const RideSyncApp({super.key});

  @override
  State<RideSyncApp> createState() => _RideSyncAppState();
}

class _RideSyncAppState extends State<RideSyncApp> {
  bool _loading = true;
  String? _startupError;

  List<Motorcycle> _motorcycles = [];
  List<RideRecord> _rides = [];
  int _selectedMotorcycleId = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final motorcycles = await AppStorage.loadMotorcycles();
      final rides = await AppStorage.loadRides();
      final selectedId = await AppStorage.loadSelectedMotorcycleId();

      if (!mounted) return;

      setState(() {
        _motorcycles = motorcycles;
        _rides = rides;
        _selectedMotorcycleId = selectedId;
        _loading = false;
        _startupError = null;
      });
    } catch (error, stackTrace) {
      debugPrint('RideSync startup error: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      setState(() {
        _loading = false;
        _startupError = error.toString();
      });
    }
  }

  Future<void> _saveMotorcycles() async {
    await AppStorage.saveMotorcycles(_motorcycles);
    await AppStorage.saveSelectedMotorcycleId(_selectedMotorcycleId);
  }

  Future<void> _addMotorcycle(Motorcycle motorcycle) async {
    setState(() {
      _motorcycles = [..._motorcycles, motorcycle];
      _selectedMotorcycleId = motorcycle.id;
    });
    await _saveMotorcycles();
  }

  Future<void> _updateMotorcycle(Motorcycle motorcycle) async {
    setState(() {
      _motorcycles = _motorcycles
          .map((item) => item.id == motorcycle.id ? motorcycle : item)
          .toList();
    });
    await _saveMotorcycles();
  }

  Future<void> _selectMotorcycle(int id) async {
    setState(() => _selectedMotorcycleId = id);
    await AppStorage.saveSelectedMotorcycleId(id);
  }

  Future<void> _addRide(RideRecord ride) async {
    setState(() => _rides = [ride, ..._rides]);
    await AppStorage.saveRides(_rides);
  }

  Future<void> _refreshRides() async {
  final rides = await AppStorage.loadRides();

  if (!mounted) return;

  setState(() {
    _rides = rides;
  });
}

  Future<void> _clearLocalData() async {
    await AppStorage.clearAll();

    if (!mounted) return;

    setState(() {
      _motorcycles = [];
      _rides = [];
      _selectedMotorcycleId = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RideSync',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: _loading
          ? const _LoadingScreen()
          : _startupError != null
              ? _StartupErrorScreen(
                  error: _startupError!,
                  onRetry: _load,
                )
              : MainShell(
                  motorcycles: _motorcycles,
                  rides: _rides,
                  selectedMotorcycleId: _selectedMotorcycleId,
                  onAddMotorcycle: _addMotorcycle,
                  onUpdateMotorcycle: _updateMotorcycle,
                  onSelectMotorcycle: _selectMotorcycle,
                  onAddRide: _addRide,
                  onClearLocalData: _clearLocalData,
                  onRefreshRides: _refreshRides,
                ),
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.two_wheeler,
              size: 54,
              color: Color(0xFFFF6B1A),
            ),
            SizedBox(height: 14),
            Text(
              'RIDESYNC',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                letterSpacing: 3,
              ),
            ),
            SizedBox(height: 12),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

class _StartupErrorScreen extends StatelessWidget {
  const _StartupErrorScreen({
    required this.error,
    required this.onRetry,
  });

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  size: 56,
                  color: Color(0xFFFF6B1A),
                ),
                const SizedBox(height: 16),
                const Text(
                  'RIDESYNC COULD NOT START',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'A startup error occurred. Your saved data has not '
                  'been intentionally cleared.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                SelectableText(
                  error,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}