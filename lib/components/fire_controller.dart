import 'package:platformer/components/corner_fire.dart';

class FireController {
  static final FireController _instance = FireController._internal();
  factory FireController() => _instance;
  FireController._internal();

  CornerFire? _activeShooter;
  bool _isShooting = false;
  List<CornerFire> _waitingFires = [];

  bool canShoot(CornerFire fire) {
    if (!_isShooting) {
      _activeShooter = fire;
      _isShooting = true;
      return true;
    }

    if (!_waitingFires.contains(fire)) {
      _waitingFires.add(fire);
    }
    return false;
  }

  void finishShooting(CornerFire fire) {
    if (_activeShooter == fire) {
      _isShooting = false;
      _activeShooter = null;

      if (_waitingFires.isNotEmpty) {
        final nextFire = _waitingFires.removeAt(0);
        _activeShooter = nextFire;
        _isShooting = true;
        nextFire.forceShoot();
      }
    }
  }

  void reset() {
    _isShooting = false;
    _activeShooter = null;
  }
}