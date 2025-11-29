import 'dart:async';

import 'package:flame/components.dart';
import 'package:platformer/pixel_game.dart';

class Background extends PositionComponent with HasGameReference<PixelGame> {
  final String imageName;
  late final SpriteComponent backgroundSprite;
  
  Background({
    required this.imageName, 
    super.position,
    super.size,
  });

  @override
  FutureOr<void> onLoad() async{
    priority = -100;
    final sprite = await Sprite.load('Background/$imageName.png');
    backgroundSprite = SpriteComponent(
      sprite: sprite,
      position: Vector2.zero(),
      size: game.canvasSize,
    );
    add(backgroundSprite);
    return super.onLoad();
  }

  @override
  void onGameResize(Vector2 newSize) {
    super.onGameResize(newSize);
    // size = newSize;
    position = Vector2.zero();
    backgroundSprite.size = game.canvasSize;
    size = game.canvasSize;
  }

}