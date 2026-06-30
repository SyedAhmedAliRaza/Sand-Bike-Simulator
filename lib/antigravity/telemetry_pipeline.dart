import 'dart:async';
import 'package:flame_forge2d/flame_forge2d.dart';

class TelemetryData {
  final double throttle;
  final double tiltAngle;
  final double airTime;
  final Vector2 position;
  final Vector2 velocity;
  final bool hasCrashed;
  final double timestamp;

  TelemetryData({
    required this.throttle,
    required this.tiltAngle,
    required this.airTime,
    required this.position,
    required this.velocity,
    required this.hasCrashed,
    required this.timestamp,
  });
}

class TelemetryPipeline {
  final _controller = StreamController<TelemetryData>.broadcast();
  
  Stream<TelemetryData> get stream => _controller.stream;

  // Decoupled tick rate timer
  Timer? _tickTimer;
  
  // Cache the latest metrics to send on ticks
  TelemetryData? _latestData;

  TelemetryPipeline() {
    // 10 Hz telemetry tick to Antigravity backend
    _tickTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_latestData != null) {
        _controller.add(_latestData!);
      }
    });
  }

  void updateMetrics(TelemetryData data) {
    _latestData = data;
  }

  void dispose() {
    _tickTimer?.cancel();
    _controller.close();
  }
}
