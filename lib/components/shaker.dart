import 'dart:async';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:platformer/components/player.dart';
import 'package:platformer/pixel_game.dart';

enum ShakerState {idle, jumping, hit, attacking}

class Shaker extends SpriteAnimationGroupComponent with HasGameReference<PixelGame>, CollisionCallbacks {
  final String shakerName;
  Shaker({
    required this.shakerName,
    super.position,
    super.size,
  }); 

  static const stepTime = 0.05;
  static const tileSize = 16;
  static const runSpeed = 60;
  static const _bounceVertical = 260.0;
  static const _bounceHorizontal = 150.0;
  static const _attackKickback = 100.0;
  final textureSize = Vector2(32, 34);

  Vector2 velocity = Vector2.zero();
  // TODO: target direction needed or not???
  bool gotHit = false;
  bool canAttack = true;
  int health = 5;

  late final Player player;
  late final SpriteAnimation _idleAnimation;
  late final SpriteAnimation _jumpingAnimation;
  late final SpriteAnimation _hitAnimation;
  late final SpriteAnimation _attackingAnimation;

  @override
  FutureOr<void> onLoad() {
    debugMode = true;
    player = game.player;
    add(RectangleHitbox(
      position: Vector2.zero(),
      size: Vector2.all(64),
    ));
    _loadAllAnimations();
    return super.onLoad();
  }

  @override
  void update(double dt) {
    if (!gotHit) {
      // _updateState();
      // _movement(dt);
    }
    super.update(dt);
  }
  
  void _loadAllAnimations() {
    _idleAnimation = _spriteAnimation('Idle', 8, 32, 32);
    _jumpingAnimation = _spriteAnimation('Jump', 12, 32, 32);
    // _hitAnimation = _spriteAnimation('Hit', 5, 32, 32)..loop = false;
    _attackingAnimation = _spriteAnimation('Attack', 13, 32, 32)..loop = false;

    animations = {
      ShakerState.idle: _idleAnimation,
      ShakerState.jumping: _jumpingAnimation,
      // ShakerState.hit: _hitAnimation,
      ShakerState.attacking: _attackingAnimation,
    };

    current = ShakerState.attacking;
  }
  
  SpriteAnimation _spriteAnimation(String state, int amount, int width, int height) {
    return SpriteAnimation.fromFrameData(
      game.images.fromCache('Enemies/$shakerName/$state (${width}x$height).png'), 
      SpriteAnimationData.sequenced(
        amount: amount, 
        stepTime: stepTime, 
        textureSize: Vector2(width.toDouble(), height.toDouble()),
      )
    );
  }
  
  
  // void _movement(double dt) {
  //   velocity.x = 0;

  //   if (playerOnSameLevel()) {
  //     double distanceToPlayer = (position.x - player.x).abs();

  //     if(distanceToPlayer < attackRange && current != ShakerState.attacking && canAttack) {
  //       _attackPlayer();
  //     } else if (distanceToPlayer < chaseRange) {
  //       targetDirection = (player.x < position.x) ? -1 : 1;
  //       velocity.x = targetDirection * runSpeed;
  //     }
  //   }

  //   moveDirection = lerpDouble(moveDirection, targetDirection, 0.1) ?? 1;
  //   position.x += velocity.x * dt;
  // }

  // bool playerOnSameLevel() {
  //   return (player.y + player.height > position.y && player.y < position.y + height); 
  // }

  // bool playerInRange() {
  //   bool inFront = (position.x - player.x).abs() < attackRange;
  //   return playerOnSameLevel() && inFront;
  // }
  
  // void _updateState() {
  //   if (current == ShakerState.attacking) return;

  //   current = (velocity.x != 0) ? ShakerState.running : ShakerState.idle;

  //   if ((moveDirection > 0 && scale.x > 0) || 
  //     (moveDirection < 0 && scale.x < 0)) {
  //     flipHorizontallyAroundCenter();
  //   }
  // }

  // void collidedWithPlayer() async {
  //   if (player.velocity.y > 0 && player.y + player.height > position.y) {
  //     if (game.playSounds) FlameAudio.play('bounce.wav', volume: game.soundVolume);
  //     player.velocity.y = -_bounceVertical;
  //   } else {
  //     if (player.x < position.x) {
  //       player.velocity.x = -_bounceHorizontal.abs();
  //     } else {
  //       player.velocity.x = _bounceHorizontal.abs();
  //     }
  //     player.collidedWithEnemy();
  //   }
  // }

  // void takeDamage() async{
  //   if (gotHit) return; // prevent spamming

  //   health--;
  //   gotHit = true;

  //   if (health <= 0) {
  //     if (game.playSounds) FlameAudio.play('hit.wav', volume: game.soundVolume);
  //     current = ShakerState.hit;
  //     await animationTicker?.completed;
  //     removeFromParent();
  //     player.levelComplete();
  //   } else {
  //     velocity.x = (player.scale.x > 0) ? _attackKickback : -_attackKickback;
  //     current = ShakerState.hit;
  //     await animationTicker?.completed;
  //     animationTicker?.reset();
  //   }
  //   const hitCooldown = Duration(milliseconds: 500);
  //   Future.delayed(hitCooldown, () => gotHit = false);
  // }
  
  // void _attackPlayer() async {
  //   if (current == ShakerState.attacking || !canAttack) return;

  //   canAttack = false;
  //   current = ShakerState.attacking;
  //   velocity.x = 0;
 
  //   await animationTicker?.completed;
  //   animationTicker?.reset();

  //   if (playerInRange() && (position.x - player.x).abs() < attackRange) {
  //     player.collidedWithEnemy();
  //   }

  //   current = ShakerState.idle;

  //   await Future.delayed(const Duration(seconds: 1), () => canAttack = true);

  //   _updateState(); 
  // }

}