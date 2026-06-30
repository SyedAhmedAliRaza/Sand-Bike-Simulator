import 'package:sand_bike_sim/antigravity/telemetry_pipeline.dart';
import 'package:sand_bike_sim/antigravity/antigravity_core.dart';
import 'dart:async';

class PitBossAgent {
  final _messageController = StreamController<String>.broadcast();
  Stream<String> get messageStream => _messageController.stream;

  void analyze(TelemetryData data) {
    double playerDistance = data.position.x;
    double rivalDistance = AntigravityCore.instance.rivalAi.currentGhostPosition.x;
    
    if (data.hasCrashed || data.velocity.y < -30.0) {
      triggerExternalMessage("Watch the suspension! Ouch!");
    } else if (data.airTime > 1.5) {
      triggerExternalMessage("Massive air! Perfect rotation!");
    } else if (playerDistance < rivalDistance - 5.0) {
      triggerExternalMessage("Ghost is pulling ahead! Give it some throttle!");
    } else if (playerDistance > rivalDistance + 10.0) {
      triggerExternalMessage("You're smoking them! Keep it up!");
    }
  }

  void triggerExternalMessage(String msg) {
    _messageController.add(msg);
  }
}
