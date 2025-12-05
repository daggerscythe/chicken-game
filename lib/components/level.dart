import 'dart:async';
import 'package:flame/components.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:platformer/components/background.dart';
import 'package:platformer/components/chicken.dart';
import 'package:platformer/components/collision_block.dart';
import 'package:platformer/components/corner_fire.dart';
import 'package:platformer/components/fire.dart';
import 'package:platformer/components/heal.dart';
import 'package:platformer/components/heal_manager.dart';
import 'package:platformer/components/player.dart';
import 'package:platformer/components/saw.dart';
import 'package:platformer/components/shaker.dart';
import 'package:platformer/pixel_game.dart';


class Level extends World with HasGameReference<PixelGame> {
  final String levelName;
  late Player player;
  late Shaker shaker;
  Level({
    required this.levelName,
  });
  late TiledComponent level;
  List<CollisionBlock> collisionBlocks = [];
  HealManager healManager = HealManager();

  @override
  FutureOr<void> onLoad() async {
    level = await TiledComponent.load('$levelName.tmx', Vector2.all(16));
    add(level);

    _addBackground();
    _spawningObjects();
    _addCollisions();

    add(healManager);

    _spawnInitialHeals();

    return super.onLoad();
  }
  
  void _addBackground() {
    final backgroundLayer = level.tileMap.getLayer('background');
    
    if (backgroundLayer != null) {
      final backgroundName = backgroundLayer.properties.getValue('BackgroundImage');
      final background = Background(
        imageName: backgroundName ?? 'Gray',
        position: Vector2.zero(), 
        size: game.canvasSize,
      );
      game.add(background);
    }
  }
  
  void _spawningObjects() {
    final spawnPointLayer = level.tileMap.getLayer<ObjectGroup>('spawnpoints');
    
    if (spawnPointLayer != null) {
      for (final spawnPoint in spawnPointLayer.objects) {
        switch (spawnPoint.class_){
          case 'Player':
            player = Player(
              character: spawnPoint.name,
              reward: spawnPoint.properties.getValue('reward'),
              position: Vector2(spawnPoint.x, spawnPoint.y),
            );
            player.scale.x = 1; // always facing right
            add(player);
            game.setPlayer(player);
            break;
          case 'Heal':
            healManager.addSpawnPoint(
              Vector2(spawnPoint.x + 6, spawnPoint.y + 6)
            );
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
            final chicken = Chicken(
              position: Vector2(spawnPoint.x, spawnPoint.y),
            );
            add(chicken);
            break;
          case 'Shaker':
            final shaker = Shaker(
              name: spawnPoint.name,
              position: Vector2(spawnPoint.x, spawnPoint.y),
              size: Vector2(spawnPoint.width, spawnPoint.height),
            );
            add(shaker);
          case 'Fire':
            final fire = Fire(
              position: Vector2(spawnPoint.x, spawnPoint.y),
              size: Vector2(spawnPoint.width, spawnPoint.height),
            );
            add(fire);
            break;
          case 'CornerFire':
            final cornerFire = CornerFire(
              corner: spawnPoint.name,
              position: Vector2(spawnPoint.x, spawnPoint.y),
              size: Vector2(spawnPoint.width, spawnPoint.height),
            );
            add(cornerFire);
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
          case 'Block':
            final block = CollisionBlock(
              position: Vector2(collision.x, collision.y), 
              size: Vector2(collision.width, collision.height),
              isBlock: true,
            );
            collisionBlocks.add(block);
            add(block);
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
  
  void _spawnInitialHeals() {
    for (int i = 0; i < HealManager.maxHeals && i < healManager.spawnPoints.length; i++) {
      healManager.spawnHeal();
    }
  }

}