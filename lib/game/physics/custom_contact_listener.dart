import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:vibration/vibration.dart';

class CustomContactListener extends ContactListener {
  @override
  void beginContact(Contact contact) {
    // Haptic feedback for strong collisions
    if (contact.manifold.localNormal.length > 5.0) {
       _triggerHaptics();
    }
  }

  @override
  void endContact(Contact contact) {}

  @override
  void preSolve(Contact contact, Manifold oldManifold) {}

  @override
  void postSolve(Contact contact, ContactImpulse impulse) {}

  Future<void> _triggerHaptics() async {
    if (await Vibration.hasVibrator()) {
      Vibration.vibrate(duration: 50, amplitude: 128);
    }
  }
}
