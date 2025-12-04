import 'dart:async';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:platformer/components/player.dart';
import 'package:platformer/pixel_game.dart';

enum FireState {idle, shieldDeploy, shieldRemove, shielded, hit}

class Fire extends SpriteAnimationGroupComponent with HasGameReference<PixelGame>, CollisionCallbacks {
  
  Fire({
    super.position,
    super.size,
  });

  static const stepTime = 0.05;

  late final Player player;
  late final SpriteAnimation _idleAnimation;
  late final SpriteAnimation _shieldDeployAnimation;
  late final SpriteAnimation _shieldRemoveAnimation;
  late final SpriteAnimation _shieldedAnimation;
  late final SpriteAnimation _hitAnimation;

  int health = 10;
  bool shielded = false;
  double shootCooldown = 5; // seconds

  @override
  FutureOr<void> onLoad() {
    priority = -10;
    debugMode = true;
    player = game.player;
    add(RectangleHitbox(
      position: Vector2.zero(),
      size: Vector2.all(96),
    ));
    _loadAllAnimations();
    return super.onLoad();
  }

  @override
  void update(double dt) {
    // TODO: implement update
    super.update(dt);
  }

  void _loadAllAnimations() {
    _idleAnimation = _spriteAnimation('Idle', 8, 96, 96);
    _shieldDeployAnimation = _spriteAnimation('Shield Deploy', 12, 128, 128)..loop = false;
    _shieldRemoveAnimation = _spriteAnimation('Shield Remove', 12, 128, 128)..loop = false;
    _shieldedAnimation = _spriteAnimation('Shield', 1, 128, 128);
    _hitAnimation = _spriteAnimation('Hit', 8, 96, 96)..loop=false;

    animations = {
      FireState.idle: _idleAnimation,
      FireState.shieldDeploy: _shieldDeployAnimation,
      FireState.shieldRemove: _shieldRemoveAnimation,
      FireState.shielded: _shieldedAnimation,
      FireState.hit: _hitAnimation,
    };

    current = FireState.idle;
  }

  SpriteAnimation _spriteAnimation(String state, int amount, int width, int height) {
    return SpriteAnimation.fromFrameData(
      game.images.fromCache('Enemies/Fire/$state (${width}x$height).png'),
      SpriteAnimationData.sequenced(
        amount: amount, 
        stepTime: stepTime, 
        textureSize: Vector2(width.toDouble(), height.toDouble()),
      ),
    );
  }

  void takeDamage() {

  }

  void _shootFire() {

  }

  void _shieldToggle() {

  }
  
  
  
}