import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:platformer/pixel_game.dart';

class AttackButton extends SpriteComponent with HasGameReference<PixelGame>, TapCallbacks{
  AttackButton();

  final margin = 32;
  final buttonSize= 64;

  @override
  FutureOr<void> onLoad() {
    sprite = Sprite(game.images.fromCache('HUD/Attack.png'));
    position = Vector2(
      game.size.x - (buttonSize * 2) - (margin * 2), // offset to left of jump
      game.size.y - (buttonSize * 2) - (margin * 2),
    );
    priority = 10;
    return super.onLoad();
  }

  @override
  void onTapDown(TapDownEvent event) {
    game.player!.attacking = true;
    super.onTapDown(event);
  }

  @override
  void onTapUp(TapUpEvent event) {
    game.player!.attacking = false;
    super.onTapUp(event);
  }
}