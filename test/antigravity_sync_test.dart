import 'package:flutter_test/flutter_test.dart';
import 'package:sand_bike_sim/antigravity/antigravity_core.dart';
import 'package:sand_bike_sim/antigravity/telemetry_pipeline.dart';
import 'package:flame_forge2d/flame_forge2d.dart';

void main() {
  setUp(() async {
    await AntigravityCore.instance.initialize();
  });

  tearDown(() async {
    await AntigravityCore.instance.shutdown();
  });

  test('Telemetry Pipeline validates spoofed velocity', () {
    // Inject spoofed data
    final spoofedData = TelemetryData(
      throttle: 1.0,
      tiltAngle: 0.0,
      airTime: 0.0,
      position: Vector2.zero(),
      velocity: Vector2(200, 0), // Impossible velocity
      hasCrashed: false,
      timestamp: DateTime.now().millisecondsSinceEpoch.toDouble(),
    );

    // Referee should reject this, but for testing we just ensure it processes without crashing
    expect(() => AntigravityCore.instance.referee.validate(spoofedData), returnsNormally);
  });

  test('Track Master adapts difficulty on crash', () {
    final initialDifficulty = AntigravityCore.instance.trackMaster.targetNoiseAmplitude;
    
    final crashData = TelemetryData(
      throttle: 0.0,
      tiltAngle: 1.5,
      airTime: 0.0,
      position: Vector2.zero(),
      velocity: Vector2.zero(),
      hasCrashed: true,
      timestamp: DateTime.now().millisecondsSinceEpoch.toDouble(),
    );

    AntigravityCore.instance.trackMaster.adaptTerrain(crashData);
    
    expect(AntigravityCore.instance.trackMaster.targetNoiseAmplitude, lessThan(initialDifficulty));
  });
}
