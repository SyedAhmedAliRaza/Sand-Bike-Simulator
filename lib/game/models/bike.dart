import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flame/components.dart' hide Vector2;
import 'package:flutter/material.dart';
import 'dart:math';

class Bike extends PositionComponent with HasGameReference<Forge2DGame> {
  final Vector2 initialPosition;
  late final BikeChassis chassis;
  late final Wheel backWheel;
  late final Wheel frontWheel;
  
  bool isGrounded = true;
  bool hasCrashed = false;
  final bool isPlayer;

  Bike({required this.initialPosition, this.isPlayer = true});

  @override
  Future<void> onLoad() async {
    super.onLoad();
    
    // Create rigid bodies
    chassis = BikeChassis(initialPosition, isPlayer: isPlayer);
    backWheel = Wheel(initialPosition + Vector2(-1.5, 1.2), isPlayer: isPlayer);
    frontWheel = Wheel(initialPosition + Vector2(1.5, 1.2), isPlayer: isPlayer);

    await addAll([chassis, backWheel, frontWheel]);

    final backJointDef = WheelJointDef()
      ..initialize(chassis.body, backWheel.body, backWheel.body.position, Vector2(0, 1))
      ..frequencyHz = 3.5
      ..dampingRatio = 0.4;

    final frontJointDef = WheelJointDef()
      ..initialize(chassis.body, frontWheel.body, frontWheel.body.position, Vector2(0, 1))
      ..frequencyHz = 3.5
      ..dampingRatio = 0.4;

    game.world.physicsWorld.createJoint(WheelJoint(backJointDef));
    game.world.physicsWorld.createJoint(WheelJoint(frontJointDef));
  }

  void applyTilt(double tilt) {
    if (!hasCrashed && !isGrounded) {
      chassis.body.applyAngularImpulse(tilt * 10);
    }
  }

  void applyThrottle(double throttle) {
    if (isGrounded && !hasCrashed) {
      backWheel.body.setAwake(true);
      chassis.body.setAwake(true);
      
      if (backWheel.body.angularVelocity < 40.0) {
        backWheel.body.applyTorque(throttle * 80); 
      }
    }
  }
  
  void applyAI(double targetSpeed, double torqueMult) {
    if (hasCrashed) return;

    double currentAngle = chassis.body.angle;
    if (currentAngle.abs() > pi / 4) {
      // Prevent flipping by applying massive corrective torque
      chassis.body.applyAngularImpulse(-currentAngle * 15); 
    } else if (currentAngle.abs() > 0.1) {
      chassis.body.applyAngularImpulse(-currentAngle * 2); 
    }

    double currentSpeed = chassis.body.linearVelocity.x;
    double speedDiff = targetSpeed - currentSpeed;
    double throttle = (speedDiff * 0.2).clamp(-1.0, 1.0);
    applyThrottle(throttle * torqueMult);
  }

  void applyBoost(double boostImpulse) {
    chassis.body.applyLinearImpulse(Vector2(boostImpulse, 0));
  }
}

class BikeChassis extends BodyComponent {
  final Vector2 _position;
  final bool isPlayer;
  BikeChassis(this._position, {this.isPlayer = true});

  @override
  Body createBody() {
    final shape = PolygonShape()..setAsBoxXY(1.8, 0.8);
    final filter = Filter();
    filter.categoryBits = isPlayer ? 0x0002 : 0x0004;
    filter.maskBits = 0xFFFF ^ (isPlayer ? 0x0004 : 0x0002);

    final fixtureDef = FixtureDef(shape, density: 10.0, friction: 0.05, restitution: 0.1, filter: filter);
    final bodyDef = BodyDef(position: _position, type: BodyType.dynamic, bullet: true);
    return world.createBody(bodyDef)..createFixture(fixtureDef);
  }

  @override
  void render(Canvas canvas) {
    final color = paint.color;
    
    final panelPaint = Paint()..color = color..style = PaintingStyle.fill;
    final shadowPaint = Paint()..color = color.withOpacity(0.6)..style = PaintingStyle.fill;
    final rollCagePaint = Paint()..color = const Color(0xFF222222)..style = PaintingStyle.stroke..strokeWidth = 0.2..strokeJoin = StrokeJoin.round;
    final enginePaint = Paint()..color = const Color(0xFF666666)..style = PaintingStyle.fill;
    final darkEnginePaint = Paint()..color = const Color(0xFF1A1A1A)..style = PaintingStyle.fill;
    final shockPaint = Paint()..color = const Color(0xFFFFB300)..style = PaintingStyle.stroke..strokeWidth = 0.25;

    // Engine Block
    canvas.drawRect(const Rect.fromLTRB(-1.3, -0.3, 0.2, 0.5), darkEnginePaint);
    for(int i = 0; i < 4; i++) {
       canvas.drawRect(Rect.fromLTRB(-1.1 + i*0.3, -0.6, -0.9 + i*0.3, -0.3), enginePaint);
    }
    
    // Thicker Body Panels
    final bodyPath = Path()
      ..moveTo(-1.8, 0.4)
      ..lineTo(-1.3, -0.2)
      ..lineTo(0.8, -0.2)
      ..lineTo(1.8, 0.5)
      ..lineTo(1.7, 0.8)
      ..lineTo(-1.8, 0.8)
      ..close();
    canvas.drawPath(bodyPath, shadowPaint);
    canvas.save();
    canvas.translate(0, -0.08); 
    canvas.drawPath(bodyPath, panelPaint);
    canvas.restore();

    // Roll Cage
    final cagePath = Path()
      ..moveTo(-1.2, -0.2)
      ..lineTo(-0.6, -1.4)
      ..lineTo(0.6, -1.4)
      ..lineTo(1.2, -0.2);
    canvas.drawPath(cagePath, rollCagePaint);
    canvas.drawLine(const Offset(-0.8, -0.7), const Offset(0.8, -0.7), rollCagePaint);
    canvas.drawLine(const Offset(-0.6, -1.4), const Offset(-0.2, -0.2), rollCagePaint);
    
    // Suspension arms extending from chassis down to rough wheel locations
    canvas.drawLine(const Offset(1.2, 0.5), const Offset(1.5, 1.2), rollCagePaint); // Front Arm
    canvas.drawLine(const Offset(0.8, -0.1), const Offset(1.4, 1.1), shockPaint);   // Front Shock
    canvas.drawLine(const Offset(-1.4, 0.5), const Offset(-1.5, 1.2), rollCagePaint); // Back Arm
    canvas.drawLine(const Offset(-1.0, -0.1), const Offset(-1.4, 1.1), shockPaint);   // Back Shock

    // Thicker Fenders
    final fenderPaint = Paint()..color = const Color(0xFF111111)..style = PaintingStyle.stroke..strokeWidth = 0.25..strokeCap = StrokeCap.round;
    final backFender = Path()..moveTo(-0.5, 0.2)..quadraticBezierTo(-1.8, -0.6, -2.2, 0.5);
    final frontFender = Path()..moveTo(0.5, 0.2)..quadraticBezierTo(1.8, -0.6, 2.2, 0.5);
    canvas.drawPath(backFender, fenderPaint);
    canvas.drawPath(frontFender, fenderPaint);
  }
}

class Wheel extends BodyComponent {
  final Vector2 _position;
  final bool isPlayer;
  Wheel(this._position, {this.isPlayer = true});

  @override
  Body createBody() {
    final shape = CircleShape()..radius = 0.6; // Increased size
    final filter = Filter();
    filter.categoryBits = isPlayer ? 0x0002 : 0x0004;
    filter.maskBits = 0xFFFF ^ (isPlayer ? 0x0004 : 0x0002);

    final fixtureDef = FixtureDef(shape, density: 5.0, friction: 0.9, restitution: 0.2, filter: filter);
    final bodyDef = BodyDef(position: _position, type: BodyType.dynamic, bullet: true);
    return world.createBody(bodyDef)..createFixture(fixtureDef);
  }

  @override
  void render(Canvas canvas) {
    final tirePaint = Paint()..color = const Color(0xFF1A1A1A)..style = PaintingStyle.fill;
    final treadPaint = Paint()..color = const Color(0xFF111111)..style = PaintingStyle.fill;
    final rimOuterPaint = Paint()..color = const Color(0xFF444444)..style = PaintingStyle.stroke..strokeWidth = 0.12;
    final rimInnerPaint = Paint()..color = paint.color..style = PaintingStyle.fill;
    
    // Extended Paddles
    final int paddleCount = 14;
    for (int i = 0; i < paddleCount; i++) {
      double angle = i * 2 * pi / paddleCount;
      canvas.save();
      canvas.rotate(angle);
      final paddlePath = Path()
        ..moveTo(0.5, -0.1)
        ..lineTo(0.75, -0.05)
        ..lineTo(0.75, 0.05)
        ..lineTo(0.5, 0.1)
        ..close();
      canvas.drawPath(paddlePath, treadPaint);
      canvas.restore();
    }

    // Main Tire
    canvas.drawCircle(Offset.zero, 0.6, tirePaint);
    
    // Thicker Rim
    canvas.drawCircle(Offset.zero, 0.45, rimOuterPaint);
    canvas.drawCircle(Offset.zero, 0.35, rimInnerPaint);
    
    // Heavy Spokes
    final spokePaint = Paint()..color = const Color(0xFF999999)..style = PaintingStyle.stroke..strokeWidth = 0.1;
    for (int i = 0; i < 5; i++) {
      double angle = i * 2 * pi / 5;
      canvas.drawLine(
        Offset.zero,
        Offset(0.45 * cos(angle), 0.45 * sin(angle)),
        spokePaint,
      );
    }
    
    // Center cap
    canvas.drawCircle(Offset.zero, 0.1, Paint()..color = const Color(0xFF222222));
  }
}
