import 'package:flame_audio/flame_audio.dart';
import '../settings/settings_controller.dart';

/// Plays short SFX, gated by the Sound Effects setting. Crash-safe: if the clips
/// are missing it silently no-ops (the game ships without bundled audio).
class AudioService {
  final SettingsController settings;
  bool _ready = false;

  AudioService(this.settings);

  static const _clips = ['strike.mp3', 'pocket.mp3', 'win.mp3', 'lose.mp3'];

  Future<void> init() async {
    try {
      await FlameAudio.audioCache.loadAll(_clips);
      _ready = true;
    } catch (_) {
      _ready = false;
    }
  }

  void _play(String clip) {
    if (!_ready || !settings.settings.soundEffects) return;
    try {
      FlameAudio.play(clip);
    } catch (_) {}
  }

  void strike() => _play('strike.mp3');
  void pocket() => _play('pocket.mp3');
  void win() => _play('win.mp3');
  void lose() => _play('lose.mp3');
}
