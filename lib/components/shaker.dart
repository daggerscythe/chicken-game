import 'dart:async';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:platformer/components/attack_hitbox.dart';
import 'package:platformer/components/collision_block.dart';
import 'package:platformer/components/custom_hitbox.dart';
import 'package:platformer/components/flake_projectile.dart';
import 'package:platformer/components/player.dart';
import 'package:platformer/components/utils.dart';
import 'package:platformer/pixel_game.dart';

enum ShakerState {idle, attacking, jumping, hit, disappearing}

class Shaker extends SpriteAnimationGroupComponent with HasGameReference<PixelGame>, CollisionCallbacks {
  final String name;

  Shaker({
    required this.name,
    super.position,
    super.size,
  });

  static const stepTime = 0.05;
  static const gravity = 9.8;
  static const _attackKickback = 100.0;
  final double terminalVelocity = 300;
  final double jumpForce = 300.0; 
  final double horizontalPush = 150.0;
  final double jumpCooldown = 5; // seconds
  final double stompRange = 150;
  final double shootRange = 400;
  final double attackCooldownTime = 3; // seconds
  final double shootWindup = 0.35; // 7 * 0.05 step time 

  Vector2 velocity = Vector2.zero();
  List<CollisionBlock> collisionBlocks = [];
  CustomHitbox hitbox = CustomHitbox(
    offsetX: 12, 
    offsetY: 10, 
    width: 40, 
    height: 85,
  );
  
  bool gotHit = false;
  bool canAttack = true;
  bool isOnGround = true;
  bool isShooting = false;
  double jumpTimer = 0;
  double shootTimer = 0;
  double attackCooldown = 0;
  double fixedDeltaTime = 1 / 60; // 60 fps
  double accumulatedTime = 0;
  int health = 2; // TODO: for presentation only
  AttackHitbox? attackHitbox;

  late final Player player;
  late final SpriteAnimation _idleAnimation;
  late final SpriteAnimation _attackingAnimation;
  late final SpriteAnimation _jumpingAnimation;
  late final SpriteAnimation _hitAnimation;
  late final SpriteAnimation _disappearingAnimation;

  @override
  FutureOr<void> onLoad() {
    // debugMode = true;
    player = game.player;
    add(RectangleHitbox(
      position: Vector2(hitbox.offsetX, hitbox.offsetY),
      size: Vector2(hitbox.width, hitbox.height),
      collisionType: CollisionType.passive,
    ));
    _loadAllAnimations();
    super.onLoad();
    collisionBlocks = game.currentLevel!.collisionBlocks;
    return super.onLoad();
  }

  @override
  void update(double dt) {
    accumulatedTime += dt;
    while (accumulatedTime >= fixedDeltaTime) {

      if (isShooting) {
        shootTimer -= fixedDeltaTime;
        if (shootTimer <= 0) {
          _fireProjectile();
          isShooting = false;
          current = ShakerState.idle;
        }
      }

      if (jumpTimer > 0) {
        jumpTimer -= fixedDeltaTime;
        if (jumpTimer < 0) jumpTimer = 0;
      }

      if (attackCooldown > 0) {
        attackCooldown -= fixedDeltaTime;
        if (attackCooldown < 0) attackCooldown = 0;
      }

      if (!gotHit) {
        _updateState();
        _movement(fixedDeltaTime);
        _checkHorizontalCollisions(); // important to check gravity AFTER hor. collision
        _applyGravity(fixedDeltaTime);
        _checkVerticalCollisions();
      }
      accumulatedTime -= fixedDeltaTime;
    }
    super.update(dt);
  }
  
  void _loadAllAnimations() {
    _idleAnimation = _spriteAnimation('Idle', 8, 32, 32);
    _attackingAnimation = _spriteAnimation('Attack', 13, 32, 32)..loop = false;
    _jumpingAnimation = _spriteAnimation('Jump', 12, 32, 32)..loop = false;
    _hitAnimation = _spriteAnimation('Hit', 8, 32, 32)..loop = false;
    _disappearingAnimation = _spriteAnimation('Disappearing', 7, 96, 96)..loop = false;

    animations = {
      ShakerState.idle: _idleAnimation,
      ShakerState.attacking: _attackingAnimation,
      ShakerState.jumping: _jumpingAnimation,
      ShakerState.hit: _hitAnimation,
      ShakerState.disappearing: _disappearingAnimation,
    };

    current = ShakerState.idle;
;  }

  SpriteAnimation _spriteAnimation(String state, int amount, int width, int height) {
    return SpriteAnimation.fromFrameData(
      game.images.fromCache('Enemies/$name/$state (${width}x$height).png'), 
      SpriteAnimationData.sequenced(
        amount: amount, 
        stepTime: stepTime, 
        textureSize: Vector2(width.toDouble(), height.toDouble()),
      ),
    );
  }
  
  void _updateState() {
    if (current == ShakerState.attacking || isShooting) return;

    // if in air
    if (!isOnGround) {
      current = ShakerState.jumping;
      return;
    }

    // on ground
    current = ShakerState.idle;
  }
  
  void _movement(double dt) {
    if (jumpTimer <= 0 && attackCooldown <= 0 && isOnGround) {

      if(_playerInStompRange()) {
        _jumpTowardPlayer(dt);
        return;
      }

      if (_playerInShootRange()) {
        _shootPlayer(dt);
        return;
      }
    }

    position.x += velocity.x * dt;
  }

  void _checkHorizontalCollisions() {
    for (final block in collisionBlocks) {
      // for a non-platform block
      if (!block.isPlatform && !block.isBlock) {
        if (checkCollision(this, block)) {
          // right collision
          if (velocity.x > 0) {
            position.x = block.x - hitbox.offsetX - hitbox.width;
          }
          // left collison
          if (velocity.x < 0) {
            position.x = block.x + block.width + hitbox.width + hitbox.offsetX;
          }

          velocity.x = -velocity.x; // bounce off the wall
          break;
        }
      }
    }
  }

  void _checkVerticalCollisions() {
    for (final block in collisionBlocks) {
      if (!block.isPlatform && !block.isBlock) {
        if (checkCollision(this, block)) {
          if (velocity.y > 0) {
            velocity.y = 0;
            velocity.x = 0;
            position.y = block.y - hitbox.height - hitbox.offsetY;

            if (!isOnGround) {
              _removeAttackHitbox();
            }
            isOnGround = true;
            break;
          }
          if (velocity.y < 0) {
            velocity.x = 0;
            velocity.y = 0;
            position.y = block.y + block.height - hitbox.offsetY;
            break;
          }
        }
      }
    }
  }

  Future<void> _jumpTowardPlayer(double dt) async {
    final int direction = (player.x < position.x) ? -1 : 1;

    velocity.y = -jumpForce;
    velocity.x = horizontalPush * direction;

    isOnGround = false;
    jumpTimer = jumpCooldown;
    current = ShakerState.jumping;

    attackHitbox = AttackHitbox(
      owner: this, 
      onHit: (other) {
        if (other is Player) other.collidedWithEnemy();
      },
      position: Vector2(hitbox.offsetX, 50),
      size: Vector2(hitbox.width, 50),
    );

    add(attackHitbox!);
  }
  
  void _shootPlayer(double dt) {
    current = ShakerState.attacking;
    isShooting = true;
    shootTimer = shootWindup;
    attackCooldown = attackCooldownTime;
  }

  void _fireProjectile() {
    final Vector2 playerCenter = player.position.clone() + player.size / 2;
    final Vector2 start = Vector2(
      position.x + hitbox.offsetX + hitbox.width / 2,
      position.y + hitbox.offsetY + hitbox.height / 2,
    ).clone();
    
    final Vector2 direction = (playerCenter - start).normalized();

    final flake = FlakeProjectile(
      flakeType: name,
      startPosition: start,
      direction: direction,
    );

    game.currentLevel?.add(flake);
  }
  
  bool _playerInStompRange() {
    final double shakerCenterX = position.x + hitbox.offsetX + hitbox.width / 2;
    final double playerCenterX = player.position.x + player.width / 2;

    final double shakerCenterY = position.y + hitbox.offsetY + hitbox.height / 2;
    final double playerCenterY = player.position.y + player.height / 2;

    final double dx = (playerCenterX - shakerCenterX).abs();
    final double dy = (playerCenterY - shakerCenterY).abs();

    return dy < 120 && dx < stompRange;
  }


  bool _playerInShootRange() {
    return (player.x - position.x).abs() < shootRange;
  }
  
  void _applyGravity(double dt) {
    velocity.y += gravity;
    velocity.y = velocity.y.clamp(-jumpForce, terminalVelocity);
    position.y += velocity.y * dt;
  }

  void takeDamage() async{
    if (gotHit) return; // prevent spamming

    _removeAttackHitbox(); // in case attack was interrupted

    health--;
    gotHit = true;

    if (health <= 0) {
      if (game.playSounds) FlameAudio.play('hit.wav', volume: game.soundVolume);
      current = ShakerState.disappearing;
      await animationTicker?.completed;
      bool lastShaker = _noShakersLeft();
      removeFromParent();

      if (lastShaker) {
        player.levelComplete();
      }

    } else {
      velocity.x = (player.scale.x > 0) ? _attackKickback : -_attackKickback;
      current = ShakerState.hit;
      await animationTicker?.completed;
      animationTicker?.reset();
    }

    const hitCooldown = Duration(milliseconds: 500);
    Future.delayed(hitCooldown, () => gotHit = false);
    current = ShakerState.idle;
  }
  
  void _removeAttackHitbox() {
    attackHitbox?.removeFromParent();
    attackHitbox = null;
  }
  
  bool _noShakersLeft() {
    if (parent == null) return true;

    int currentShakers = parent!.children
      .whereType<Shaker>()
      .where((shaker) => shaker != this)
      .length;
    
    return currentShakers == 0;
  }
  
}
