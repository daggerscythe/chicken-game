import 'dart:async';

import 'package:flame/components.dart';

class Background extends SpriteComponent {
  final String imageName;
  Background({
    this.imageName = 'Gray', 
    position,
    size,
  }) : super(position: position, size: size);

  @override
  FutureOr<void> onLoad() async{
    priority = -1;
    sprite = await Sprite.load('Background/$imageName.png');
    return super.onLoad();
  }

  @override
  void onGameResize(Vector2 newSize) {
    super.onGameResize(newSize);
    size = newSize;
    position = Vector2.zero();
  }

}