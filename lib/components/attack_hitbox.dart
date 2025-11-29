import 'dart:async';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:platformer/components/chicken.dart';
import 'package:platformer/components/player.dart';

class AttackHitbox extends PositionComponent with CollisionCallbacks {
  AttackHitbox({super.position, super.size});

  @override
  FutureOr<void> onLoad() {
    debugMode = true;
    add(RectangleHitbox());
    return super.onLoad();
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is Chicken && (parent as Player).current == PlayerState.slashing) {
      other.takeDamage();
    }
    super.onCollisionStart(intersectionPoints, other);
  }
}