import 'dart:async';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:platformer/components/attack_hitbox.dart';
import 'package:platformer/components/custom_hitbox.dart';
import 'package:platformer/components/player.dart';
import 'package:platformer/pixel_game.dart';

enum ChickenState {idle, running, hit, attacking}

class Chicken extends SpriteAnimationGroupComponent with HasGameReference<PixelGame>, CollisionCallbacks {

  Chicken({
    super.position, // shortcut for constructors
  }); 

  static const stepTime = 0.05;
  static const runSpeed = 60;
  static const _bounceVertical = 260.0;
  static const _bounceHorizontal = 150.0;
  static const _attackKickback = 100.0;
  final textureSize = Vector2(32, 34);

  Vector2 velocity = Vector2.zero();
  double attackRange = 130;
  double chaseRange = 300;
  double moveDirection = 1;
  double targetDirection = -1; // by default chicken faces left
  bool gotHit = false;
  bool canAttack = true;
  int health = 2; // TODO: for presentation only
  AttackHitbox? attackHitbox;
  CustomHitbox hitbox = CustomHitbox(
    offsetX: 0, 
    offsetY: 0, 
    width: 64, 
    height: 64,
  );

  late final Player player;
  late final SpriteAnimation _idleAnimation;
  late final SpriteAnimation _runningAnimation;
  late final SpriteAnimation _hitAnimation;
  late final SpriteAnimation _attackingAnimation;

  @override
  FutureOr<void> onLoad() {
    // debugMode = true;
    player = game.player;
    add(RectangleHitbox(
      position: Vector2(hitbox.offsetX, hitbox.offsetY),
      size: Vector2(hitbox.width, hitbox.height),
    ));
    _loadAllAnimations();
    anchor = Anchor.topRight;
    return super.onLoad();
  }

  @override
  void update(double dt) {
    if (!gotHit) {
      _updateState();
      _movement(dt);
    }
    super.update(dt);
  }
  
  void _loadAllAnimations() {
    _idleAnimation = _spriteAnimation('Idle', 12, 64, 64);
    _runningAnimation = _spriteAnimation('Run', 14, 64, 64);
    _hitAnimation = _spriteAnimation('Hit', 5, 64, 64)..loop = false;
    _attackingAnimation = _spriteAnimation('Attack', 12, 100, 64)..loop = false;

    animations = {
      ChickenState.idle: _idleAnimation,
      ChickenState.running: _runningAnimation,
      ChickenState.hit: _hitAnimation,
      ChickenState.attacking: _attackingAnimation,
    };

    current = ChickenState.idle;
  }
  
  SpriteAnimation _spriteAnimation(String state, int amount, int width, int height) {
    return SpriteAnimation.fromFrameData(
      game.images.fromCache('Enemies/Chicken/$state (${width}x$height).png'), 
      SpriteAnimationData.sequenced(
        amount: amount, 
        stepTime: stepTime, 
        textureSize: Vector2(width.toDouble(), height.toDouble()),
      )
    );
  }
  
  
  void _movement(double dt) {
    velocity.x = 0;

    if (current == ChickenState.hit || current == ChickenState.attacking) {
      velocity.x = 0;
      return;
    }

    if (playerOnSameLevel()) {
      double distanceToPlayer = (position.x - player.x).abs();

      if(distanceToPlayer < attackRange && canAttack) {
        current = ChickenState.attacking;
        _attackPlayer();
        return;
      } else if (distanceToPlayer < chaseRange) {
        targetDirection = (player.x < position.x) ? -1 : 1;
        velocity.x = targetDirection * runSpeed;
      }
    }

    moveDirection = lerpDouble(moveDirection, targetDirection, 0.1) ?? 1;
    position.x += velocity.x * dt;
  }

  bool playerOnSameLevel() {
    return (player.y + player.height > position.y && player.y < position.y + height); 
  }

  bool playerInRange() {
    bool inFront = (position.x - player.x).abs() < attackRange;
    return playerOnSameLevel() && inFront;
  }
  
  void _updateState() {
    if (current == ChickenState.attacking) return;

    _removeAttackHitbox();

    current = (velocity.x != 0) ? ChickenState.running : ChickenState.idle;

    if ((moveDirection > 0 && scale.x > 0) || 
      (moveDirection < 0 && scale.x < 0)) {
      flipHorizontallyAroundCenter();
    }
  }


  //TODO: add player bouncing off the chicken
  void collidedWithPlayer() async {
    if (player.velocity.y > 0 && player.y + player.height > position.y) {
      if (game.playSounds) FlameAudio.play('bounce.wav', volume: game.soundVolume);
      player.velocity.y = -_bounceVertical;
    } else {
      if (player.x < position.x) {
        player.velocity.x = -_bounceHorizontal.abs();
      } else {
        player.velocity.x = _bounceHorizontal.abs();
      }
      player.collidedWithEnemy();
    }
  }

  void takeDamage() async{
    if (gotHit) return; // prevent spamming

    _removeAttackHitbox();
    canAttack = true;

    health--;
    gotHit = true;

    if (health <= 0) {
      if (game.playSounds) FlameAudio.play('hit.wav', volume: game.soundVolume);
      current = ChickenState.hit;
      await animationTicker?.completed;
      removeFromParent();
      player.levelComplete();
    } else {
      if (game.playSounds) FlameAudio.play('hit.wav', volume: game.soundVolume);
      velocity.x = (player.scale.x > 0) ? _attackKickback : -_attackKickback;
      current = ChickenState.hit;
      await animationTicker?.completed;
      animationTicker?.reset();
    }
    const hitCooldown = Duration(milliseconds: 500);
    Future.delayed(hitCooldown, () => gotHit = false);
  }
  
  void _attackPlayer() async {
    canAttack = false;
    current = ChickenState.attacking;

    final hitboxDelay = const Duration(milliseconds: 400); // 50 ms for 8 frames

    Future.delayed(hitboxDelay, () {
      attackHitbox = AttackHitbox(
        owner: this,
        onHit: (other) {
          if (other is Player) other.collidedWithEnemy();
        },
        position: Vector2(-20, 40),
        size: Vector2(30, 30),
      );

      add(attackHitbox!);
    });
 
    await animationTicker?.completed;

    _removeAttackHitbox();

    animationTicker?.reset();
    current = ChickenState.idle;

    await Future.delayed(const Duration(seconds: 1), () => canAttack = true);
  }
  
  void _removeAttackHitbox() {
    attackHitbox?.removeFromParent();
    attackHitbox = null;
  }

}