import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:sand_bike_sim/antigravity/antigravity_core.dart';
import 'package:flutter/material.dart';

class Terrain extends BodyComponent {
  double lastGeneratedX = -50;
  final double segmentLength = 1.0;
  final List<Vector2> surfacePoints = [];
  final List<Fixture> _sandFixtures = [];
  double _currentFriction = 0.6;

  @override
  Body createBody() {
    final bodyDef = BodyDef(position: Vector2.zero(), type: BodyType.static);
    final body = world.createBody(bodyDef);
    _generateSegment(body, -50, 50);
    return body;
  }

  void _generateSegment(Body body, double startX, double endX) {
    List<Vector2> chunkPoints = [];
    
    if (surfacePoints.isEmpty) {
      double y = AntigravityCore.instance.trackMaster.getTerrainHeightAt(startX);
      surfacePoints.add(Vector2(startX, y));
      chunkPoints.add(Vector2(startX, y));
    } else {
      // Connect to the last point to prevent gaps
      chunkPoints.add(surfacePoints.last);
    }

    for (double x = startX + segmentLength; x <= endX + 0.1; x += segmentLength) {
      double y = AntigravityCore.instance.trackMaster.getTerrainHeightAt(x);
      Vector2 point = Vector2(x, y);
      chunkPoints.add(point);
      surfacePoints.add(point);
    }
    
    // Using ChainShape prevents "ghost collisions" between segments where wheels get stuck
    final shape = ChainShape()..createChain(chunkPoints);
    final fixtureDef = FixtureDef(shape, friction: _currentFriction, restitution: 0.0); 
    fixtureDef.userData = 'sand';
    final fixture = body.createFixture(fixtureDef);
    _sandFixtures.add(fixture);
    
    lastGeneratedX = endX;
  }

  void setFriction(double f) {
    _currentFriction = f;
    for (var fix in _sandFixtures) {
      fix.friction = f;
    }
  }

  @override
  void render(Canvas canvas) {
    if (surfacePoints.isEmpty) return;

    final path = Path();
    path.moveTo(surfacePoints.first.x, surfacePoints.first.y);
    for (final p in surfacePoints) {
      path.lineTo(p.x, p.y);
    }
    path.lineTo(surfacePoints.last.x, 100);
    path.lineTo(surfacePoints.first.x, 100);
    path.close();

    final paint = Paint()
      ..color = const Color(0xFFFFB300) 
      ..style = PaintingStyle.fill;
    
    canvas.drawPath(path, paint);

    final edgePaint = Paint()
      ..color = const Color(0xFFE65100) 
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.3;
    
    final edgePath = Path();
    edgePath.moveTo(surfacePoints.first.x, surfacePoints.first.y);
    for (final p in surfacePoints) {
      edgePath.lineTo(p.x, p.y);
    }
    canvas.drawPath(edgePath, edgePaint);
  }

  void updateTerrain(double cameraX) {
    if (cameraX + 50 > lastGeneratedX) {
      _generateSegment(body, lastGeneratedX, lastGeneratedX + 20);
    }
  }
}
