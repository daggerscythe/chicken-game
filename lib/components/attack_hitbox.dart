import 'dart:async';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

class AttackHitbox extends PositionComponent with CollisionCallbacks {
  final PositionComponent owner;
  final void Function(PositionComponent target) onHit;

  AttackHitbox({
    required this.owner,
    required this.onHit,
    super.position, 
    super.size,
  });

  @override
  FutureOr<void> onLoad() {
    // debugMode = true;
    add(RectangleHitbox());
    return super.onLoad();
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other == owner) return; // can't hit itself
    onHit(other);
    super.onCollision(intersectionPoints, other);
  }
}