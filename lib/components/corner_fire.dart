import 'dart:async';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:platformer/components/fire_controller.dart';
import 'package:platformer/components/fireball.dart';
import 'package:platformer/components/player.dart';
import 'package:platformer/pixel_game.dart';

class CornerFire extends SpriteAnimationComponent with HasGameReference<PixelGame>, CollisionCallbacks {
  final String corner;
  final FireController fireController = FireController();

  CornerFire({
    required this.corner,
    super.position,
    super.size,
  });

  static const stepTime = 0.05;
  static const shootCooldown = 8; // seconds

  double cooldownTimer = 0;
  bool isShooting = false;
  bool _hasRequestedShot = false;

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
    // debugMode = true;
    add(RectangleHitbox());
    return super.onLoad();
  }

  @override
  void update(double dt) {
    cooldownTimer += dt;

    if (cooldownTimer >= shootCooldown && !isShooting && !_hasRequestedShot) {
      if (fireController.canShoot(this)) {
        _hasRequestedShot = true;
        isShooting = true;
        _shootFireballs();
        cooldownTimer = 0;
      } else {
        cooldownTimer = shootCooldown - 0.1;
      }
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

    Future.delayed(const Duration(milliseconds: 1700), () {
      isShooting = false;
      _hasRequestedShot = false;
      fireController.finishShooting(this);
    });
    
  }

  void forceShoot() {
    if (!isShooting) {
      _hasRequestedShot = true;
      isShooting = true;
      _shootFireballs();
      cooldownTimer = 0;
    }
  }
  
}

