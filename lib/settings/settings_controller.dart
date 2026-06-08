import 'package:flutter/foundation.dart';
import '../services/storage_service.dart';
import 'difficulty.dart';
import 'settings.dart';

class SettingsController extends ChangeNotifier {
  static const _kSound = 'settings.soundEffects';
  static const _kMusic = 'settings.music';
  static const _kVibration = 'settings.vibration';
  static const _kDifficulty = 'settings.defaultDifficulty';

  final StorageService _storage;
  Settings _settings = const Settings();

  SettingsController(this._storage) {
    _load();
  }

  Settings get settings => _settings;

  void _load() {
    _settings = Settings(
      soundEffects: _storage.getBool(_kSound, defaultValue: true),
      music: _storage.getBool(_kMusic, defaultValue: true),
      vibration: _storage.getBool(_kVibration, defaultValue: true),
      defaultDifficulty: Difficulty.values[_storage.getInt(
        _kDifficulty,
        defaultValue: Difficulty.medium.index,
      )],
    );
    notifyListeners();
  }

  Future<void> setSoundEffects(bool value) async {
    _settings = _settings.copyWith(soundEffects: value);
    await _storage.setBool(_kSound, value);
    notifyListeners();
  }

  Future<void> setMusic(bool value) async {
    _settings = _settings.copyWith(music: value);
    await _storage.setBool(_kMusic, value);
    notifyListeners();
  }

  Future<void> setVibration(bool value) async {
    _settings = _settings.copyWith(vibration: value);
    await _storage.setBool(_kVibration, value);
    notifyListeners();
  }

  Future<void> setDefaultDifficulty(Difficulty value) async {
    _settings = _settings.copyWith(defaultDifficulty: value);
    await _storage.setInt(_kDifficulty, value.index);
    notifyListeners();
  }
}
