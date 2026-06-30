import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:sand_bike_sim/antigravity/telemetry_pipeline.dart';

class GhostRider {
  double targetSpeed = 0.0;
  double tractionMultiplier = 1.0;
  double torqueMultiplier = 1.0;

  void updateAI(TelemetryData playerData, Vector2 ghostPosition) {
    double playerAvgVelocityX = playerData.velocity.x;
    double playerDistance = playerData.position.x;
    double ghostDistance = ghostPosition.x;

    // Rubber-banding heuristic for the 24-hour MVP
    if (playerDistance > ghostDistance + 5.0) {
      // Player is ahead, GhostRider catches up (simulating a learning opponent)
      tractionMultiplier = 1.2;
      torqueMultiplier = 1.5;
      targetSpeed = playerAvgVelocityX * 1.3;
    } else if (ghostDistance > playerDistance + 5.0) {
      // GhostRider is too far ahead, slows down
      tractionMultiplier = 0.9;
      torqueMultiplier = 0.8;
      targetSpeed = playerAvgVelocityX * 0.8;
    } else {
      // Match player
      tractionMultiplier = 1.0;
      torqueMultiplier = 1.0;
      targetSpeed = playerAvgVelocityX;
    }
  }
}

class SmartRivalAi {
  final GhostRider ghostRider = GhostRider();
  
  // We need the ghost's position to compare, which will be updated by the game loop
  Vector2 currentGhostPosition = Vector2.zero();

  void processOpponentData(TelemetryData data) {
    ghostRider.updateAI(data, currentGhostPosition);
  }
}
