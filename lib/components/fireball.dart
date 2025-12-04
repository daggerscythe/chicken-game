import 'dart:async';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:platformer/components/player.dart';
import 'package:platformer/pixel_game.dart';

//TODO: add a splash effect on hit

class Fireball extends SpriteAnimationComponent with HasGameReference<PixelGame>, CollisionCallbacks {
  
  Fireball({
    super.position,
    super.size,
  });

  late final Player player;

  static const double lifetime = 3; //seconds
  static const double moveSpeed = 100;

  double lifeTimer = 0;
  
  @override
  FutureOr<void> onLoad() {
    debugMode = true;
    player = game.player;
    add(RectangleHitbox());
    return super.onLoad();
  }

  @override
  void update(double dt) {
    
    lifeTimer += dt;

    if (lifeTimer >= lifetime) {
      removeFromParent();
      return;
    }

    _chasePlayer(dt);

    super.update(dt);
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is Player) {
      other.collidedWithEnemy();
      removeFromParent();
    }
    super.onCollisionStart(intersectionPoints, other);
  }

  void _chasePlayer(double dt){
    final playerCenter = player.position + player.size / 2;
    final fireballCenter = position + size / 2;
    final direction = (playerCenter - fireballCenter).normalized();
    
    // move towards player
    position += direction * moveSpeed * dt;
  }
}