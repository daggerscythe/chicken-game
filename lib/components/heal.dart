import 'dart:async';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:platformer/pixel_game.dart';

class Heal extends SpriteAnimationComponent with HasGameReference<PixelGame>, CollisionCallbacks{
  Heal({ 
    position, 
    size
  }) : super(position: position, size: size);

  final double stepTime = 0.05; // animation time

  bool collected = false;

  @override
  FutureOr<void> onLoad() {
    // debugMode = true;
    priority = -1; // keeps heal behind the player

    add(RectangleHitbox(
      collisionType: CollisionType.passive, // checks collision with player, not each other
      )
    );
    animation = SpriteAnimation.fromFrameData(
      game.images.fromCache('Items/Heart.png'), 
      SpriteAnimationData.sequenced(
        amount: 6, 
        stepTime: 0.08, 
        textureSize: Vector2.all(32),
      ),
    );
    return super.onLoad();
  }
  
  void collidedWithPlayer() async {
    if (!collected) {
      collected = true;
      if (game.playSounds) FlameAudio.play('pickup.wav', volume: game.soundVolume);
      animation = SpriteAnimation.fromFrameData(
        game.images.fromCache('Items/Collected.png'), 
        SpriteAnimationData.sequenced(
          amount: 6, 
          stepTime: stepTime, 
          textureSize: Vector2.all(32),
          loop: false,
        ),
      );

      await animationTicker?.completed;
      removeFromParent();
    }
  }

}