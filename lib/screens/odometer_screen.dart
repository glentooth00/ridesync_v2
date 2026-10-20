
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class OdometerScreen extends StatefulWidget {
  const OdometerScreen({
    super.key,
    this.motorcycleName = 'My Motorcycle',
    this.year = '2024',
    this.engineCc = 150,
    this.odometerKm = 0,
    this.speedKmh = 0,
    this.onEndRide,
  });

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
  DateTime? _rideStartedAt;
  Duration _elapsed = Duration.zero;
  Timer? _rideTimer;

  @override
  void initState() {
    super.initState();
    _enterLandscape();
  }

  Future<void> _enterLandscape() async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  Future<void> _restorePortrait() async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  void _startRide() {
    _rideTimer?.cancel();

    setState(() {
      _rideActive = true;
      _rideStartedAt = DateTime.now();
      _elapsed = Duration.zero;
    });

    _rideTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _rideStartedAt == null) return;

      setState(() {
        _elapsed = DateTime.now().difference(_rideStartedAt!);
      });
    });
  }

  void _endRide() {
    _rideTimer?.cancel();

    setState(() {
      _rideActive = false;
      if (_rideStartedAt != null) {
        _elapsed = DateTime.now().difference(_rideStartedAt!);
      }
      _rideStartedAt = null;
    });

    widget.onEndRide?.call();
  }

  @override
  void dispose() {
    _rideTimer?.cancel();
    _restorePortrait();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');

    return '$hours:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          _restorePortrait();
        }
      },
      child: Scaffold(
        backgroundColor: background,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Row(
                children: [
                  Expanded(
                    flex: 6,
                    child: _buildSpeedPanel(constraints.maxHeight),
                  ),
                  Container(
                    width: 1,
                    margin: const EdgeInsets.symmetric(vertical: 18),
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                  Expanded(
                    flex: 4,
                    child: _buildDetailsPanel(),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSpeedPanel(double availableHeight) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 14, 10),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.two_wheeler_rounded,
                color: orange,
                size: 25,
              ),
              const SizedBox(width: 9),
              const Text(
                'RIDE',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  fontSize: 17,
                ),
              ),
              const Text(
                'SYNC',
                style: TextStyle(
                  color: orange,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  fontSize: 17,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.gps_fixed_rounded,
                color: _rideActive ? green : muted,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                'GPS ${_rideActive ? 'READY' : 'STANDBY'}',
                style: TextStyle(
                  color: _rideActive ? green : muted,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'LIVE SPEEDOMETER',
              style: TextStyle(
                color: muted,
                fontSize: 9,
                letterSpacing: 2.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final dialSize = math.min(
                  constraints.maxWidth,
                  constraints.maxHeight,
                );

                return Center(
                  child: SizedBox.square(
                    dimension: dialSize,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CustomPaint(
                          size: Size.square(dialSize),
                          painter: _SpeedometerPainter(
                            speed: widget.speedKmh,
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(height: dialSize * 0.10),
                            Text(
                              widget.speedKmh
                                  .clamp(0, 999)
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
                            const SizedBox(height: 5),
                            const Text(
                              'KM/H',
                              style: TextStyle(
                                color: orange,
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 4,
                              ),
                            ),
                            SizedBox(height: dialSize * 0.045),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                'ODO  ${widget.odometerKm.toStringAsFixed(1)} KM',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsPanel() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 18, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'ACTIVE MOTORCYCLE',
                  style: TextStyle(
                    color: muted,
                    fontSize: 10,
                    letterSpacing: 2,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Close odometer',
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(
                  Icons.close_rounded,
                  color: muted,
                  size: 21,
                ),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Expanded(
            flex: 5,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: panel,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.07),
                ),
              ),
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  Positioned(
                    right: -15,
                    top: -20,
                    child: Icon(
                      Icons.two_wheeler_rounded,
                      size: 150,
                      color: Colors.white.withValues(alpha: 0.035),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 38,
                          height: 3,
                          color: orange,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          widget.motorcycleName.toUpperCase(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${widget.engineCc} CC  /  ${widget.year}',
                          style: const TextStyle(
                            color: orange,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            flex: 4,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: panel,
                borderRadius: BorderRadius.circular(14),
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
                  ),
                  _detailRow(
                    Icons.timer_outlined,
                    'RIDE TIME',
                    _formatDuration(_elapsed),
                  ),
                  _detailRow(
                    Icons.route_rounded,
                    'RIDE STATUS',
                    _rideActive ? 'IN PROGRESS' : 'NOT STARTED',
                    valueColor: _rideActive ? green : muted,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 43,
            child: ElevatedButton.icon(
              onPressed: _rideActive ? _endRide : _startRide,
              style: ElevatedButton.styleFrom(
                backgroundColor: _rideActive ? const Color(0xFF292B2D) : orange,
                foregroundColor: _rideActive ? Colors.white : Colors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9),
                  side: _rideActive
                      ? BorderSide(
                          color: Colors.white.withValues(alpha: 0.1),
                        )
                      : BorderSide.none,
                ),
              ),
              icon: Icon(
                _rideActive
                    ? Icons.stop_circle_outlined
                    : Icons.play_arrow_rounded,
                size: 20,
              ),
              label: Text(
                _rideActive ? 'END RIDE' : 'START RIDE',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(
    IconData icon,
    String label,
    String value, {
    Color valueColor = Colors.white,
  }) {
    return Row(
      children: [
        Icon(icon, color: orange, size: 17),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: muted,
                  fontSize: 8,
                  letterSpacing: 1,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: valueColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
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
        ..strokeWidth = 1.5,
    );

    const startAngle = math.pi * 0.75;
    const sweepAngle = math.pi * 1.5;
    const maximumSpeed = 160.0;

    final arcRect = Rect.fromCircle(
      center: center,
      radius: radius,
    );

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

    // Eighty intervals create fine ticks and larger marks every 20 km/h.
    for (int i = 0; i <= 80; i++) {
      final angle = startAngle + sweepAngle * i / 80;
      final major = i % 10 == 0;
      final medium = i % 5 == 0;

      final outerRadius = radius * 0.88;
      final innerRadius = radius * (major ? 0.70 : medium ? 0.75 : 0.80);

      final start = Offset(
        center.dx + outerRadius * math.cos(angle),
        center.dy + outerRadius * math.sin(angle),
      );

      final end = Offset(
        center.dx + innerRadius * math.cos(angle),
        center.dy + innerRadius * math.sin(angle),
      );

      final tickPaint = Paint()
        ..color = major ? Colors.white : muted.withValues(alpha: 0.65)
        ..strokeWidth = major ? 2.2 : medium ? 1.4 : 0.8
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(start, end, tickPaint);
    }

    // Numeric markings.
    for (int value = 0; value <= 160; value += 20) {
      final angle = startAngle + sweepAngle * value / maximumSpeed;
      final labelRadius = radius * 0.59;

      final position = Offset(
        center.dx + labelRadius * math.cos(angle),
        center.dy + labelRadius * math.sin(angle),
      );

      final textPainter = TextPainter(
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

      textPainter.paint(
        canvas,
        Offset(
          position.dx - textPainter.width / 2,
          position.dy - textPainter.height / 2,
        ),
      );
    }

    // Needle.
    final needleAngle =
        startAngle + sweepAngle * progress;
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
        ..strokeWidth = 3
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
