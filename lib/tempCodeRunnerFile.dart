void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Flame.device.fullScreen();
  await Flame.device.setLandscape();

  PixelGame game = PixelGame();
  // runApp(GameWidget(game: game)); // uncomment when done
  runApp(GameWidget(game: kDebugMode ? PixelGame() : game)); // for debugging
}