import 'dart:async';

import 'package:flame/components.dart';
import 'package:platformer/pixel_game.dart';

class AnimatedHeart extends SpriteAnimationComponent with HasGameReference<PixelGame> {
  final bool isFull;

  AnimatedHeart({super.position, required this.isFull});

  final double stepTime = 0.1;
  final int amount = 8;
  final Vector2 textureSize = Vector2.all(32);

  @override
  FutureOr<void> onLoad() async {
    animation = await _loadAnimation(isFull);
    size = textureSize;
    anchor = Anchor.center;
    return super.onLoad();
  }
  
  Future<SpriteAnimation?> _loadAnimation(bool isFull) async {
    return SpriteAnimation.fromFrameData(
      game.images.fromCache('HUD/${isFull ? 'Full' : 'Empty'} Heart.png'),
      SpriteAnimationData.sequenced(
        amount: amount, 
        stepTime: stepTime, 
        textureSize: textureSize,
      ),
    );
  }
}