import 'dart:async';
import 'package:flame/events.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:platformer/components/healthbar.dart';
import 'package:platformer/components/jump_button.dart';
import 'package:platformer/components/menu.dart';

import 'components/level.dart';
import 'components/player.dart';

class PixelGame extends FlameGame 
  with 
    HasKeyboardHandlerComponents,
    DragCallbacks, 
    HasCollisionDetection, 
    TapCallbacks {

  @override 
  Color backgroundColor() => const Color(0xFF211F30);
  late CameraComponent cam;
  late JoystickComponent joystick;
  Level? currentLevel;
  CameraComponent? currentCamera;
  bool showControls = false; // TODO: be able to flip in settings
  bool playSounds = false; // TODO: be able to flip in settings ALSO CHANGE TO TRUE
  double soundVolume = 0.05; // TODO: be able to set in settings
  List<String> levels = ['level_01', 'level_02', 'level_03']; // add more levels later
  int currentLevelIndex = 0; // TODO: be able to pick level
  late Player player;
  
  @override
  FutureOr<void> onLoad() async {   
    await images.loadAllImages(); // use loadAll if you have many images for optimization

    loadLevel();

    // for mobile controls
    if (showControls) {
      addJoystick();
      add(JumpButton());
    }

    return super.onLoad();
  }

  @override
  void update(double dt) {
    if (showControls) {
      updateJoystick();
    }
    super.update(dt);
  }
  
  void addJoystick() {
    joystick = JoystickComponent(
      priority: 10,
      knob: SpriteComponent(
        sprite: Sprite(
          images.fromCache('HUD/Knob.png'),
        ),
      ),
      // knobRadius: 14, // controls how far the knob goes out of the joystick
      background: SpriteComponent(
        sprite: Sprite(
          images.fromCache('HUD/Joystick.png'),
        ),
      ),
      margin: const EdgeInsets.only(left: 32, bottom: 32),
    );

    add(joystick);
  }
  
  void updateJoystick() {
    switch (joystick.direction) {
      case JoystickDirection.left:
      case JoystickDirection.upLeft:
      case JoystickDirection.downLeft:
        player.horizontalMovement = -1;
        break;
      case JoystickDirection.right:
      case JoystickDirection.upRight:
      case JoystickDirection.downRight:
        player.horizontalMovement = 1;
        break;
      default:
        player.horizontalMovement = 0;
        break;
    }
  }

  void loadNextLevel() {
    if (currentLevelIndex < levels.length - 1) {
      currentLevelIndex++;
      loadLevel();
    } else {
      // loops through levels
      currentLevelIndex = 0;
      loadLevel();
    }
  }
  
  void loadLevel() async {
    Future.delayed(const Duration(seconds: 1), () async {
      // remove old level
      currentLevel?.removeFromParent();
      currentCamera?.removeFromParent();

      Level world = Level(
        levelName: levels[currentLevelIndex]
      );
      currentLevel = world;
      
      //TODO: actually make the resolution fixed??
      cam = CameraComponent.withFixedResolution(
        world: world, 
        width: 640, 
        height: 360
      );
      cam.viewfinder.anchor = Anchor.topLeft;
      currentCamera = cam;

      cam.viewport.removeWhere((c) => c is Menu); // avoid duplicates
      final menu = Menu(game: this);
      cam.viewport.add(menu);

      addAll([cam, world]);

      await Future.delayed(Duration(milliseconds: 50));

      

      print("Camera viewport size: ${cam.viewport.size}");
      print("Game size: ${size}");

      await Future.delayed(Duration(milliseconds: 100));
    });
  }

  void setPlayer(Player newPlayer) {
    player = newPlayer;

    // refresh health bar
    cam.viewport.removeWhere((component) => component is HealthBar);
    final health = HealthBar(player: player)..position = Vector2(60, 5);
    cam.viewport.add(health);

    
  }
  
}