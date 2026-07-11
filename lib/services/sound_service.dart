import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SoundService {
  static bool _enabled = true;
  static bool _initialized = false;
  static late AudioPlayer _player;

  static Future<void> init() async {
    if (_initialized) return;
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool('sound_effects') ?? true;
    _player = AudioPlayer();
    _initialized = true;
  }

  static bool get enabled => _enabled;

  static Future<void> setEnabled(bool value) async {
    _enabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sound_effects', value);
  }

  static Future<void> playDeposit() async {
    await init();
    if (!_enabled) return;
    await _player.play(AssetSource('sounds/deposit.wav'));
  }

  static Future<void> playGoalComplete() async {
    await init();
    if (!_enabled) return;
    await _player.play(AssetSource('sounds/goal_complete.wav'));
  }
}
