import 'dart:async';
import 'package:flame/components.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:platformer/components/background.dart';
import 'package:platformer/components/chicken.dart';
import 'package:platformer/components/collision_block.dart';
import 'package:platformer/components/heal.dart';
import 'package:platformer/components/player.dart';
import 'package:platformer/components/saw.dart';
import 'package:platformer/pixel_game.dart';


class Level extends World with HasGameReference<PixelGame> {
  final String levelName;
  final Player player;
  Level({
    required this.levelName, 
    required this.player,
  });
  late TiledComponent level;
  List<CollisionBlock> collisionBlocks = [];

  @override
  FutureOr<void> onLoad() async {
    level = await TiledComponent.load('$levelName.tmx', Vector2.all(16));
    add(level);

    _addBackground();
    _spawningObjects();
    _addCollisions();

    return super.onLoad();
  }
  
  void _addBackground() {
    final backgroundLayer = level.tileMap.getLayer('background');
    
    if (backgroundLayer != null) {
      final backgroundName = backgroundLayer.properties.getValue('BackgroundImage');
      final background = Background(
        imageName: backgroundName ?? 'Gray',
        position: Vector2(0, 0), 
        size: Vector2(
          level.tileMap.map.width * 16,
          level.tileMap.map.height * 16,
        ),
      );
      add(background);
    }
  }
  
  void _spawningObjects() {
    final spawnPointLayer = level.tileMap.getLayer<ObjectGroup>('spawnpoints');
    
    if (spawnPointLayer != null) {
      for (final spawnPoint in spawnPointLayer.objects) {
        switch (spawnPoint.class_){
          case 'Player':
            player.position = Vector2(spawnPoint.x, spawnPoint.y);
            player.scale.x = 1; // always facing right
            add(player);
            break;
          case 'Heal':
            final heal = Heal(
              position: Vector2(spawnPoint.x + 16, spawnPoint.y + 16),
              size: Vector2(spawnPoint.width - 16, spawnPoint.height - 16),
            );
            add(heal);
            break;
          case 'Saw':
            final isVertical = spawnPoint.properties.getValue('isVertical');
            final offsetNeg = spawnPoint.properties.getValue('offsetNeg');
            final offsetPos = spawnPoint.properties.getValue('offsetPos');
            final saw = Saw(
              isVertical: isVertical,
              offsetNeg: offsetNeg,
              offsetPos: offsetPos,
              position: Vector2(spawnPoint.x, spawnPoint.y),
              size: Vector2(spawnPoint.width, spawnPoint.height),
            );
            add(saw);
            break;
          case 'Chicken':
            final offsetNeg = spawnPoint.properties.getValue('offsetNeg');
            final offsetPos = spawnPoint.properties.getValue('offsetPos');
            final chicken = Chicken(
              position: Vector2(spawnPoint.x, spawnPoint.y - 32),
              size: Vector2(64, 64),
              offsetNeg: offsetNeg,
              offsetPos: offsetPos,
            );
            add(chicken);
            break;
          default:
        }
      } 
    }
  }
  
  void _addCollisions() {
    final collisionLayer = level.tileMap.getLayer<ObjectGroup>('collisions');
    if (collisionLayer != null) {
      for (final collision in collisionLayer.objects) {
        switch (collision.class_) {
          case 'Platform':
            final platform = CollisionBlock(
              position: Vector2(collision.x, collision.y), 
              size: Vector2(collision.width, collision.height),
              isPlatform: true,
            );
            collisionBlocks.add(platform);
            add(platform);
            break;
          default:
          final block = CollisionBlock(
            position: Vector2(collision.x, collision.y), 
            size: Vector2(collision.width, collision.height),
          );
          collisionBlocks.add(block);
          add(block);
        }
      }
    }
    player.collisionBlocks = collisionBlocks; // makes the actor aware of the collisions
  }

}