import 'dart:async';

import 'package:flame/components.dart';
import 'package:platformer/components/heart.dart';
import 'package:platformer/components/player.dart';
import 'package:platformer/pixel_game.dart';

class HealthBar extends PositionComponent with HasGameReference<PixelGame> {
  final Player player;
  final List<AnimatedHeart> hearts = [];

  HealthBar({required this.player});

  final double margin = 36.0;
  int _currentHealth = 0;

  @override
  FutureOr<void> onLoad() {
    priority = 10;
    _updateHearts();
    return super.onLoad();
  }

  @override
  void update(double dt) {
    if (hearts.length != player.maxLives || _currentHealth != player.currentLives){
      _updateHearts();
      _currentHealth = player.currentLives;
    }
    super.update(dt);
  }

  void _updateHearts() {
    // remove old hearts
    for (final heart in hearts) {
      heart.removeFromParent();
    }
    hearts.clear();

    for (int i = 0; i < player.maxLives; i++) {
      final heart = AnimatedHeart(
        position: Vector2(i * margin, 16),
        isFull: i < player.currentLives,
      );
      add(heart);
      hearts.add(heart);
    }
  }

  
}