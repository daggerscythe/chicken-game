import 'dart:async';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:platformer/pixel_game.dart';

class Menu extends PositionComponent with HasGameReference<PixelGame>, TapCallbacks {
  final PixelGame game;

  Menu({required this.game});

  late SpriteComponent levelsButton;
  late SpriteComponent volumeButton;
  late SpriteComponent settingsButton;

  late final SpriteComponent tempSprite;

  @override
  void onMount() {
    super.onMount();
    final viewportSize = game.cam.viewport.size;
    position = Vector2(viewportSize.x - 100, 20); // top-right
  }


  @override
  FutureOr<void> onLoad() {
    priority = 100;
    // top-right corner
    final viewportSize = game.cam.viewport.size;
    // position = Vector2(viewportSize.x - 100, 100);
    size = Vector2(200, 50);
    anchor = Anchor.topRight;
    position = Vector2(viewportSize.x - 400, 200);


    // levels button
    levelsButton = MenuSpriteButton(
      sprite: Sprite(game.images.fromCache('Items/Rotisserie.png')), 
      position: Vector2.zero(), 
      size: Vector2.all(40), 
      onPressed: _showLevelsMenu,
    );

    // volume button
    volumeButton = VolumeButton(
      game: game, 
      position: Vector2(50, 0), 
      size: Vector2.all(40),
    );

    // settings button
    settingsButton = MenuSpriteButton(
      sprite: Sprite(game.images.fromCache('Menu/Buttons/Settings.png')),
      position: Vector2(100, 0),
      size: Vector2.all(40),
      onPressed: _showSettings,
    );

    addAll([levelsButton, volumeButton, settingsButton]);

    print("menu is at ${position} size: ${size}");
    print("levels button is at ${levelsButton.position} size: ${levelsButton.size}");

    return super.onLoad();
  }

  void _showLevelsMenu() {
    final overlay = _LevelsOverlay(game: game);
    game.cam.viewport.add(overlay);
  }

  void _showSettings() {
    final settings = _SettingsOverlay(game: game);
    game.cam.viewport.add(settings);
  }

}

class _LevelsOverlay extends PositionComponent {
  final PixelGame game;

  _LevelsOverlay({required this.game});

  @override
  FutureOr<void> onLoad() {
    size = game.size;
    position = Vector2.zero();

    // opaque background
    add(RectangleComponent(
      size: size,
      paint: Paint()..color = Color(0x80000000),
    ));

    // level buttons
    for (int i = 0; i < game.levels.length; i++) {
      final button = LevelSelectButton(
        sprite: Sprite(game.images.fromCache('Menu/Levels/0${i+1}.png')), 
        position: Vector2(game.size.x / 2 - 100, 100 + i * 60), 
        size: Vector2(200, 50), 
        onPressed: () {
          game.currentLevelIndex = i;
          game.loadLevel();
          removeFromParent();
        }
      );
      add(button);
    }

    final closeButton = CloseButton(
      sprite: Sprite(game.images.fromCache('Menu/Buttons/Close.png')),
      position: Vector2(game.size.x - 40, 10), 
      size: Vector2.all(30), 
      onTap: () => removeFromParent(),
    );
    add(closeButton);

    return super.onLoad();
  }
}

class _SettingsOverlay extends PositionComponent with TapCallbacks {
  final PixelGame game;

  _SettingsOverlay({required this.game});

  @override
  FutureOr<void> onLoad() {
    final textRenderer = TextPaint(
      style: TextStyle(fontSize: 16, color: Colors.white)
    );
    
    size = Vector2(300, 200);
    position = Vector2(game.size.x / 2 - 150, game.size.y / 2 - 100);

    // background
    add(RectangleComponent(
      size: size,
      paint: Paint()..color = Color(0xFF2D2B3E),
    ));

    // volume slider
    // TODO: add slider logic

    // mobile controls toggle
    
    final toggleText = TextComponent(
      text: 'Mobile Controls: ${game.showControls ? 'ON' : 'OFF'}',
      position: Vector2(20, 100),
      textRenderer: textRenderer,
    );

    final toggleButton = SettingsButton(
      game: game, 
      textComponent: toggleText, 
      position: Vector2(200, 100), 
      size: Vector2(50, 30)
    );

    final closeButton = CloseButton(
      sprite: Sprite(game.images.fromCache('Menu/Buttons/Close.png')),
      position: Vector2(game.size.x - 40, 10), 
      size: Vector2.all(30), 
      onTap: () => removeFromParent(),
    );

    addAll([toggleText, toggleButton, closeButton]);

    return super.onLoad();
  }
}

class MenuSpriteButton extends SpriteComponent with TapCallbacks {
  final VoidCallback onPressed;
  MenuSpriteButton({
    required super.sprite,
    required super.position,
    required super.size,
    required this.onPressed,
  });

  @override
  void onTapDown(TapDownEvent event) => onPressed();
}

class LevelSelectButton extends SpriteComponent with TapCallbacks {
  final VoidCallback onPressed;
  LevelSelectButton({
    required super.sprite,
    required super.position,
    required super.size,
    required this.onPressed,
  });

  @override
  void onTapDown(TapDownEvent event) => onPressed();
}

class VolumeButton extends SpriteComponent with TapCallbacks {
  final PixelGame game;
  VolumeButton({
    required this.game,
    required super.position,
    required super.size,
  }) : super(
          sprite: Sprite(game.images.fromCache(
              'Menu/Buttons/${game.playSounds ? 'VolumeOn' : 'VolumeOff'}.png')),
        );

  @override
  void onTapDown(TapDownEvent event) {
    game.playSounds = !game.playSounds;
    sprite = Sprite(
      game.images.fromCache(
        'Menu/Buttons/${game.playSounds ? 'VolumeOn' : 'VolumeOff'}.png',
      ),
    );
  }
}

class SettingsButton extends RectangleComponent with TapCallbacks {
  final PixelGame game;
  final TextComponent textComponent;
  SettingsButton({
    required this.game,
    required this.textComponent,
    required super.position,
    required super.size,
  }) : super(paint: Paint());

  @override
  FutureOr<void> onLoad() {
    _updateAppearance();
    return super.onLoad();
  }

  @override
  void onTapDown(TapDownEvent event) {
    game.showControls = !game.showControls;
    _updateAppearance();
    textComponent.text =
        'Mobile Controls: ${game.showControls ? 'ON' : 'OFF'}';
  }

  void _updateAppearance() {
    paint.color = game.showControls ? Colors.green : Colors.grey;
  }
}

class CloseButton extends SpriteComponent with TapCallbacks {
  final VoidCallback onTap;
  CloseButton({
    required super.sprite,
    required super.position,
    required super.size,
    required this.onTap,
  });

  @override
  void onTapDown(TapDownEvent event) => onTap();
}