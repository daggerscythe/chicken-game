import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:platformer/pixel_game.dart';

class Menu extends PositionComponent with HasGameReference<PixelGame>, TapCallbacks {
  final PixelGame game;

  Menu({required this.game});

  late SpriteComponent levelsButton;
  late SpriteComponent volumeButton;
  late SpriteComponent settingsButton;

  _LevelsOverlay? _levelsOverlay;
  SettingsOverlay? _settingsOverlay;

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
      _settingsOverlay = SettingsOverlay(game: game, menu: this);
      game.cam.viewport.add(_settingsOverlay!);
    } else {
      _settingsOverlay!.removeFromParent();
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

class SettingsOverlay extends PositionComponent with TapCallbacks, KeyboardHandler, HasGameReference<PixelGame> {
  final PixelGame game;
  final Menu menu;

  SettingsOverlay({
    required this.game,
    required this.menu
  });

  late TextComponent placeholder;
  late RectangleComponent placeholderBackground;

  static const double _vpWidth = 640;
  static const double _vpHeight = 360;

  @override
  FutureOr<void> onLoad() {
    priority = 1000;
    size = Vector2(_vpWidth, _vpHeight);
    position = Vector2.zero();

     final textRenderer = TextPaint(
      style: TextStyle(
        fontFamily: 'Daydream',
        fontSize: 16, 
        color: Color(0XFFFFFFFF),
      ),
    );

    // dim background panel
    add(RectangleComponent(
      position: Vector2(_vpWidth / 2, _vpHeight / 2),
      size: Vector2(220, 100),
      anchor: Anchor.center,
      paint: Paint()..color = Colors.black.withAlpha(180),
    ));

    // title
    add(TextComponent(
      text: 'Settings',
      textRenderer: textRenderer,
      position: Vector2(size.x / 2, size.y / 2 - 35),
      anchor: Anchor.center,
    ));

    // volume label
    add(TextComponent(
      text: 'Volume',
      textRenderer: textRenderer,
      position: Vector2(size.x / 2 - 80, size.y / 2 - 10),
      anchor: Anchor.centerLeft,
    ));

    // slider
    add(VolumeSlider(
      game: game,
      position: Vector2(size.x / 2 - 80, size.y / 2 + 15),
      sliderWidth: 160,
    ));

    // close button
    add(MenuSpriteButton(
      sprite: Sprite(game.images.fromCache('Menu/Buttons/Close.png')),
      position: Vector2(size.x / 2 + 95, size.y / 2 - 45),
      size: Vector2.all(16),
      onPressed: removeFromParent,
    ));

    return super.onLoad();
  }

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (event is KeyDownEvent && 
        event.logicalKey == LogicalKeyboardKey.escape) {
      removeFromParent();
      menu._settingsOverlay = null;
      return true;
    }
    return false;
  }

  // make only the menu interactive, otherwise it takes up
  // full screen and makes other buttons un-tappable 
  @override
  bool containsLocalPoint(Vector2 point) {
    final panelTopLeft = Vector2(_vpWidth / 2 - 110, _vpHeight / 2 - 50);
    final panelBottomRight = Vector2(_vpWidth / 2 + 110, _vpHeight / 2 + 50);
    return point.x >= panelTopLeft.x && point.x <= panelBottomRight.x &&
          point.y >= panelTopLeft.y && point.y <= panelBottomRight.y;
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

class VolumeSlider extends PositionComponent with DragCallbacks, HasGameReference<PixelGame> {
  final PixelGame game;
  final double sliderWidth;

  static const double _trackHeight = 4;
  static const double _knobRadius = 8;
  static const double _hitPadding = 16;

  late RectangleComponent _filledTrack;
  late CircleComponent _knob;

  VolumeSlider({
    required this.game,
    required super.position,
    required this.sliderWidth,
  }) : super(size: Vector2(sliderWidth, _knobRadius * 2 + _hitPadding));

  @override
  FutureOr<void> onLoad() {
    // empty track
    add(RectangleComponent(
      position: Vector2(0, size.y / 2 - _trackHeight / 2),
      size: Vector2(sliderWidth, _trackHeight),
      paint: Paint()..color = Colors.white24,
    ));

    final initialX = game.soundVolume.clamp(0.0, 1.0) * sliderWidth;

    // filled portion
    _filledTrack = RectangleComponent(
      position: Vector2(0, size.y / 2 - _trackHeight / 2),
      size: Vector2(initialX, _trackHeight),
      paint: Paint()..color = Colors.white,
    );
    add(_filledTrack);

    // knob
    _knob = CircleComponent(
      radius: _knobRadius,
      position: Vector2(initialX, size.y / 2),
      anchor: Anchor.center,
      paint: Paint()..color = Colors.white,
    );
    add(_knob);

    return super.onLoad();
  }

  void _updateFromX(double localX) {
    final clamped = localX.clamp(0.0, sliderWidth);
    game.soundVolume = clamped / sliderWidth;
    _filledTrack.size = Vector2(clamped, _trackHeight);
    _knob.position = Vector2(clamped, size.y / 2);
  }

  @override
  void onDragStart(DragStartEvent event) {
    _updateFromX(event.localPosition.x);
    super.onDragStart(event);
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    final currentX = game.soundVolume.clamp(0.0, 1.0) * sliderWidth;
    _updateFromX(currentX + event.canvasDelta.x);
    super.onDragUpdate(event);
  }

}