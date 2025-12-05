import 'dart:async';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:platformer/components/custom_hitbox.dart';
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

  int health = 2; // TODO: for presentation only
  bool shielded = false;
  bool isShieldAnimating = false;
  bool recentlyHit = false;
  double shieldCooldown = 5; // seconds
  double shieldTimer = 0;
  CustomHitbox hitbox = CustomHitbox(
    offsetX: 20,
    offsetY: 20,
    width: 50,
    height: 50,
  );

  @override
  FutureOr<void> onLoad() {
    priority = -10;
    // debugMode = true;
    player = game.player;
    add(RectangleHitbox(
      position: Vector2(hitbox.offsetX, hitbox.offsetY),
      size: Vector2(hitbox.width, hitbox.height),
    ));
    _loadAllAnimations();
    return super.onLoad();
  }

  @override
  void update(double dt) {
    if (!isShieldAnimating) {
      shieldTimer += dt;

      if (shieldTimer >= shieldCooldown) {
        _shieldToggle();
        shieldTimer = 0;
      }
    }
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

  Future<void> takeDamage() async {
    if (!shielded) {
      if (recentlyHit) return; // prevents spamming

      health--;
      recentlyHit = true;

      if (game.playSounds) FlameAudio.play('hit.wav', volume: game.soundVolume);
      
      animationTicker?.reset();
      isShieldAnimating = false;

      current = FireState.hit;
      await animationTicker?.completed;
      animationTicker?.reset();

      if (health <= 0) {
        removeFromParent();
        player.levelComplete();  
      } else {
        current = FireState.idle;
      }

      const hitCooldown = Duration(milliseconds: 500);
      Future.delayed(hitCooldown, () => recentlyHit = false);
    }    
  }

  Future<void> _shieldToggle() async {
    if (isShieldAnimating) return;

    isShieldAnimating = true;

    if (!shielded) {
      shielded = true;
      current = FireState.shieldDeploy;
      
      await animationTicker?.completed;
      animationTicker?.reset();

      current = FireState.shielded; 
    } else {
      shielded = false;
      current = FireState.shieldRemove;
      
      await animationTicker?.completed;
      animationTicker?.reset();

      current = FireState.idle; 
    }

    isShieldAnimating = false;
  }
  
  
  
}