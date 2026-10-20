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
  List<Motorcycle> _motorcycles = [];
  List<RideRecord> _rides = [];
  int _selectedMotorcycleId = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final motorcycles = await AppStorage.loadMotorcycles();
    final rides = await AppStorage.loadRides();
    final selectedId = await AppStorage.loadSelectedMotorcycleId();

    if (!mounted) return;
    setState(() {
      _motorcycles = motorcycles;
      _rides = rides;
      _selectedMotorcycleId = selectedId;
      _loading = false;
    });
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
          : MainShell(
              motorcycles: _motorcycles,
              rides: _rides,
              selectedMotorcycleId: _selectedMotorcycleId,
              onAddMotorcycle: _addMotorcycle,
              onUpdateMotorcycle: _updateMotorcycle,
              onSelectMotorcycle: _selectMotorcycle,
              onAddRide: _addRide,
              onClearLocalData: _clearLocalData,
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
            Icon(Icons.two_wheeler, size: 54, color: Color(0xFFFF6B1A)),
            SizedBox(height: 14),
            Text('RIDESYNC', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 3)),
            SizedBox(height: 12),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
