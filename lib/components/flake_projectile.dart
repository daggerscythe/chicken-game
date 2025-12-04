import 'dart:async';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:platformer/components/player.dart';
import 'package:platformer/pixel_game.dart';

class FlakeProjectile extends SpriteComponent with HasGameReference<PixelGame>, CollisionCallbacks{
  String flakeType;
  Vector2 startPosition;
  Vector2 direction;

  FlakeProjectile ({
    required this.flakeType,
    required this.startPosition,
    required this.direction,
  }) : super (    
    position: startPosition,
    size: Vector2.all(32),
    // anchor: Anchor.center,
  );
  static const speed = 200.0;

  @override
  FutureOr<void> onLoad() {
    debugMode = true;
    priority = 10;
    sprite = Sprite(game.images.fromCache('Enemies/$flakeType/Flakes (32x32).png'));
    add(RectangleHitbox());
    return super.onLoad();
  }

  @override
  void update(double dt) {
    // print("Zoom is ${game.cam.viewfinder.zoom}");
    position += direction * speed * dt;

    if (!game.cam.visibleWorldRect.overlaps(toRect())) removeFromParent();
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
}