import 'dart:async';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:platformer/components/fireball.dart';
import 'package:platformer/components/player.dart';
import 'package:platformer/pixel_game.dart';

class CornerFire extends SpriteAnimationComponent with HasGameReference<PixelGame>, CollisionCallbacks {
  final String corner;

  CornerFire({
    required this.corner,
    super.position,
    super.size,
  });

  static const stepTime = 0.05;
  static const shootCooldown = 5; // seconds

  double cooldownTimer = 0;

  @override
  FutureOr<void> onLoad() {
    animation = SpriteAnimation.fromFrameData(
      game.images.fromCache('Enemies/Corner Fire/$corner (96x96).png'),
      SpriteAnimationData.sequenced(
        amount: 8, 
        stepTime: stepTime, 
        textureSize: Vector2.all(96),
      ),
    );
    debugMode = true;
    add(RectangleHitbox());
    return super.onLoad();
  }

  @override
  void update(double dt) {
    cooldownTimer += dt;

    if (cooldownTimer >= shootCooldown) {
      // _shootFireballs();
      cooldownTimer = 0;
    }

    super.update(dt);
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is Player) other.collidedWithEnemy();
    super.onCollisionStart(intersectionPoints, other);
  }

  void _shootFireballs() {
    final fireballInterval = 0.5;
    // final Duration fireballInterval = const Duration(milliseconds: 500);
    for (int i = 0; i < 3; i++) {
      final delay = fireballInterval * i;

      Future.delayed(Duration(seconds: delay.toInt(), milliseconds: ((delay % 1) * 1000).toInt()), () {
        final fireball = Fireball(
          position: position.clone(), 
          size: Vector2.all(32),
        );
        game.currentLevel?.add(fireball);
      });    
      
       
    }
    
  }
  
}

