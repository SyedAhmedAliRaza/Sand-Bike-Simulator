import 'package:fast_noise/fast_noise.dart';
import 'package:sand_bike_sim/antigravity/telemetry_pipeline.dart';
import 'dart:async';

class AgentMutationResponse {
  final double targetNoiseAmplitude;
  final double surfaceFrictionCoefficient;

  AgentMutationResponse(this.targetNoiseAmplitude, this.surfaceFrictionCoefficient);
}

class SmartTrackMaster {
  late final PerlinNoise noise;
  double targetNoiseAmplitude = 5.0;
  double surfaceFrictionCoefficient = 1.5;
  
  final _mutationController = StreamController<AgentMutationResponse>.broadcast();
  Stream<AgentMutationResponse> get mutationStream => _mutationController.stream;
  
  SmartTrackMaster() {
    noise = PerlinNoise(
      seed: 1337,
      frequency: 0.05,
      octaves: 3,
    );
  }

  void adaptTerrain(TelemetryData data) {
    double distanceTraveled = data.position.x;
    
    // Evaluate 'Flow State'
    if (distanceTraveled > 50 && data.airTime < 0.2 && !data.hasCrashed) {
      // Game is too easy: Increase noise amplitude and reduce surface friction
      targetNoiseAmplitude += 0.01;
      surfaceFrictionCoefficient -= 0.005;
    } else if (data.hasCrashed || data.velocity.length < 2.0) {
      // Game is too hard: Decrease amplitude, add "rest" segments
      targetNoiseAmplitude -= 0.05;
      surfaceFrictionCoefficient += 0.01;
    }

    // Clamp values to sane ranges
    targetNoiseAmplitude = targetNoiseAmplitude.clamp(1.0, 15.0);
    surfaceFrictionCoefficient = surfaceFrictionCoefficient.clamp(0.1, 3.0);

    _mutationController.add(AgentMutationResponse(targetNoiseAmplitude, surfaceFrictionCoefficient));
  }

  double getTerrainHeightAt(double x) {
    double rawNoise = noise.getPerlin2(x, 0.0);
    return rawNoise * targetNoiseAmplitude;
  }
}
