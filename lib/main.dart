import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:sand_bike_sim/game/sand_bike_game.dart';
import 'package:sand_bike_sim/ui/game_overlay.dart';
import 'package:sand_bike_sim/antigravity/antigravity_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AntigravityCore.instance.initialize();
  
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: GameWidget<SandBikeGame>(
          game: SandBikeGame(),
          overlayBuilderMap: {
            'Overlay': (context, game) => GameOverlay(game: game),
          },
          initialActiveOverlays: const ['Overlay'],
        ),
      ),
    ),
  );
}
