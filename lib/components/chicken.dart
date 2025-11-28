import 'dart:async';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:platformer/components/player.dart';
import 'package:platformer/pixel_game.dart';

enum ChickenState {idle, running, hit}

class Chicken extends SpriteAnimationGroupComponent with HasGameReference<PixelGame>, CollisionCallbacks {
  final double offsetNeg;
  final double offsetPos;

  Chicken({super.position, // shortcut for constructors
    super.size, // shortcut for constructors
    this.offsetNeg = 0.0, 
    this.offsetPos = 0.0
  }); 

  static const stepTime = 0.05;
  static const tileSize = 16;
  static const runSpeed = 80;
  static const _bounceVertical = 260.0;
  static const _bounceHorizontal = 150.0;
  final textureSize = Vector2(32, 34);

  Vector2 velocity = Vector2.zero();
  double rangeNeg = 0.0;
  double rangePos = 0.0;
  double moveDirection = 1;
  double targetDirection = -1; // by default chicken faces left
  bool gotStomped = false;
  bool gotHit = false;
  int health = 5;

  late final Player player;
  late final SpriteAnimation _idleAnimation;
  late final SpriteAnimation _runningAnimation;
  late final SpriteAnimation _hitAnimation;

  @override
  FutureOr<void> onLoad() {
    debugMode = false;
    player = game.player;
    add(RectangleHitbox(
      position: Vector2(4, 6),
      size: Vector2(24, 26)
    ));
    _loadAllAnimations();
    _calculateRange();
    return super.onLoad();
  }

  @override
  void update(double dt) {
    if (!gotStomped) {
      _updateState();
      _movement(dt);
    }
    super.update(dt);
  }
  
  void _loadAllAnimations() {
    _idleAnimation = _spriteAnimation('Idle', 13);
    _runningAnimation = _spriteAnimation('Run', 14);
    _hitAnimation = _spriteAnimation('Hit', 5)..loop = false;

    animations = {
      ChickenState.idle: _idleAnimation,
      ChickenState.running: _runningAnimation,
      ChickenState.hit: _hitAnimation,
    };

    current = ChickenState.idle;
  }
  
  SpriteAnimation _spriteAnimation(String state, int amount) {
    return SpriteAnimation.fromFrameData(
      game.images.fromCache('Enemies/Chicken/$state (32x34).png'), 
      SpriteAnimationData.sequenced(
        amount: amount, 
        stepTime: stepTime, 
        textureSize: textureSize
      )
    );
  }
  
  void _calculateRange() {
    rangeNeg = position.x - offsetNeg * tileSize;
    rangePos = position.x + offsetPos * tileSize;
  }
  
  void _movement(double dt) {
    // set velocity to 0
    velocity.x = 0;

    double playerOffset = (player.scale.x > 0) ? 0 : -player.width;
    double chickenOffset = (scale.x > 0) ? 0 : -width;

    if (playerInRange()) {
       // -1 go left, 1 go right
      targetDirection = (player.x + playerOffset < position.x + chickenOffset) ? -1 : 1;
      velocity.x = targetDirection * runSpeed;
    }

    moveDirection = lerpDouble(moveDirection, targetDirection, 0.1) ?? 1;

    position.x += velocity.x * dt;
  }

  bool playerInRange() {
    double playerOffset = (player.scale.x > 0) ? 0 : -player.width;
    return player.x + playerOffset >= rangeNeg &&
          player.x + playerOffset <= rangePos &&
          player.y + player.height > position.y &&
          player.y < position.y + height;
  }
  
  void _updateState() {
    current = (velocity.x != 0) ? ChickenState.running : ChickenState.idle;
    if ((moveDirection > 0 && scale.x > 0) || 
      (moveDirection < 0 && scale.x < 0)) {
      flipHorizontallyAroundCenter();
    }
  }

  void collidedWithPlayer() async {
    if (player.velocity.y > 0 && player.y + player.height > position.y) {
      if (game.playSounds) FlameAudio.play('bounce.wav', volume: game.soundVolume);
      gotStomped = true;
      current = ChickenState.hit;
      player.velocity.y = -_bounceVertical;
      await animationTicker?.completed;
      removeFromParent();
    } else {
      if (player.x < position.x) {
        player.velocity.x = -_bounceHorizontal.abs();
      } else {
        player.velocity.x = _bounceHorizontal.abs();
      }
      player.collidedWithEnemy();
    }
  }

}