import 'package:flame/flame.dart';
// import 'package:flutter/foundation.dart'; // for debugging
import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:platformer/pixel_game.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Flame.device.fullScreen();
  await Flame.device.setLandscape();

  PixelGame game = PixelGame();
  runApp(GameWidget(game: game)); // uncomment when done
  // runApp(GameWidget(game: kDebugMode ? PixelGame() : game)); // for debugging
}
