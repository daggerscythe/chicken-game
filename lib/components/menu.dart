import 'dart:async';

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

  _LevelsOverlay? _levelsOverlay;
  _SettingsOverlay? _settingsOverlay;

  @override
  FutureOr<void> onLoad() {
    priority = 100;

    // levels button
    levelsButton = MenuSpriteButton(
      sprite: Sprite(game.images.fromCache('Menu/Buttons/Levels.png')), 
      position: Vector2.zero(), 
      size: Vector2.all(30), 
      onPressed: _toggleLevelsMenu,
    );

    // volume button
    volumeButton = VolumeButton(
      game: game, 
      position: Vector2(40, 0), 
      size: Vector2.all(30),
    );

    // settings button
    settingsButton = MenuSpriteButton(
      sprite: Sprite(game.images.fromCache('Menu/Buttons/Settings.png')),
      position: Vector2(80, 0),
      size: Vector2.all(30),
      onPressed: _toggleSettings,
    );

    addAll([levelsButton, volumeButton, settingsButton]);

    return super.onLoad();
  }

  void _toggleLevelsMenu() {
    if (_levelsOverlay == null || !_levelsOverlay!.isMounted) {
      // create a new overlay
      _levelsOverlay = _LevelsOverlay(game: game, menu: this);
      game.cam.viewport.add(_levelsOverlay!);
    } else {
      // hide overlay
      _levelsOverlay!.removeFromParent();
      _levelsOverlay = null;
    }
    
  }

  void _toggleSettings() {
    if (_settingsOverlay == null || !_settingsOverlay!.isMounted) {
      // create a new overlay
      _settingsOverlay = _SettingsOverlay(game: game, menu: this);
      game.cam.viewport.add(_settingsOverlay!);
    } else {
      // hide overlay
      _settingsOverlay!.placeholder.removeFromParent();
      _settingsOverlay!.placeholderBackground.removeFromParent();
      _settingsOverlay = null;
    }
  }

}

class _LevelsOverlay extends PositionComponent {
  final PixelGame game;
  final Menu menu;

  _LevelsOverlay({
    required this.game, 
    required this.menu
  });

  @override
  FutureOr<void> onLoad() {
    priority = 1000;

    // level buttons
    for (int i = 0; i < game.levels.length; i++) {
      final button = LevelSelectButton(
        sprite: Sprite(game.images.fromCache('Menu/Levels/0${i+1}.png')), 
        position: Vector2(menu.position.x - 100 + i * 50, menu.levelsButton.y + 40), 
        size: Vector2.all(40), 
        onPressed: () {
          game.currentLevelIndex = i;
          game.loadLevel();
          removeFromParent();
        }
      );
      add(button);
    }

    return super.onLoad();
  }
}

class _SettingsOverlay extends PositionComponent with TapCallbacks {
  final PixelGame game;
  final Menu menu;

  _SettingsOverlay({
    required this.game,
    required this.menu
  });

  late TextComponent placeholder;
  late RectangleComponent placeholderBackground;

  @override
  FutureOr<void> onLoad() {
     final textRenderer = TextPaint(
      style: TextStyle(
        fontFamily: 'Daydream',
        fontSize: 16, 
        color: Color.fromARGB(255, 255, 255, 255),
      ),
    );
    
    size = game.size;
    position = Vector2.zero();

    // TODO: volume slider

    // TODO: mobile controls toggle

    placeholder = TextComponent(
      text: 'Settings Coming Soon!',
      position: Vector2(size.x / 2, size.y / 2),
      textRenderer: textRenderer,
      anchor: Anchor.center
    );

    placeholderBackground = RectangleComponent(
      position: placeholder.position.clone(),
      size: placeholder.size + Vector2(50, 20),
      paint: Paint()..color = Colors.black.withAlpha(150),
      anchor: Anchor.center,
    );
    
    game.addAll([placeholderBackground, placeholder]);

    return super.onLoad();
  }

  @override
  void onGameResize(Vector2 size) {
    placeholder.position = size / 2;
    placeholderBackground.position = size / 2;
    super.onGameResize(size);
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