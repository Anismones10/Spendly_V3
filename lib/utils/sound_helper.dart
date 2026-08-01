import 'package:audioplayers/audioplayers.dart';
import 'package:hive/hive.dart';

class SoundHelper {
  static final AudioPlayer _player = AudioPlayer();

  static bool get _enabled => Hive.box('settings').get('soundEnabled', defaultValue: true);

  static Future<void> playChaChing() async {
    if (!_enabled) return;
    try {
      await _player.play(AssetSource('sounds/chaching.mp3'));
    } catch (_) {}
  }

  static Future<void> playCelebration() async {
    if (!_enabled) return;
    try {
      await _player.play(AssetSource('sounds/celebration.mp3'));
    } catch (_) {}
  }

  static Future<void> playIncome() async {
    if (!_enabled) return;
    try {
      await _player.play(AssetSource('sounds/income.mp3'));
    } catch (_) {}
  }

  static Future<void> playWarning() async {
    if (!_enabled) return;
    try {
      await _player.play(AssetSource('sounds/warning.mp3'));
    } catch (_) {}
  }
}
