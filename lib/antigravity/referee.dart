import 'package:sand_bike_sim/antigravity/telemetry_pipeline.dart';
import 'dart:async';

class Referee {
  final _boostController = StreamController<double>.broadcast();
  Stream<double> get boostStream => _boostController.stream;

  void validate(TelemetryData data) {
    // Basic anti-spoofing logic for vibe-coding (mocked)
    if (data.velocity.length > 100) {
      print("[Antigravity Security] Velocity exceeds physical limits. Dropping telemetry.");
      return;
    }

    // Action-Feedback-Reward cycle: kinetic boosts for perfect landings
    if (data.airTime > 1.5 && data.tiltAngle.abs() < 0.1 && !data.hasCrashed) {
      // Perfect landing detected securely on backend
      _grantKineticBoost();
    }
  }

  void _grantKineticBoost() {
    print("[Antigravity Referee] Perfect Landing validated. Granting Kinetic Boost!");
    _boostController.add(50.0); // Adds 50 impulse units
  }
}
