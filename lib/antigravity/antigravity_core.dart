import 'dart:async';
import 'package:sand_bike_sim/antigravity/telemetry_pipeline.dart';
import 'package:sand_bike_sim/antigravity/smart_track_master.dart';
import 'package:sand_bike_sim/antigravity/smart_rival_ai.dart';
import 'package:sand_bike_sim/antigravity/pit_boss.dart';
import 'package:sand_bike_sim/antigravity/referee.dart';

class AntigravityCore {
  AntigravityCore._privateConstructor();
  static final AntigravityCore instance = AntigravityCore._privateConstructor();

  late final TelemetryPipeline telemetry;
  late final SmartTrackMaster trackMaster;
  late final SmartRivalAi rivalAi;
  late final PitBossAgent pitBoss;
  late final Referee referee;

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    
    // Instantiate sub-agents
    telemetry = TelemetryPipeline();
    trackMaster = SmartTrackMaster();
    rivalAi = SmartRivalAi();
    pitBoss = PitBossAgent();
    referee = Referee();

    // Orchestrate inter-agent connections
    telemetry.stream.listen(_onTelemetryTick);
    
    _initialized = true;
    print("Antigravity SDK Initialized. Agents standing by.");
  }

  void _onTelemetryTick(TelemetryData data) {
    // 1. Referee validates state
    referee.validate(data);
    
    // 2. Track master adjusts terrain based on momentum/crashes
    trackMaster.adaptTerrain(data);
    
    // 3. Smart Rival adapts racing line
    rivalAi.processOpponentData(data);
    
    // 4. Pit Boss analyzes vectors
    pitBoss.analyze(data);
  }

  Future<void> shutdown() async {
    telemetry.dispose();
  }
}
