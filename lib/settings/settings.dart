import 'difficulty.dart';

class Settings {
  final bool soundEffects;
  final bool music;
  final bool vibration;
  final Difficulty defaultDifficulty;

  const Settings({
    this.soundEffects = true,
    this.music = true,
    this.vibration = true,
    this.defaultDifficulty = Difficulty.medium,
  });

  Settings copyWith({
    bool? soundEffects,
    bool? music,
    bool? vibration,
    Difficulty? defaultDifficulty,
  }) {
    return Settings(
      soundEffects: soundEffects ?? this.soundEffects,
      music: music ?? this.music,
      vibration: vibration ?? this.vibration,
      defaultDifficulty: defaultDifficulty ?? this.defaultDifficulty,
    );
  }
}
