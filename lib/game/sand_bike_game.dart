import 'package:flutter/services.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flame/components.dart' hide Vector2;
import 'package:sand_bike_sim/game/models/bike.dart';
import 'package:sand_bike_sim/game/models/terrain.dart';
import 'package:sand_bike_sim/antigravity/antigravity_core.dart';
import 'package:sand_bike_sim/antigravity/telemetry_pipeline.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:flutter/material.dart';
import 'dart:math';

enum RaceState { preRace, racing, finished }

class FinishLineArch extends Component {
  final double xPos;
  FinishLineArch(this.xPos);
  
  @override
  void render(Canvas canvas) {
    final archPaint = Paint()..color = const Color(0xFF2E2E2E)..style = PaintingStyle.fill;
    final decorPaint = Paint()..color = const Color(0xFFFFB300)..style = PaintingStyle.stroke..strokeWidth = 0.2;
    final flagPaint = Paint()..color = Colors.white;
    final flagBlackPaint = Paint()..color = Colors.black;

    // Pillars
    canvas.drawRect(Rect.fromLTRB(xPos - 0.5, -12, xPos, AntigravityCore.instance.trackMaster.getTerrainHeightAt(xPos)), archPaint);
    canvas.drawRect(Rect.fromLTRB(xPos + 10, -12, xPos + 10.5, AntigravityCore.instance.trackMaster.getTerrainHeightAt(xPos + 10)), archPaint);
    
    // Crossbars & Decor
    canvas.drawRect(Rect.fromLTRB(xPos - 1, -12, xPos + 11, -9), archPaint);
    canvas.drawLine(Offset(xPos, -12), Offset(xPos + 10, -9), decorPaint);
    canvas.drawLine(Offset(xPos, -9), Offset(xPos + 10, -12), decorPaint);

    // Checkered pattern
    for (int i = 0; i < 24; i++) {
      for (int j = 0; j < 4; j++) {
        final p = (i + j) % 2 == 0 ? flagBlackPaint : flagPaint;
        canvas.drawRect(Rect.fromLTRB(xPos - 1 + i*0.5, -12 + j*0.5, xPos - 1 + (i+1)*0.5, -12 + (j+1)*0.5), p);
      }
    }
  }
}

class StartLineArch extends Component {
  final double xPos;
  StartLineArch(this.xPos);
  
  @override
  void render(Canvas canvas) {
    final archPaint = Paint()..color = const Color(0xFF444444)..style = PaintingStyle.fill;
    final decorPaint = Paint()..color = const Color(0xFF00E5FF)..style = PaintingStyle.stroke..strokeWidth = 0.2; // Cyan start line decor
    final flagPaint = Paint()..color = Colors.greenAccent;
    final flagBlackPaint = Paint()..color = Colors.black;

    canvas.drawRect(Rect.fromLTRB(xPos - 0.5, -10, xPos, AntigravityCore.instance.trackMaster.getTerrainHeightAt(xPos)), archPaint);
    canvas.drawRect(Rect.fromLTRB(xPos + 10, -10, xPos + 10.5, AntigravityCore.instance.trackMaster.getTerrainHeightAt(xPos + 10)), archPaint);
    
    canvas.drawRect(Rect.fromLTRB(xPos - 1, -10, xPos + 11, -7), archPaint);
    canvas.drawLine(Offset(xPos, -10), Offset(xPos + 10, -7), decorPaint);
    canvas.drawLine(Offset(xPos, -7), Offset(xPos + 10, -10), decorPaint);

    for (int i = 0; i < 24; i++) {
      for (int j = 0; j < 3; j++) {
        final p = (i + j) % 2 == 0 ? flagBlackPaint : flagPaint;
        canvas.drawRect(Rect.fromLTRB(xPos - 1 + i*0.5, -10 + j*1.0, xPos - 1 + (i+1)*0.5, -10 + (j+1)*1.0), p);
      }
    }
  }
}

class ScoreboardDisplay extends PositionComponent {
  final List<Map<String, dynamic>> results;
  ScoreboardDisplay({required Vector2 position, required this.results}) : super(position: position, size: Vector2(25, 15));

  @override
  void render(Canvas canvas) {
    final boardPaint = Paint()..color = const Color(0xFF111111)..style = PaintingStyle.fill;
    final borderPaint = Paint()..color = const Color(0xFF555555)..style = PaintingStyle.stroke..strokeWidth = 0.5;
    final postPaint = Paint()..color = const Color(0xFF333333)..style = PaintingStyle.fill;
    
    canvas.drawRect(Rect.fromLTRB(2, 15, 3, 30), postPaint);
    canvas.drawRect(Rect.fromLTRB(22, 15, 23, 30), postPaint);

    canvas.drawRect(size.toRect(), boardPaint);
    canvas.drawRect(size.toRect(), borderPaint);

    if (results.isEmpty) {
      _drawText(canvas, "RACE IN PROGRESS", 2, 6, 2.0, Colors.orangeAccent);
      return;
    }

    _drawText(canvas, "RESULTS - 1 LAP", 1, 1, 2.0, Colors.orangeAccent);
    _drawText(canvas, "POSITION | VEHICLE | TIME", 1, 4, 1.2, Colors.white70);

    double y = 6;
    for (int i = 0; i < results.length; i++) {
      final res = results[i];
      final isPlayer = res['name'] == 'Player';
      final color = isPlayer ? Colors.cyanAccent : Colors.white;
      final timeStr = formatTime(res['time']);
      
      if (isPlayer) {
        canvas.drawRect(Rect.fromLTRB(0.5, y - 0.2, 24.5, y + 1.8), Paint()..color = const Color(0xFF00E5FF).withOpacity(0.2));
      }
      
      _drawText(canvas, "${i+1}${getOrdinal(i+1)}    | ${res['name'].toString().padRight(7)} | $timeStr", 1, y, 1.2, color);
      y += 2.5;
    }
  }

  String getOrdinal(int n) {
    if (n == 1) return "st";
    if (n == 2) return "nd";
    if (n == 3) return "rd";
    return "th";
  }

  void _drawText(Canvas canvas, String text, double x, double y, double fontSize, Color color) {
    canvas.save();
    canvas.translate(x, y);
    final crispSpan = TextSpan(style: TextStyle(color: color, fontSize: fontSize * 10, fontFamily: 'Courier', fontWeight: FontWeight.bold), text: text);
    final crispTp = TextPainter(text: crispSpan, textAlign: TextAlign.left, textDirection: TextDirection.ltr);
    crispTp.layout();
    canvas.scale(0.1);
    crispTp.paint(canvas, Offset.zero);
    canvas.restore();
  }

  String formatTime(double time) {
    int minutes = time ~/ 60;
    int seconds = (time % 60).toInt();
    int ms = ((time * 100) % 100).toInt();
    return "$minutes:${seconds.toString().padLeft(2, '0')}:${ms.toString().padLeft(2, '0')}";
  }
}

class DustParticle {
  Vector2 position;
  double life;
  double maxLife;
  double radius;
  DustParticle(this.position, this.life, this.maxLife, this.radius);
}

class SandBikeContactListener extends ContactListener {
  final SandBikeGame game;
  SandBikeContactListener(this.game);

  @override
  void beginContact(Contact contact) {
    final bodyA = contact.fixtureA.body;
    final bodyB = contact.fixtureB.body;

    if (bodyA == game.bike.chassis.body || bodyB == game.bike.chassis.body) {
      game.onCrash(game.bike);
    }
    if (bodyA == game.rivalBike.chassis.body || bodyB == game.rivalBike.chassis.body) {
      game.onCrash(game.rivalBike);
    }
    if (bodyA == game.npc2Bike.chassis.body || bodyB == game.npc2Bike.chassis.body) {
      game.onCrash(game.npc2Bike);
    }
    
    if ((bodyA == game.bike.backWheel.body || bodyB == game.bike.backWheel.body) ||
        (bodyA == game.bike.frontWheel.body || bodyB == game.bike.frontWheel.body)) {
      game.onWheelLanding();
    }
  }

  @override
  void endContact(Contact contact) {}
  @override
  void preSolve(Contact contact, Manifold oldManifold) {}
  @override
  void postSolve(Contact contact, ContactImpulse impulse) {}
}

class SandBikeGame extends Forge2DGame {
  SandBikeGame() : super(gravity: Vector2(0, 10.0));

  late Bike bike;
  late Bike rivalBike;
  late Bike npc2Bike;
  late Terrain terrain;
  late ScoreboardDisplay scoreboard;
  
  double _tiltAngle = 0.0;
  double _throttle = 0.0;
  double _airTime = 0.0;
  
  final double finishLineX = 1000.0; // Increased lap distance
  double _raceTime = 0.0;
  
  final ValueNotifier<RaceState> raceState = ValueNotifier(RaceState.preRace);
  List<Map<String, dynamic>> raceResults = [];
  
  List<DustParticle> dustParticles = [];
  double currentMmr = 1.0;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    world.physicsWorld.setContactListener(SandBikeContactListener(this));
    camera.viewfinder.zoom = 20.0;

    terrain = Terrain();
    await world.add(terrain);

    bike = Bike(initialPosition: Vector2(0, -5), isPlayer: true);
    await world.add(bike);

    rivalBike = Bike(initialPosition: Vector2(-5, -5), isPlayer: false);
    await world.add(rivalBike);
    
    npc2Bike = Bike(initialPosition: Vector2(-10, -5), isPlayer: false);
    await world.add(npc2Bike);
    
    await world.add(StartLineArch(0.0));
    await world.add(FinishLineArch(finishLineX));
    scoreboard = ScoreboardDisplay(position: Vector2(finishLineX + 15, -25), results: raceResults);
    await world.add(scoreboard);
    
    bike.chassis.paint = Paint()..color = const Color(0xFF00E5FF); 
    bike.backWheel.paint = Paint()..color = const Color(0xFFE0F7FA);
    bike.frontWheel.paint = Paint()..color = const Color(0xFFE0F7FA);

    rivalBike.chassis.paint = Paint()..color = const Color(0xFFFF1744); 
    rivalBike.backWheel.paint = Paint()..color = const Color(0xFFFF8A80);
    rivalBike.frontWheel.paint = Paint()..color = const Color(0xFFFF8A80);

    npc2Bike.chassis.paint = Paint()..color = const Color(0xFFFFD600); // Desert Yellow
    npc2Bike.backWheel.paint = Paint()..color = const Color(0xFFFFF59D);
    npc2Bike.frontWheel.paint = Paint()..color = const Color(0xFFFFF59D);

    camera.follow(bike.chassis);

    accelerometerEventStream().listen((AccelerometerEvent event) {
      _tiltAngle = event.x / 9.8; 
    });
    
    AntigravityCore.instance.referee.boostStream.listen((boost) {
      if (raceState.value == RaceState.racing) bike.applyBoost(boost);
    });

    AntigravityCore.instance.trackMaster.mutationStream.listen((mutation) {
      currentMmr = mutation.targetNoiseAmplitude;
      terrain.setFriction(0.6 + (0.4 * currentMmr));
    });
  }

  void startGame() {
    resetRace();
    raceState.value = RaceState.racing;
  }

  void resetRace() {
    _raceTime = 0.0;
    raceResults.clear();
    dustParticles.clear();
    
    _relocateBike(bike, 0.0);
    _relocateBike(rivalBike, -5.0);
    _relocateBike(npc2Bike, -10.0);
    
    bike.hasCrashed = false;
    rivalBike.hasCrashed = false;
    npc2Bike.hasCrashed = false;
    
    raceState.value = RaceState.preRace;
  }

  void _relocateBike(Bike b, double startX) {
    double groundY = AntigravityCore.instance.trackMaster.getTerrainHeightAt(startX);
    double safeY = groundY - 3.0; 
    
    b.chassis.body.setTransform(Vector2(startX, safeY), 0);
    b.chassis.body.linearVelocity = Vector2.zero();
    b.chassis.body.angularVelocity = 0;
    
    b.frontWheel.body.setTransform(Vector2(startX + 1.5, safeY + 1.5), 0);
    b.frontWheel.body.linearVelocity = Vector2.zero();
    b.frontWheel.body.angularVelocity = 0;
    
    b.backWheel.body.setTransform(Vector2(startX - 1.5, safeY + 1.5), 0);
    b.backWheel.body.linearVelocity = Vector2.zero();
    b.backWheel.body.angularVelocity = 0;
    
    b.chassis.body.setAwake(true);
    b.backWheel.body.setAwake(true);
    b.frontWheel.body.setAwake(true);
  }

  void onCrash(Bike b) {
    if (raceState.value != RaceState.racing || b.hasCrashed) return;
    
    b.hasCrashed = true;
    if (b.isPlayer) HapticFeedback.heavyImpact();
    
    // Quick safe respawn slightly behind
    double safeX = b.chassis.body.position.x - 5.0;
    if (safeX < 0) safeX = 0;
    
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!isMounted) return; // Prevent crash if disposed
      _relocateBike(b, safeX);
      b.hasCrashed = false;
    });
  }

  void onWheelLanding() {
    if (_airTime > 1.0 && raceState.value == RaceState.racing && !bike.hasCrashed) {
      HapticFeedback.mediumImpact();
      AntigravityCore.instance.pitBoss.triggerExternalMessage("Perfect Landing!");
    }
  }

  @override
  void render(Canvas canvas) {
    final Rect bgRect = Rect.fromLTWH(0, 0, size.x, size.y);
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF01579B), Color(0xFF81D4FA), Color(0xFFFFCC80)],
        stops: [0.0, 0.6, 1.0],
      ).createShader(bgRect);
    canvas.drawRect(bgRect, paint);
    
    canvas.drawCircle(Offset(size.x * 0.8, size.y * 0.25), size.y * 0.12, Paint()..color = const Color(0xFFFFE082)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20));
    canvas.drawCircle(Offset(size.x * 0.8, size.y * 0.25), size.y * 0.08, Paint()..color = const Color(0xFFFFF8E1));

    final double camX = camera.viewfinder.position.x;
    
    _drawParallaxLayer(canvas, camX, 0.3, size.y * 0.5, const Color(0xFFDCA773)); 
    _drawParallaxLayer(canvas, camX, 0.6, size.y * 0.65, const Color(0xFFE6A355)); 

    super.render(canvas);
    
    final dustPaint = Paint()..style = PaintingStyle.fill;
    for (var p in dustParticles) {
      final screenPos = camera.viewfinder.localToGlobal(p.position);
      final alpha = (255 * (p.life / p.maxLife)).toInt().clamp(0, 255);
      dustPaint.color = const Color(0xFFD7CCC8).withAlpha(alpha);
      canvas.drawCircle(screenPos.toOffset(), p.radius * camera.viewfinder.zoom, dustPaint);
    }
  }
  
  void _drawParallaxLayer(Canvas canvas, double camX, double parallaxFactor, double baseY, Color color) {
    final Path dunePath = Path();
    double offsetX = -(camX * parallaxFactor * 20) % size.x;
    if (offsetX > 0) offsetX -= size.x;
    
    dunePath.moveTo(0, baseY);
    dunePath.quadraticBezierTo(size.x * 0.25, baseY - size.y * 0.1, size.x * 0.5, baseY);
    dunePath.quadraticBezierTo(size.x * 0.75, baseY + size.y * 0.1, size.x, baseY);
    dunePath.lineTo(size.x, size.y);
    dunePath.lineTo(0, size.y);
    dunePath.close();
    
    final Paint dunePaint = Paint()..color = color;
    canvas.save();
    canvas.translate(offsetX, 0);
    canvas.drawPath(dunePath, dunePaint);
    canvas.translate(size.x, 0);
    canvas.drawPath(dunePath, dunePaint);
    canvas.restore();
  }

  void _checkFinishLine(Bike b, String name) {
    if (b.chassis.body.position.x >= finishLineX) {
      bool alreadyFinished = raceResults.any((r) => r['name'] == name);
      if (!alreadyFinished) {
        raceResults.add({'name': name, 'time': _raceTime});
        if (name == 'Player') {
          raceState.value = RaceState.finished; // End game when player crosses
          int position = raceResults.length;
          String timeStr = scoreboard.formatTime(_raceTime);
          String suffix = scoreboard.getOrdinal(position);
          AntigravityCore.instance.pitBoss.triggerExternalMessage("Great fight! You crossed the line in $position$suffix Place. Total Time: $timeStr.");
        } else if (raceResults.length == 3) {
          // If player somehow never crossed but others did (fallback end)
          if(raceState.value == RaceState.racing) raceState.value = RaceState.finished;
        }
      }
    }
  }

  void _spawnDust(Bike b) {
    if (b.backWheel.body.angularVelocity.abs() > 5.0 && (b.backWheel.body.position.y >= AntigravityCore.instance.trackMaster.getTerrainHeightAt(b.backWheel.body.position.x) - 0.6)) {
      if (Random().nextDouble() > 0.5) {
        dustParticles.add(DustParticle(
          b.backWheel.body.position.clone() + Vector2(Random().nextDouble() - 0.5, Random().nextDouble() * 0.5),
          1.0,
          1.0 + Random().nextDouble(),
          0.1 + Random().nextDouble() * 0.3
        ));
      }
    }
  }

  void _checkOutOfBounds(Bike b) {
    if (b.chassis.body.position.y > 100) { // Kill volume check
      onCrash(b);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    if (raceState.value == RaceState.racing) {
      _raceTime += dt;
      _checkFinishLine(bike, 'Player');
      _checkFinishLine(rivalBike, 'NPC 1');
      _checkFinishLine(npc2Bike, 'NPC 2');
      
      bike.applyTilt(_tiltAngle);
      bike.applyThrottle(_throttle); 
      
      // AI Logic using the new applyAI method
      double targetSpeed = AntigravityCore.instance.rivalAi.ghostRider.targetSpeed;
      double torqueMult = AntigravityCore.instance.rivalAi.ghostRider.torqueMultiplier * currentMmr;
      
      if (rivalBike.chassis.body.position.x < finishLineX + 30) {
        rivalBike.applyAI(targetSpeed, torqueMult);
      }
      if (npc2Bike.chassis.body.position.x < finishLineX + 30) {
        npc2Bike.applyAI(targetSpeed * 0.95, torqueMult * 0.95);
      }
    } else {
      bike.applyThrottle(0);
      rivalBike.applyThrottle(0);
      npc2Bike.applyThrottle(0);
    }
    
    _checkOutOfBounds(bike);
    _checkOutOfBounds(rivalBike);
    _checkOutOfBounds(npc2Bike);

    if (!bike.isGrounded) {
      _airTime += dt;
    } else {
      _airTime = 0;
    }

    for (int i = dustParticles.length - 1; i >= 0; i--) {
      dustParticles[i].life -= dt;
      dustParticles[i].position.y -= dt * 2; 
      dustParticles[i].position.x -= dt * 1; 
      dustParticles[i].radius += dt * 0.5;   
      if (dustParticles[i].life <= 0) {
        dustParticles.removeAt(i);
      }
    }
    
    if (raceState.value == RaceState.racing) {
      _spawnDust(bike);
      _spawnDust(rivalBike);
      _spawnDust(npc2Bike);
    }
    
    // Update AI state so Pit Boss knows where the ghost is
    AntigravityCore.instance.rivalAi.currentGhostPosition = rivalBike.chassis.body.position.clone();

    AntigravityCore.instance.telemetry.updateMetrics(
      TelemetryData(
        throttle: _throttle,
        tiltAngle: _tiltAngle,
        airTime: _airTime,
        position: bike.chassis.body.position,
        velocity: bike.chassis.body.linearVelocity,
        hasCrashed: bike.hasCrashed,
        timestamp: DateTime.now().millisecondsSinceEpoch.toDouble(),
      ),
    );

    terrain.updateTerrain(camera.viewfinder.position.x);
  }
  
  void setThrottle(double val) {
    if (raceState.value == RaceState.racing) {
      _throttle = val;
    }
  }
}
