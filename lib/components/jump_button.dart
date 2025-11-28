import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:platformer/pixel_game.dart';

class JumpButton extends SpriteComponent with HasGameReference<PixelGame>, TapCallbacks{
  JumpButton();

  final margin = 32;
  final buttonSize= 64;

  @override
  FutureOr<void> onLoad() {
    sprite = Sprite(game.images.fromCache('HUD/Jump.png'));
    position - Vector2(
      game.size.x - buttonSize - margin,
      game.size.y - buttonSize - margin,
    );
    priority = 10;
    return super.onLoad();
  }

  @override
  void onTapDown(TapDownEvent event) {
    game.player.hasJumped = true;
    super.onTapDown(event);
  }

  @override
  void onTapUp(TapUpEvent event) {
    game.player.hasJumped = false;
    super.onTapUp(event);
  }
}