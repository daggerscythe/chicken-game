import 'dart:async';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:platformer/pixel_game.dart';

class FlakeProjectile extends SpriteComponent with HasGameReference<PixelGame>, CollisionCallbacks{
  String flakeType;
  Vector2 startPosition;
  Vector2 direction;
  double speed;

  FlakeProjectile ({
    required this.flakeType,
    required this.startPosition,
    required this.direction,
    required this.speed,
  }) : super (    
    position: startPosition.clone(),
    size: Vector2.all(32),
    anchor: Anchor.center,
  );

  @override
  FutureOr<void> onLoad() {
    print("DEBUG: loading $flakeType flakes....");
    sprite = Sprite(game.images.fromCache('Enemies/$flakeType/Flakes (32x32).png'));
    add(RectangleHitbox());
    return super.onLoad();
  }

  @override
  void update(double dt) {
    print("DEBUG: firing $flakeType flakes at $position....");
    position += direction * speed * dt;

    // delete when offscreen
    if (!game.camera.visibleWorldRect.contains(position.toOffset())) removeFromParent();
    super.update(dt);
  }
}