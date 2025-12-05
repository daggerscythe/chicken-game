import 'dart:math';

import 'package:flame/components.dart';
import 'package:platformer/components/heal.dart';
import 'package:platformer/pixel_game.dart';

class HealManager extends Component with HasGameReference<PixelGame> {
  final List<Vector2> spawnPoints = [];
  final List<Heal> activeHeals = [];
  
  static const maxHeals = 2; // active at one time
  static const respawnDelay = 3.0; // seconds

  double _timer = 0;

  void addSpawnPoint(Vector2 position) {
    spawnPoints.add(position);
  }

  @override
  void update(double dt) {
    _timer += dt;

    activeHeals.removeWhere((heal) => !heal.isMounted); // remove collected heals

    // spawn new heal
    if (_timer >= respawnDelay && activeHeals.length < maxHeals && spawnPoints.isNotEmpty) {
      spawnHeal();
      _timer = 0;
    }
    
    super.update(dt);
  }
  
  void spawnHeal() {
    if (spawnPoints.isEmpty) return;

    // heals cant be in the same place at once
    final availablePoints = List<Vector2>.from(spawnPoints);

    // remove points that already have active heals
    for (final heal in activeHeals) {
      availablePoints.removeWhere((point) => (point - heal.position).length < 5); // 5 px tolerance
    }

    if (availablePoints.isEmpty) return;

    final randomSpawnIndex = Random().nextInt(availablePoints.length);
    final spawnPosition = availablePoints[randomSpawnIndex];

    final heal = Heal(
      position: spawnPosition,
      size: Vector2.all(20),
    );
    parent!.add(heal);
    activeHeals.add(heal);
  }

}