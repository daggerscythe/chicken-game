import 'dart:async';
import 'dart:ui';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/text.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/services.dart';
import 'package:platformer/components/attack_hitbox.dart';
import 'package:platformer/components/chicken.dart';
import 'package:platformer/components/collision_block.dart';
import 'package:platformer/components/custom_hitbox.dart';
import 'package:platformer/components/fire.dart';
import 'package:platformer/components/fireball.dart';
import 'package:platformer/components/flake_projectile.dart';
import 'package:platformer/components/heal.dart';
import 'package:platformer/components/saw.dart';
import 'package:platformer/components/shaker.dart';
import 'package:platformer/components/utils.dart';
import 'package:platformer/pixel_game.dart';

enum PlayerState {idle, running, jumping, falling, hit, slashing, appearing, disappearing}

class Player extends SpriteAnimationGroupComponent with HasGameReference<PixelGame>, KeyboardHandler, CollisionCallbacks, TapCallbacks {
  String character;
  String reward;
  Player({
    position, 
    this.character = 'Chef',
    this.reward = 'Chef Jacket',
  }) : super(position: position);

  final double stepTime = 0.05;
  static const canMoveDuration = Duration(milliseconds: 400);
  late final SpriteAnimation idleAnimation;
  late final SpriteAnimation runningAnimation;
  late final SpriteAnimation jumpingAnimation;
  late final SpriteAnimation fallingAnimation;
  late final SpriteAnimation hitAnimation;
  late final SpriteAnimation slashingAnimation;
  late final SpriteAnimation appearingAnimation;
  late final SpriteAnimation disappearingAnimation;

  final double _gravity = 9.8;
  final double _jumpForce = 300;
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
  bool defeatedBoss= false;
  bool recentlyHit = false;
  bool attacking = false;
  AttackHitbox? attackHitbox;
  List<CollisionBlock> collisionBlocks = [];
  CustomHitbox hitbox = CustomHitbox(
    offsetX: 8, 
    offsetY: 4, 
    width: 18, 
    height: 28,
  );

  double fixedDeltaTime = 1 / 60; // 60 fps
  double accumulatedTime = 0;

  @override
  FutureOr<void> onLoad() {
    _loadAllAnimations();
    debugMode = true; // to show player collision
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
      if (!dead && !defeatedBoss) {
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
    attacking = keysPressed.contains(LogicalKeyboardKey.keyE)
      || keysPressed.contains(LogicalKeyboardKey.enter);

    return super.onKeyEvent(event, keysPressed);
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (!defeatedBoss) {
      if (other is Heal){
        other.collidedWithPlayer();
        if (currentLives != maxLives) currentLives++;
      }
      if (other is Saw) _playerHit();
    }
    super.onCollisionStart(intersectionPoints, other);
  }

  void _loadAllAnimations() {
    idleAnimation = _spriteAnimation('Idle', 11, 32, 32);
    runningAnimation = _spriteAnimation('Run', 12, 32, 32);
    jumpingAnimation = _spriteAnimation('Jump', 1, 32, 32);
    fallingAnimation = _spriteAnimation('Fall', 1, 32, 32);
    hitAnimation = _spriteAnimation('Hit', 7, 32, 32)..loop = false; // only plays once
    slashingAnimation = _spriteAnimation('Slash', 9, 64, 32)..loop = false; // only plays once
    appearingAnimation = _spriteAnimation('Appearing', 7, 96, 96)..loop = false;
    disappearingAnimation = _spriteAnimation('Disappearing', 7, 96, 96)..loop = false;
    
    animations = {
      PlayerState.idle: idleAnimation,
      PlayerState.running: runningAnimation,
      PlayerState.jumping: jumpingAnimation,
      PlayerState.falling: fallingAnimation,
      PlayerState.hit: hitAnimation,
      PlayerState.slashing: slashingAnimation,
      PlayerState.appearing: appearingAnimation,
      PlayerState.disappearing: disappearingAnimation,
    };

    // set current animation
    current = PlayerState.idle;
  }
  
  SpriteAnimation _spriteAnimation(String state, int amount, int width, int height) {
    return SpriteAnimation.fromFrameData(
      game.images.fromCache('Main Characters/$character/$state (${width}x$height).png'), 
        SpriteAnimationData.sequenced(
          amount: amount, 
          stepTime: stepTime, 
          textureSize: Vector2(width.toDouble(), height.toDouble()),
      )
    );
  }
  
  void _updatePlayerState() {
    PlayerState playerState = PlayerState.idle;

    // wait for attack animation to finish
    if (current == PlayerState.slashing && !(animationTicker?.isLastFrame ?? true)) {
      return;
    }

    if (attacking) {
      if (game.playSounds) FlameAudio.play('slash.wav', volume: game.soundVolume);
      current = PlayerState.slashing;
      _attack();
      return;
    }
    
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
    // cant move during attacking
    if (current == PlayerState.slashing) {
      velocity.x = 0;
      attacking = false;
      return;
    }
    // can only jump on ground
    if (hasJumped && isOnGround) _playerJump(dt);
    // can only move when not recently hit
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
      } else if (block.isBlock){
        if (checkCollision(this, block)) {
          if (velocity.y < 0) {
            velocity.y = 0;
            position.y = block.y + block.height;
            break;          
          }
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
  
  void levelComplete() async {
    defeatedBoss = true;
    if (game.playSounds) FlameAudio.play('complete.mp3', volume: game.soundVolume);

    if (scale.x > 0) { // if facing right
      position = position - Vector2.all(32);
    } else if (scale.x < 0){ // if facing left
      position = position + Vector2(32, -32);
    }

    current = PlayerState.disappearing;
    await animationTicker?.completed;
    animationTicker?.reset();

    position = Vector2.all(-640); // move player offscreen

    Future.delayed(const Duration(milliseconds: 500), () => _showCompletionScreen());
  }

  void collidedWithEnemy() {
    _playerHit();
    recentlyHit = true;
    Future.delayed(canMoveDuration, () => recentlyHit = false);
  }
  
  void _attack() async {
    final attackDuration = const Duration(milliseconds: 300);

    _removeAttackHitbox();
    
    attackHitbox = AttackHitbox(
      owner: this,
      onHit: (other) {
        if (other is Chicken) other.takeDamage();
        if (other is Shaker) other.takeDamage();
        if (other is FlakeProjectile) {
          if (game.playSounds) FlameAudio.play('hit.wav', volume: game.soundVolume);
          other.removeFromParent();
        } 
        if (other is Fireball) {
          if (game.playSounds) FlameAudio.play('hit.wav', volume: game.soundVolume);
          other.removeFromParent();
        } 
        if (other is Fire) other.takeDamage();
      },
      position: Vector2(scale.x > 0 ? hitbox.width : -hitbox.width + 30, 0), // TODO: remove magic number
      size: Vector2(40, 30),
    );

    add (attackHitbox!);

    Future.delayed(attackDuration, () => _removeAttackHitbox());

    animationTicker?.reset();
    attacking = false;
  }

  void _removeAttackHitbox() {
    attackHitbox?.removeFromParent();
    attackHitbox = null;
  }
  
  void _showCompletionScreen() {
    Vector2 cameraCenter = game.cam.viewport.virtualSize / 2;

    // pop up screen
    final popUp = SpriteAnimationComponent( 
      animation: SpriteAnimation.fromFrameData(
        game.images.fromCache('HUD/Popup.png'), 
        SpriteAnimationData.sequenced(
          amount: 8, 
          stepTime: stepTime, 
          textureSize: Vector2.all(96),
        ),
      ),
      position: cameraCenter,
      size: Vector2.all(350),
      anchor: Anchor.center,
    )..priority = 100;
    
    // item
    final item = SpriteComponent(
      sprite: Sprite(game.images.fromCache('Items/$reward.png')),
      position: cameraCenter,
      size: Vector2.all(100),
      anchor: Anchor.center,
    )..priority = 101;

    final textRenderer = TextPaint(style: TextStyle(fontSize: 16, color: Color.fromARGB(255, 255, 255, 255)));
    // congrats text
    final text = TextComponent(
      text: "Nice job! You get a $reward!",
      position: cameraCenter - Vector2(0, -100),
      anchor: Anchor.center,
      textRenderer: textRenderer,
    )..priority = 102;

    // press anything text
    final hintText = TextComponent(
      text: "Press anything to continue",
      position: cameraCenter - Vector2(0, -150),
      anchor: Anchor.center,
      textRenderer: textRenderer,
    )..priority = 102;

    game.cam.viewport.addAll([popUp, item, text, hintText]);

    late _CompletionInputHandler inputHandler;

    inputHandler = _CompletionInputHandler(onContinue: () {
      popUp.removeFromParent();
      item.removeFromParent();
      text.removeFromParent();
      hintText.removeFromParent();
      inputHandler.removeFromParent();
      game.loadNextLevel();
    });
    
    game.add(inputHandler);
  }
  
}

class _CompletionInputHandler extends Component with TapCallbacks, KeyboardHandler{
  final VoidCallback onContinue;
  bool _finished = false;

  _CompletionInputHandler({required this.onContinue});

  @override
  bool onTapDown(TapDownEvent event) {
    _trigger();
    return true;
  }

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (event is KeyDownEvent) {
      _trigger();
      return true;
    }
    return false;
  }

  void _trigger() {
    if (_finished) return;
    _finished = true;
    onContinue();
  }
}

