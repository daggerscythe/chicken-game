import 'dart:async';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/services.dart';
import 'package:platformer/components/checkpoint.dart';
import 'package:platformer/components/chicken.dart';
import 'package:platformer/components/collision_block.dart';
import 'package:platformer/components/custom_hitbox.dart';
import 'package:platformer/components/heal.dart';
import 'package:platformer/components/saw.dart';
import 'package:platformer/components/utils.dart';
import 'package:platformer/pixel_game.dart';

enum PlayerState {idle, running, jumping, falling, hit, appearing, disappearing}

class Player extends SpriteAnimationGroupComponent with HasGameReference<PixelGame>, KeyboardHandler, CollisionCallbacks {
  String character;
  Player({
    position, 
    this.character = 'Virtual Guy',
  }) : super(position: position);

  final double stepTime = 0.05;
  static const canMoveDuration = Duration(milliseconds: 400);
  late final SpriteAnimation idleAnimation;
  late final SpriteAnimation runningAnimation;
  late final SpriteAnimation jumpingAnimation;
  late final SpriteAnimation fallingAnimation;
  late final SpriteAnimation hitAnimation;
  late final SpriteAnimation appearingAnimation;
  late final SpriteAnimation disappearingAnimation;

  final double _gravity = 9.8;
  final double _jumpForce = 260;
  final double _terminalVelocity = 300;

  int maxLives = 3;
  int currentLives = 3;
  double horizontalMovement = 0;
  double moveSpeed = 100;
  Vector2 startingPosition = Vector2.zero();
  Vector2 velocity = Vector2.zero();
  bool isOnGround = false;
  bool hasJumped = false;
  bool dead = false;
  bool reachedCheckpoint= false;
  bool recentlyHit = false;
  List<CollisionBlock> collisionBlocks = [];
  CustomHitbox hitbox = CustomHitbox(
    offsetX: 10, 
    offsetY: 4, 
    width: 14, 
    height: 28,
  );

  double fixedDeltaTime = 1 / 60; // 60 fps
  double accumulatedTime = 0;

  @override
  FutureOr<void> onLoad() {
    _loadAllAnimations(); // underscore makes it private
    // debugMode = true; // to show player collision
    startingPosition = Vector2(position.x, position.y); // get spawn point
    add(RectangleHitbox(
      position: Vector2(hitbox.offsetX, hitbox.offsetY),
      size: Vector2(hitbox.width, hitbox.height),
    ));
    return super.onLoad();
  }

  @override
  void update(double dt) { // delta time allows the game to run at same fps consistently
    accumulatedTime += dt;

    while (accumulatedTime >= fixedDeltaTime) {
      if (!dead && !reachedCheckpoint) {
        _updatePlayerState();
        _updatePlayerMovement(fixedDeltaTime);
        _checkHorizontalCollisions(); // important to check gravity AFTER hor. collision
        _applyGravity(fixedDeltaTime);
        _checkVerticalCollisions();
      }
      accumulatedTime -= fixedDeltaTime;
    }

    super.update(dt);
  }

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    horizontalMovement = 0;
    final isLeftKeyPressed = keysPressed.contains(LogicalKeyboardKey.keyA) 
      || keysPressed.contains(LogicalKeyboardKey.arrowLeft);
    final isRightKeyPressed = keysPressed.contains(LogicalKeyboardKey.keyD) 
      || keysPressed.contains(LogicalKeyboardKey.arrowRight);
    
    horizontalMovement += isLeftKeyPressed ? -1 : 0;
    horizontalMovement += isRightKeyPressed ? 1 : 0;

    hasJumped = keysPressed.contains(LogicalKeyboardKey.space);
    
    return super.onKeyEvent(event, keysPressed);
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (!reachedCheckpoint) {
      if (other is Heal) other.collidedWithPlayer();
      if (other is Saw) _respawn();
      if (other is Chicken) other.collidedWithPlayer();
      if (other is Checkpoint && !reachedCheckpoint) _reachedCheckpoint();
    }
    super.onCollisionStart(intersectionPoints, other);
  }

  void _loadAllAnimations() {
    idleAnimation = _spriteAnimation('Idle', 11);
    runningAnimation = _spriteAnimation('Run', 12);
    jumpingAnimation = _spriteAnimation('Jump', 1);
    fallingAnimation = _spriteAnimation('Fall', 1);
    hitAnimation = _spriteAnimation('Hit', 7)..loop = false; // only plays once
    appearingAnimation = _specialSpriteAnimation('Appearing', 7);
    disappearingAnimation = _specialSpriteAnimation('Disappearing', 7);
    
    animations = {
      PlayerState.idle: idleAnimation,
      PlayerState.running: runningAnimation,
      PlayerState.jumping: jumpingAnimation,
      PlayerState.falling: fallingAnimation,
      PlayerState.hit: hitAnimation,
      PlayerState.appearing: appearingAnimation,
      PlayerState.disappearing: disappearingAnimation,
    };

    // set current animation
    current = PlayerState.idle;
  }
  
  SpriteAnimation _spriteAnimation(String state, int amount) {
    return SpriteAnimation.fromFrameData(
      game.images.fromCache('Main Characters/$character/$state (32x32).png'), 
        SpriteAnimationData.sequenced(amount: amount, stepTime: stepTime, textureSize: Vector2.all(32)
      )
    );
  }

  SpriteAnimation _specialSpriteAnimation(String state, int amount) {
    return SpriteAnimation.fromFrameData(
      game.images.fromCache('Main Characters/$state (96x96).png'), 
        SpriteAnimationData.sequenced(
          amount: amount, 
          stepTime: stepTime, 
          textureSize: Vector2.all(96),
          loop: false,
      )
    );
  }
  
  void _updatePlayerState() {
    PlayerState playerState = PlayerState.idle;

    // flip depending on direction
    if (velocity.x < 0 && scale.x > 0) {
      flipHorizontallyAroundCenter();
    } else if (velocity.x > 0 && scale.x < 0){
      flipHorizontallyAroundCenter();
    }

    // if moving, set running
    if (velocity.x > 0 || velocity.x < 0) playerState = PlayerState.running;
    
    // if falling, set falling
    if (velocity.y > 0) playerState = PlayerState.falling;

    // if jumping, set jumping
    if (velocity.y < 0) playerState = PlayerState.jumping;

    current = playerState;
  }
  
  void _updatePlayerMovement(double dt) {
    if (hasJumped && isOnGround) _playerJump(dt);
    if (!recentlyHit) velocity.x = horizontalMovement * moveSpeed;
    position.x += velocity.x * dt;
  }

  void _playerJump(double dt) {
    if (game.playSounds) FlameAudio.play('jump.wav', volume: game.soundVolume);
    velocity.y = -_jumpForce;
    position.y += velocity.y * dt;
    isOnGround = false;
    hasJumped = false;
  }
  
  void _checkHorizontalCollisions() {
    for (final block in collisionBlocks) {
      // for a non-platform block
      if (!block.isPlatform) {
        if (checkCollision(this, block)) {
          // right collision
          if (velocity.x > 0) {
            velocity.x = 0;
            position.x = block.x - hitbox.offsetX - hitbox.width;
            break;
          }
          // left collison
          if (velocity.x < 0) {
            velocity.x = 0;
            position.x = block.x + block.width + hitbox.width + hitbox.offsetX;
            break;
          }
        }
      }
    }
  }
  
  void _applyGravity(double dt) {
    velocity.y += _gravity;
    velocity.y = velocity.y.clamp(-_jumpForce, _terminalVelocity);
    position.y += velocity.y * dt;
  }
  
  void _checkVerticalCollisions() {
    for (final block in collisionBlocks) {
      if (block.isPlatform) {
        if (checkCollision(this, block)) {
          if (velocity.y > 0) {
            velocity.y = 0;
            position.y = block.y - hitbox.height - hitbox.offsetY;
            isOnGround = true;
            break;
          }
        }
      } else {
        if (checkCollision(this, block)) {
          if (velocity.y > 0) {
            velocity.y = 0;
            position.y = block.y - hitbox.height - hitbox.offsetY;
            isOnGround = true;
            break;
          }
          if (velocity.y < 0) {
            velocity.y = 0;
            position.y = block.y + block.height - hitbox.offsetY;
            break;
          }
        }
      }
    }

  }
  
  void _playerHit() async {
    if (game.playSounds) FlameAudio.play('hit.wav', volume: game.soundVolume);
    currentLives--;

    current = PlayerState.hit;
    
    if (currentLives <= 0) {
      // TODO: fix animations for hit and respawn
      _respawn();
      return;
    }

    await animationTicker?.completed;
    animationTicker?.reset();

    _updatePlayerState();
  }
  
  void _respawn() async {
    dead = true;

    scale.x = 1; // makes player face right
    position = startingPosition - Vector2.all(32); // 96 - 64 to offset for the diff animation size
    current = PlayerState.appearing;

    await animationTicker?.completed;
    animationTicker?.reset();

    velocity = Vector2.zero();
    position = startingPosition;
    currentLives = maxLives;
    _updatePlayerState();
    Future.delayed(canMoveDuration, () => dead = false); // player can't move immediately after respawning
  }
  
  void _reachedCheckpoint() async {
    reachedCheckpoint = true;
    if (game.playSounds) FlameAudio.play('completed.wav', volume: game.soundVolume);
    if (scale.x > 0) { // if facing right
      position = position - Vector2.all(32);
    } else if (scale.x < 0){ // if facing left
      position = position + Vector2(32, -32);
    }

    current = PlayerState.disappearing;

    await animationTicker?.completed;
    animationTicker?.reset();

    reachedCheckpoint = false;
    position = Vector2.all(-640); // move player offscreen

    const waitToChangeDuration = Duration(milliseconds: 3);
    Future.delayed(waitToChangeDuration, () => game.loadNextLevel());
  }

  void collidedWithEnemy() {
    _playerHit();
    recentlyHit = true;
    Future.delayed(canMoveDuration, () => recentlyHit = false);
  }

}