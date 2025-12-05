import 'dart:async';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:platformer/components/custom_hitbox.dart';
import 'package:platformer/components/fire.dart';
import 'package:platformer/components/player.dart';
import 'package:platformer/pixel_game.dart';

class Fireball extends SpriteAnimationComponent with HasGameReference<PixelGame>, CollisionCallbacks {
  
  Fireball({
    super.position,
    super.size,
  });

  late final Player player;
  late final SpriteAnimation _popAnimation;

  static const double lifetime = 3; //seconds
  static const double moveSpeed = 100;
  static const double stepTime = 0.05;
  static const int amount = 16;

  double lifeTimer = 0;
  bool isPopping = false;
  CustomHitbox hitbox = CustomHitbox(
    offsetX: 7, 
    offsetY: 5, 
    width: 20, 
    height: 20,
  );
  
  @override
  FutureOr<void> onLoad() {
    animation = SpriteAnimation.fromFrameData(
      game.images.fromCache('Enemies/Corner Fire/Fireball (32x32).png'), 
      SpriteAnimationData.sequenced(
        amount: amount, 
        stepTime: stepTime, 
        textureSize: Vector2.all(32),
      ),
    );
    _popAnimation = SpriteAnimation.fromFrameData(
      game.images.fromCache('Enemies/Corner Fire/Fireball Pop (32x32).png'), 
      SpriteAnimationData.sequenced(
        amount: 6, 
        stepTime: stepTime, 
        textureSize: Vector2.all(32),
        loop: false,
      ),
    );
    // debugMode = true;
    player = game.player;
    add(RectangleHitbox(
      position: Vector2(hitbox.offsetX, hitbox.offsetY),
      size: Vector2(hitbox.width, hitbox.height),
    ));
    anchor = Anchor.center;
    return super.onLoad();
  }

  @override
  void update(double dt) {
    
    lifeTimer += dt;

    if (lifeTimer > lifetime && !isPopping) {
      _popFireball();
    }

    if (!isPopping) _chasePlayer(dt);

    if (parent!.children.whereType<Fire>().length == 0) _popFireball();

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

    // direction the fireball is facing
    scale.x = (direction.x > 0) ? 1 : -1;
    
    position += direction * moveSpeed * dt;
  }

  Future<void> _popFireball() async {
    isPopping = true;
    animation = _popAnimation;
    await animationTicker?.completed;

    removeFromParent();
  }
}