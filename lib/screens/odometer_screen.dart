import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:async';
import 'dart:math' as math;
import '../models/ride.dart';
import '../services/app_storage.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class OdometerScreen extends StatefulWidget {
  const OdometerScreen({
    super.key,
    this.motorcycleId = 0,
    this.motorcycleName = 'My Motorcycle',
    this.year = '2024',
    this.engineCc = 150,
    this.odometerKm = 0,
    this.speedKmh = 0,
    this.onEndRide,
  });

  final int motorcycleId;
  final String motorcycleName;
  final String year;
  final int engineCc;
  final double odometerKm;
  final double speedKmh;
  final VoidCallback? onEndRide;

  @override
  State<OdometerScreen> createState() => _OdometerScreenState();
}

class _OdometerScreenState extends State<OdometerScreen> {
  static const Color background = Color(0xFF101112);
  static const Color panel = Color(0xFF1B1D1F);
  static const Color orange = Color(0xFFFF6B24);
  static const Color muted = Color(0xFF85898D);
  static const Color green = Color(0xFF65E6A5);

  bool _rideActive = false;
  bool _startingRide = false;
  bool _gpsReady = false;

  String _gpsStatus = 'GPS STANDBY';

  double _speedKmh = 0;
  double _travelDistanceMeters = 0;

  Position? _lastPosition;
  DateTime? _rideStartedAt;
  Duration _elapsed = Duration.zero;

  Timer? _rideTimer;
  StreamSubscription<Position>? _positionSubscription;

  // Right-side panel: 0 = Motorcycle, 1 = Map.
  int _selectedPane = 0;

  final MapController _mapController = MapController();

  bool _mapReady = false;
  bool _mapLoading = false;
  String? _mapMessage;

  Position? _currentPosition;
  StreamSubscription<Position>? _mapSubscription;

  final List<LatLng> _routePoints = [];

  @override
  void initState() {
    super.initState();
    _enterOdometerMode();
  }

  Widget _buildMapPanel() {
  final position = _currentPosition;

  final currentPoint = position == null
      ? const LatLng(12.8797, 121.7740)
      : LatLng(position.latitude, position.longitude);

  return ClipRRect(
    borderRadius: BorderRadius.circular(14),
    child: Stack(
      children: [
        Positioned.fill(
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: currentPoint,
              initialZoom: position == null ? 5 : 16,
              onMapReady: () {
                _mapReady = true;

                final latestPosition = _currentPosition;

                if (latestPosition != null) {
                  _moveMapTo(latestPosition);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                // Replace this with your app's actual Android application ID.
                userAgentPackageName: 'com.ridesync.app',
              ),

              if (_routePoints.length >= 2)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: List<LatLng>.unmodifiable(_routePoints),
                      strokeWidth: 4,
                      color: orange,
                    ),
                  ],
                ),

              if (position != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: currentPoint,
                      width: 42,
                      height: 42,
                      child: Container(
                        decoration: BoxDecoration(
                          color: orange,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.navigation_rounded,
                          color: Colors.black,
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),

        // Map information badge.
        Positioned(
          top: 10,
          left: 10,
          right: 10,
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xEE101112),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        position == null
                            ? Icons.location_searching_rounded
                            : Icons.my_location_rounded,
                        color: position == null ? muted : green,
                        size: 17,
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          position == null
                              ? 'WAITING FOR LOCATION'
                              : 'GPS LOCATION LOCKED',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 7),
              Material(
                color: const Color(0xEE101112),
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () {
                    if (position != null) {
                      _moveMapTo(position);
                    } else {
                      _startMapLocation();
                    }
                  },
                  child: const SizedBox(
                    width: 39,
                    height: 39,
                    child: Icon(
                      Icons.my_location_rounded,
                      color: orange,
                      size: 19,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Trip distance badge.
        Positioned(
          left: 10,
          bottom: 10,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 9,
            ),
            decoration: BoxDecoration(
              color: const Color(0xEE101112),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: orange.withValues(alpha: 0.35),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'TRIP DISTANCE',
                  style: TextStyle(
                    color: muted,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$_travelDistanceKm km',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),

        if (_mapMessage != null)
  Positioned(
    left: 10,
    right: 10,
    bottom: 80,
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xF01B1D1F),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _mapMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            children: [
              TextButton.icon(
                onPressed: _mapLoading
                    ? null
                    : _startMapLocation,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('RETRY'),
                style: TextButton.styleFrom(
                  foregroundColor: orange,
                ),
              ),
              TextButton(
                onPressed: () async {
                  await Geolocator.openLocationSettings();
                },
                child: const Text(
                  'LOCATION SETTINGS',
                  style: TextStyle(color: Colors.white70, fontSize: 10),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  ),
      ],
    ),
  );
}

  Future<void> _enterOdometerMode() async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    await WakelockPlus.enable();
  }

  Future<void> _restoreScreenMode() async {
    await WakelockPlus.disable();

    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  Future<void> _startRide() async {
    if (_rideActive || _startingRide) return;

    setState(() {
      _startingRide = true;
      _gpsStatus = 'CHECKING GPS';
    });

    try {
      var permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (!mounted) return;

      if (permission == LocationPermission.denied) {
        await _showMessage(
          'Location permission is required to display live speed '
          'and calculate travel distance.',
        );
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        await _showMessage(
          'Location access is blocked. Open app settings and allow '
          'location permission to use ride tracking.',
          settings: true,
        );
        return;
      }

      final serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!mounted) return;

      if (!serviceEnabled) {
        await _showMessage(
          'Your phone GPS is turned off. Enable Location Services '
          'before starting your ride.',
          locationSettings: true,
        );
        return;
      }

      await _positionSubscription?.cancel();
      await _mapSubscription?.cancel();

      _positionSubscription = null;
      _mapSubscription = null;

      // Start a fresh trip and route.
      _lastPosition = null;
      _travelDistanceMeters = 0;
      _routePoints.clear();

      final locationSettings = AndroidSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 1,
        intervalDuration: const Duration(seconds: 1),
      );

      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
        _handlePosition,
        onError: (Object error) {
          if (!mounted) return;

          setState(() {
            _gpsReady = false;
            _gpsStatus = 'GPS ERROR';
            _speedKmh = 0;
          });

          _showMessage(
            'GPS updates are unavailable. Check your location settings '
            'and try again.',
          );
        },
      );

      setState(() {
        _rideActive = true;
        _gpsReady = false;
        _speedKmh = 0;
        _gpsStatus = 'WAITING FOR GPS';
        _rideStartedAt = DateTime.now();
        _elapsed = Duration.zero;
      });

      _rideTimer?.cancel();
      _rideTimer = Timer.periodic(
        const Duration(seconds: 1),
        (_) {
          if (!mounted || _rideStartedAt == null) return;

          setState(() {
            _elapsed = DateTime.now().difference(_rideStartedAt!);
          });
        },
      );
    } catch (error) {
      if (mounted) {
        await _showMessage(
          'Unable to start GPS tracking. Please try again.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _startingRide = false);
      }
    }
  }

void _handlePosition(Position position) {
  if (!mounted || !_rideActive) return;

  final rawSpeed = position.speed;

  final speed = rawSpeed.isFinite
      ? (rawSpeed * 3.6).clamp(0.0, 999.0).toDouble()
      : 0.0;

  final point = LatLng(
    position.latitude,
    position.longitude,
  );

  final previous = _lastPosition;

  if (previous != null) {
    final distance = Geolocator.distanceBetween(
      previous.latitude,
      previous.longitude,
      position.latitude,
      position.longitude,
    );

    // Filter out GPS drift and implausible location jumps.
    if (distance.isFinite && distance >= 1.5 && distance <= 100) {
      _travelDistanceMeters += distance;
      _routePoints.add(point);
    }
  } else {
    _routePoints.add(point);
  }

  _lastPosition = position;
  _currentPosition = position;

  setState(() {
    _speedKmh = speed;
    _gpsReady = true;
    _gpsStatus = 'GPS CONNECTED';
  });

  if (_mapReady && _selectedPane == 1) {
    _moveMapTo(position);
  }
}

Future<void> _selectPane(int index) async {
  if (!mounted || _selectedPane == index) return;

  setState(() {
    _selectedPane = index;
  });

  if (index == 1) {
    await _startMapLocation();
  } else if (!_rideActive) {
    await _mapSubscription?.cancel();
    _mapSubscription = null;
  }
}

Future<void> _startMapLocation() async {
  if (_mapLoading) return;

  if (_rideActive) {
    final position = _currentPosition;

    if (_mapReady && position != null) {
      _moveMapTo(position);
    }
    return;
  }

  setState(() {
    _mapLoading = true;
    _mapMessage = 'Checking location services...';
  });

  try {
    // Check app permission first.
    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (!mounted) return;

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      setState(() {
        _mapMessage = permission == LocationPermission.deniedForever
            ? 'Location permission is blocked. Open app settings and allow location.'
            : 'Location permission is required to show your position.';
      });
      return;
    }

    // Recheck Android's location service.
    var serviceEnabled =
        await Geolocator.isLocationServiceEnabled();

    if (!mounted) return;

    if (!serviceEnabled) {
      setState(() {
        _mapMessage =
            'Android reports that Location Services are off. '
            'Check your phone settings, then tap Retry.';
      });
      return;
    }

    // Get a fresh GPS fix instead of relying only on a cached location.
    setState(() {
      _mapMessage = 'Getting your current location...';
    });

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );

    if (!mounted) return;

    _handleMapPosition(position);

    // Start ongoing map updates.
    await _mapSubscription?.cancel();

    _mapSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen(
      _handleMapPosition,
      onError: (Object error) {
        if (!mounted) return;

        setState(() {
          _mapMessage = 'GPS updates failed. Tap Retry to reconnect.';
        });
      },
    );
  } catch (error) {
    if (!mounted) return;

    setState(() {
      _mapMessage =
          'Could not get a GPS fix. Move outdoors and try again.';
    });
  } finally {
    if (mounted) {
      setState(() {
        _mapLoading = false;
      });
    }
  }
}

  void _handleMapPosition(Position position) {
    if (!mounted) return;

    _currentPosition = position;

    setState(() {
      _mapMessage = null;
    });

    if (_mapReady && _selectedPane == 1) {
      _moveMapTo(position);
    }
  }

  void _moveMapTo(Position position) {
    try {
      _mapController.move(
        LatLng(position.latitude, position.longitude),
        16,
      );
    } catch (_) {
      // The map controller might not be attached yet.
    }
  }

  Future<void> _showMessage(
    String message, {
    bool settings = false,
    bool locationSettings = false,
  }) async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: panel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: const Text(
          'GPS REQUIRED',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
        content: Text(
          message,
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              'CLOSE',
              style: TextStyle(color: muted),
            ),
          ),
          if (settings || locationSettings)
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);

                if (settings) {
                  await Geolocator.openAppSettings();
                } else {
                  await Geolocator.openLocationSettings();
                }
              },
              child: const Text(
                'OPEN SETTINGS',
                style: TextStyle(
                  color: orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }


Future<void> _endRide() async {
  if (!_rideActive) return;

  final endedAt = DateTime.now();
  final startedAt = _rideStartedAt;

  final elapsed = startedAt != null
      ? endedAt.difference(startedAt)
      : _elapsed;

  final distanceKm = _travelDistanceMeters / 1000;

  _rideTimer?.cancel();
  _rideTimer = null;

  await _positionSubscription?.cancel();
  _positionSubscription = null;

  await _mapSubscription?.cancel();
  _mapSubscription = null;

  // Save this ride against the motorcycle that was used.
  bool saved = false;

  if (startedAt != null && widget.motorcycleId > 0) {
    try {
      final ride = RideRecord(
        id: DateTime.now().microsecondsSinceEpoch,
        motorcycleId: widget.motorcycleId,
        date: startedAt,
        startTime: startedAt,
        endTime: endedAt,
        distanceKm: distanceKm,
        durationMinutes: elapsed.inMinutes,
      );

      final rides = await AppStorage.loadRides();
      rides.add(ride);
      await AppStorage.saveRides(rides);

      saved = true;
    } catch (error) {
      debugPrint('Failed to save ride history: $error');
    }
  }

  if (!mounted) return;

  setState(() {
    _rideActive = false;
    _gpsReady = false;
    _gpsStatus = 'GPS STANDBY';
    _speedKmh = 0;
    _elapsed = elapsed;
    _rideStartedAt = null;
    _lastPosition = null;
  });

  if (saved) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ride saved to your ride history.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.motorcycleId <= 0
              ? 'Ride ended, but no motorcycle ID was provided.'
              : 'Ride ended, but the history could not be saved.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  widget.onEndRide?.call();

  if (mounted && _selectedPane == 1) {
    await _startMapLocation();
  }
}


  @override
  void dispose() {
    _rideTimer?.cancel();
    _positionSubscription?.cancel();
    _mapSubscription?.cancel();

    unawaited(_restoreScreenMode());

    super.dispose();
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');

    return '$hours:$minutes:$seconds';
  }

  String get _travelDistanceKm =>
      (_travelDistanceMeters / 1000).toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          unawaited(_restoreScreenMode());
        }
      },
      child: Scaffold(
        backgroundColor: background,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final height = constraints.maxHeight;

              // Retain the split landscape layout on phones and tablets.
              // Use a compact layout when the available width is narrow.
              final compactWidth = width < 720;
              final compactHeight = height < 390;

              return Row(
                children: [
                  Expanded(
                    flex: compactWidth ? 5 : 6,
                    child: _buildSpeedPanel(
                      height: height,
                      compactWidth: compactWidth,
                      compactHeight: compactHeight,
                    ),
                  ),
                  Container(
                    width: 1,
                    margin: EdgeInsets.symmetric(
                      vertical: compactHeight ? 8 : 20,
                    ),
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                  Expanded(
                    flex: compactWidth ? 5 : 4,
                    child: _buildDetailsPanel(
                      compactWidth: compactWidth,
                      compactHeight: compactHeight,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSpeedPanel({
    required double height,
    required bool compactWidth,
    required bool compactHeight,
  }) {
    final horizontalPadding = compactWidth ? 10.0 : 20.0;
    final verticalPadding = compactHeight ? 5.0 : 12.0;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        verticalPadding,
        compactWidth ? 8 : 18,
        verticalPadding,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.two_wheeler_rounded,
                color: orange,
                size: compactWidth ? 19 : 25,
              ),
              SizedBox(width: compactWidth ? 4 : 9),
              Text(
                'RIDE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: compactWidth ? 13 : 17,
                  fontWeight: FontWeight.w900,
                  letterSpacing: compactWidth ? 1 : 2,
                ),
              ),
              Text(
                'SYNC',
                style: TextStyle(
                  color: orange,
                  fontSize: compactWidth ? 13 : 17,
                  fontWeight: FontWeight.w900,
                  letterSpacing: compactWidth ? 1 : 2,
                ),
              ),
              const Spacer(),
              Flexible(child: _gpsBadge(compact: compactWidth)),
            ],
          ),
          SizedBox(height: compactHeight ? 2 : 7),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'LIVE SPEEDOMETER',
              style: TextStyle(
                color: muted,
                fontSize: compactWidth ? 7 : 9,
                letterSpacing: compactWidth ? 1.3 : 2.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Reserve room for the trip-distance panel below the dial.
                final distanceHeight = compactHeight ? 43.0 : 53.0;
                final gap = compactHeight ? 3.0 : 7.0;

                final dialSize = math.max(
                  0.0,
                  math.min(
                    constraints.maxWidth,
                    constraints.maxHeight - distanceHeight - gap,
                  ),
                );

                return Column(
                  children: [
                    Expanded(
                      child: Center(
                        child: SizedBox.square(
                          dimension: dialSize,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CustomPaint(
                                size: Size.square(dialSize),
                                painter: _SpeedometerPainter(
                                  speed: _speedKmh,
                                ),
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(height: dialSize * 0.09),
                                  Text(
                                    _speedKmh
                                        .round()
                                        .toString()
                                        .padLeft(2, '0'),
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: dialSize * 0.19,
                                      fontWeight: FontWeight.w900,
                                      height: 1,
                                      letterSpacing: -2,
                                    ),
                                  ),
                                  SizedBox(height: compactHeight ? 2 : 5),
                                  Text(
                                    'KM/H',
                                    style: TextStyle(
                                      color: orange,
                                      fontSize: compactWidth ? 9 : 12,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: compactWidth ? 2 : 4,
                                    ),
                                  ),
                                  SizedBox(height: dialSize * 0.025),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: compactWidth ? 6 : 12,
                                      vertical: compactHeight ? 3 : 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.055,
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: Colors.white.withValues(
                                          alpha: 0.06,
                                        ),
                                      ),
                                    ),
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        'ODO  ${widget.odometerKm.toStringAsFixed(1)} KM',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: compactWidth ? 8 : 10,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: gap),
                    _buildDistanceCounter(
                      compactWidth: compactWidth,
                      compactHeight: compactHeight,
                      height: distanceHeight,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDistanceCounter({
    required bool compactWidth,
    required bool compactHeight,
    required double height,
  }) {
    return Container(
      height: height,
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: compactWidth ? 9 : 15,
        vertical: compactHeight ? 4 : 7,
      ),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: orange.withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.route_rounded,
            color: orange,
            size: compactWidth ? 17 : 21,
          ),
          SizedBox(width: compactWidth ? 6 : 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TRIP DISTANCE',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: muted,
                    fontSize: compactWidth ? 7 : 9,
                    letterSpacing: compactWidth ? 1 : 1.6,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  '$_travelDistanceKm km',
                  maxLines: 1,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: compactWidth ? 15 : 19,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
          if (!compactWidth)
            Text(
              _rideActive ? 'RECORDING' : 'READY',
              style: TextStyle(
                color: _rideActive ? green : muted,
                fontSize: 8,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
        ],
      ),
    );
  }

  Widget _gpsBadge({required bool compact}) {
    final color = _gpsReady
        ? green
        : (_startingRide || _rideActive ? orange : muted);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 5 : 10,
        vertical: compact ? 4 : 7,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _gpsReady ? Icons.gps_fixed_rounded : Icons.gps_not_fixed_rounded,
            color: color,
            size: compact ? 11 : 14,
          ),
          SizedBox(width: compact ? 3 : 6),
          Flexible(
            child: Text(
              _gpsStatus,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: compact ? 7 : 9,
                fontWeight: FontWeight.w900,
                letterSpacing: compact ? 0.2 : 0.8,
              ),
            ),
          ),
        ],
      ),
    );
  }

Widget _buildDetailsPanel({
  required bool compactWidth,
  required bool compactHeight,
}) {
  final horizontalPadding = compactWidth ? 8.0 : 16.0;
  final verticalPadding = compactHeight ? 4.0 : 12.0;

  return Padding(
    padding: EdgeInsets.fromLTRB(
      horizontalPadding,
      verticalPadding,
      compactWidth ? 8 : 20,
      verticalPadding,
    ),
    child: Column(
      children: [
        // Header.
        Row(
          children: [
            Expanded(
              child: Text(
                'RIDE CONTROL',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: muted,
                  fontSize: compactWidth ? 9 : 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: compactWidth ? 1 : 2,
                ),
              ),
            ),
            SizedBox(
              width: compactWidth ? 27 : 36,
              height: compactWidth ? 27 : 36,
              child: IconButton(
                tooltip: 'Close odometer',
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                onPressed: () => Navigator.of(context).maybePop(),
                icon: Icon(
                  Icons.close_rounded,
                  color: muted,
                  size: compactWidth ? 17 : 21,
                ),
              ),
            ),
          ],
        ),

        SizedBox(height: compactHeight ? 4 : 9),

        // Two tabs.
        Row(
          children: [
            Expanded(
              child: _paneTab(
                label: 'MOTORCYCLE',
                icon: Icons.two_wheeler_rounded,
                index: 0,
                compact: compactWidth,
              ),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: _paneTab(
                label: 'MAP',
                icon: Icons.map_outlined,
                index: 1,
                compact: compactWidth,
              ),
            ),
          ],
        ),

        SizedBox(height: compactHeight ? 5 : 10),

        // Keep both tabs mounted so the map doesn't need to be rebuilt
        // whenever the user switches back to the motorcycle tab.
        Expanded(
          child: IndexedStack(
            index: _selectedPane,
            children: [
              SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: _buildDetailsContent(
                  compactWidth: compactWidth,
                  compactHeight: true,
                  scrollable: true,
                ),
              ),

              // Build the map only when the Map tab is selected.
              _selectedPane == 1
                  ? _buildMapPanel()
                  : const SizedBox.expand(),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _paneTab({
  required String label,
  required IconData icon,
  required int index,
  required bool compact,
}) {
  final selected = _selectedPane == index;

  return Material(
    color: selected ? orange : panel,
    borderRadius: BorderRadius.circular(9),
    child: InkWell(
      borderRadius: BorderRadius.circular(9),
      onTap: () => _selectPane(index),
      child: Container(
        height: compact ? 34 : 41,
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 4 : 8,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: selected
                ? orange
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: compact ? 14 : 17,
              color: selected ? Colors.black : muted,
            ),
            SizedBox(width: compact ? 4 : 7),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? Colors.black : Colors.white70,
                  fontSize: compact ? 8 : 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: compact ? 0.3 : 0.8,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}


  Widget _buildDetailsContent({
    required bool compactWidth,
    required bool compactHeight,
    required bool scrollable,
  }) {
    final gap = compactHeight ? 4.0 : 10.0;

    final motorcycleCard = Container(
      width: double.infinity,
      constraints: BoxConstraints(
        minHeight: compactHeight ? 85 : 105,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF242628),
            Color(0xFF171819),
          ],
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.075),
        ),
      ),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned(
            right: -14,
            top: -18,
            child: Icon(
              Icons.two_wheeler_rounded,
              size: compactWidth ? 90 : 150,
              color: Colors.white.withValues(alpha: 0.045),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(compactHeight ? 9 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 38,
                  height: 3,
                  decoration: BoxDecoration(
                    color: orange,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                SizedBox(height: compactHeight ? 5 : 12),
                Text(
                  widget.motorcycleName.toUpperCase(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: compactWidth ? 15 : 21,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),
                SizedBox(height: compactHeight ? 4 : 8),
                Text(
                  '${widget.engineCc} CC  /  ${widget.year}',
                  style: TextStyle(
                    color: orange,
                    fontSize: compactWidth ? 9 : 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: compactWidth ? 0.8 : 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    final statsCard = Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: compactWidth ? 8 : 14,
        vertical: compactHeight ? 4 : 8,
      ),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.07),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _detailRow(
            Icons.speed_rounded,
            'TOTAL ODOMETER',
            '${widget.odometerKm.toStringAsFixed(1)} km',
            compact: compactWidth,
          ),
          _detailRow(
            Icons.timer_outlined,
            'RIDE TIME',
            _formatDuration(_elapsed),
            compact: compactWidth,
          ),
          _detailRow(
            Icons.route_rounded,
            'RIDE STATUS',
            _rideActive ? 'IN PROGRESS' : 'NOT STARTED',
            valueColor: _rideActive ? green : muted,
            compact: compactWidth,
          ),
        ],
      ),
    );

    final button = SizedBox(
      width: double.infinity,
      height: compactHeight ? 37 : 45,
      child: ElevatedButton.icon(
        onPressed: _startingRide
            ? null
            : (_rideActive ? _endRide : _startRide),
        style: ElevatedButton.styleFrom(
          backgroundColor:
              _rideActive ? const Color(0xFF292B2D) : orange,
          disabledBackgroundColor: const Color(0xFF3A302B),
          foregroundColor: _rideActive ? Colors.white : Colors.black,
          elevation: 0,
          padding: EdgeInsets.symmetric(
            horizontal: compactWidth ? 5 : 12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: _rideActive
                ? BorderSide(
                    color: Colors.white.withValues(alpha: 0.12),
                  )
                : BorderSide.none,
          ),
        ),
        icon: Icon(
          _startingRide
              ? Icons.hourglass_top_rounded
              : (_rideActive
                  ? Icons.stop_circle_outlined
                  : Icons.play_arrow_rounded),
          size: compactWidth ? 16 : 20,
        ),
        label: Flexible(
          child: Text(
            _startingRide
                ? 'CONNECTING GPS...'
                : (_rideActive ? 'END RIDE' : 'START RIDE'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: compactWidth ? 9 : 12,
              fontWeight: FontWeight.w900,
              letterSpacing: compactWidth ? 0.6 : 1.5,
            ),
          ),
        ),
      ),
    );

    if (scrollable) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _detailsHeader(compactWidth),
          SizedBox(height: gap),
          motorcycleCard,
          SizedBox(height: gap),
          statsCard,
          SizedBox(height: gap),
          button,
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _detailsHeader(compactWidth),
        SizedBox(height: compactHeight ? 1 : 3),
        Expanded(flex: 5, child: motorcycleCard),
        SizedBox(height: gap),
        Expanded(flex: 4, child: statsCard),
        SizedBox(height: gap),
        button,
      ],
    );
  }

  Widget _detailsHeader(bool compactWidth) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'ACTIVE MOTORCYCLE',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: muted,
              fontSize: compactWidth ? 8 : 10,
              letterSpacing: compactWidth ? 1 : 1.8,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(
          width: compactWidth ? 27 : 36,
          height: compactWidth ? 27 : 36,
          child: IconButton(
            tooltip: 'Close odometer',
            padding: EdgeInsets.zero,
            onPressed: () => Navigator.of(context).maybePop(),
            icon: Icon(
              Icons.close_rounded,
              color: muted,
              size: compactWidth ? 17 : 21,
            ),
            visualDensity: VisualDensity.compact,
          ),
        ),
      ],
    );
  }

  Widget _detailRow(
    IconData icon,
    String label,
    String value, {
    Color valueColor = Colors.white,
    bool compact = false,
  }) {
    final iconSize = compact ? 25.0 : 31.0;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: compact ? 2 : 3),
      child: Row(
        children: [
          Container(
            width: iconSize,
            height: iconSize,
            decoration: BoxDecoration(
              color: orange.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: orange,
              size: compact ? 14 : 17,
            ),
          ),
          SizedBox(width: compact ? 6 : 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: muted,
                    fontSize: compact ? 7 : 8,
                    letterSpacing: compact ? 0.4 : 1,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: compact ? 1 : 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: valueColor,
                    fontSize: compact ? 10 : 12,
                    fontWeight: FontWeight.w800,
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

class _SpeedometerPainter extends CustomPainter {
  const _SpeedometerPainter({required this.speed});

  final double speed;

  static const Color orange = Color(0xFFFF6B24);
  static const Color muted = Color(0xFF85898D);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.43;

    canvas.drawCircle(
      center,
      radius * 1.13,
      Paint()..color = const Color(0xFF1B1D1F),
    );

    canvas.drawCircle(
      center,
      radius * 1.13,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1, size.width * 0.004),
    );

    const startAngle = math.pi * 0.75;
    const sweepAngle = math.pi * 1.5;
    const maximumSpeed = 160.0;

    final arcRect = Rect.fromCircle(center: center, radius: radius);

    canvas.drawArc(
      arcRect,
      startAngle,
      sweepAngle,
      false,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.018
        ..strokeCap = StrokeCap.round,
    );

    final progress = speed.clamp(0.0, maximumSpeed) / maximumSpeed;

    if (progress > 0) {
      canvas.drawArc(
        arcRect,
        startAngle,
        sweepAngle * progress,
        false,
        Paint()
          ..color = orange
          ..style = PaintingStyle.stroke
          ..strokeWidth = size.width * 0.018
          ..strokeCap = StrokeCap.round,
      );
    }

    for (int i = 0; i <= 80; i++) {
      final angle = startAngle + sweepAngle * i / 80;
      final major = i % 10 == 0;
      final medium = i % 5 == 0;

      final outerRadius = radius * 0.88;
      final innerRadius =
          radius * (major ? 0.70 : medium ? 0.75 : 0.80);

      final start = Offset(
        center.dx + outerRadius * math.cos(angle),
        center.dy + outerRadius * math.sin(angle),
      );

      final end = Offset(
        center.dx + innerRadius * math.cos(angle),
        center.dy + innerRadius * math.sin(angle),
      );

      canvas.drawLine(
        start,
        end,
        Paint()
          ..color = major ? Colors.white : muted.withValues(alpha: 0.65)
          ..strokeWidth = major ? 2.2 : medium ? 1.4 : 0.8
          ..strokeCap = StrokeCap.round,
      );
    }

    for (int value = 0; value <= 160; value += 20) {
      final angle = startAngle + sweepAngle * value / maximumSpeed;
      final labelRadius = radius * 0.59;

      final position = Offset(
        center.dx + labelRadius * math.cos(angle),
        center.dy + labelRadius * math.sin(angle),
      );

      final painter = TextPainter(
        text: TextSpan(
          text: '$value',
          style: TextStyle(
            color: value == 0 ? orange : Colors.white,
            fontSize: size.width * 0.037,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      painter.paint(
        canvas,
        Offset(
          position.dx - painter.width / 2,
          position.dy - painter.height / 2,
        ),
      );
    }

    final needleAngle = startAngle + sweepAngle * progress;
    final needleLength = radius * 0.62;

    final needleTip = Offset(
      center.dx + needleLength * math.cos(needleAngle),
      center.dy + needleLength * math.sin(needleAngle),
    );

    canvas.drawLine(
      center,
      needleTip,
      Paint()
        ..color = orange
        ..strokeWidth = math.max(2, size.width * 0.008)
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawCircle(
      center,
      radius * 0.055,
      Paint()..color = Colors.white,
    );

    canvas.drawCircle(
      center,
      radius * 0.027,
      Paint()..color = orange,
    );
  }

  @override
  bool shouldRepaint(covariant _SpeedometerPainter oldDelegate) {
    return oldDelegate.speed != speed;
  }
}
