import 'package:flame/components.dart';

class CollisionBlock extends PositionComponent {
  bool isPlatform;
  bool isBlock;
  CollisionBlock({
    position, 
    size,
    this.isPlatform = false,
    this.isBlock = false,
  }) : super(position: position, size: size) {
    // debugMode = true; // to actually see the collisions
  }
}