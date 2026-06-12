import 'package:flutter/foundation.dart';
import '../../services/storage_service.dart';
import 'player_profile.dart';
import 'rank.dart';

/// Persisted player progression: coins, XP, stats. Notifies listeners on change.
class ProfileController extends ChangeNotifier {
  static const _key = 'profile';

  static const int winBonusCoins = 100;
  static const int coinsPerPocket = 10;
  static const int winXp = 50;
  static const int lossXp = 15;
  static const int xpPerPocket = 5;
  static const int _historyCap = 12;

  final StorageService _storage;
  PlayerProfile _profile;

  ProfileController(this._storage) : _profile = _read(_storage);

  static PlayerProfile _read(StorageService s) {
    final json = s.getJson(_key);
    return json == null ? const PlayerProfile() : PlayerProfile.fromJson(json);
  }

  PlayerProfile get profile => _profile;
  RankInfo get rank => rankForXp(_profile.xp);

  Future<void> recordMatch({
    required bool won,
    required int coinsPocketed,
  }) async {
    final coinsEarned =
        (won ? winBonusCoins : 0) + coinsPocketed * coinsPerPocket;
    final xpEarned = (won ? winXp : lossXp) + coinsPocketed * xpPerPocket;
    final streak = won ? _profile.currentStreak + 1 : 0;
    final history = [..._profile.history, coinsEarned];
    final trimmed = history.length > _historyCap
        ? history.sublist(history.length - _historyCap)
        : history;

    _profile = _profile.copyWith(
      coins: _profile.coins + coinsEarned,
      xp: _profile.xp + xpEarned,
      wins: _profile.wins + (won ? 1 : 0),
      losses: _profile.losses + (won ? 0 : 1),
      currentStreak: streak,
      bestStreak: streak > _profile.bestStreak ? streak : _profile.bestStreak,
      history: trimmed,
    );
    await _save();
    notifyListeners();
  }

  Future<void> addCoins(int amount) async {
    _profile = _profile.copyWith(coins: _profile.coins + amount);
    await _save();
    notifyListeners();
  }

  Future<bool> spend(int amount) async {
    if (_profile.coins < amount) return false;
    _profile = _profile.copyWith(coins: _profile.coins - amount);
    await _save();
    notifyListeners();
    return true;
  }

  Future<void> reset() async {
    _profile = const PlayerProfile();
    await _save();
    notifyListeners();
  }

  Future<void> _save() => _storage.setJson(_key, _profile.toJson());
}
