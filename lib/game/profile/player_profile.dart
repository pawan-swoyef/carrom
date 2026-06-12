/// Immutable local player profile. Persisted as JSON via ProfileController.
class PlayerProfile {
  final int coins;
  final int xp;
  final int wins;
  final int losses;
  final int bestStreak;
  final int currentStreak;
  final List<int> history;

  const PlayerProfile({
    this.coins = 0,
    this.xp = 0,
    this.wins = 0,
    this.losses = 0,
    this.bestStreak = 0,
    this.currentStreak = 0,
    this.history = const [],
  });

  int get gamesPlayed => wins + losses;
  int get level => xp ~/ 100 + 1;
  double get efficiency => gamesPlayed == 0 ? 0 : wins / gamesPlayed;

  PlayerProfile copyWith({
    int? coins,
    int? xp,
    int? wins,
    int? losses,
    int? bestStreak,
    int? currentStreak,
    List<int>? history,
  }) {
    return PlayerProfile(
      coins: coins ?? this.coins,
      xp: xp ?? this.xp,
      wins: wins ?? this.wins,
      losses: losses ?? this.losses,
      bestStreak: bestStreak ?? this.bestStreak,
      currentStreak: currentStreak ?? this.currentStreak,
      history: history ?? this.history,
    );
  }

  Map<String, dynamic> toJson() => {
        'coins': coins,
        'xp': xp,
        'wins': wins,
        'losses': losses,
        'bestStreak': bestStreak,
        'currentStreak': currentStreak,
        'history': history,
      };

  factory PlayerProfile.fromJson(Map<String, dynamic> json) {
    return PlayerProfile(
      coins: (json['coins'] as num?)?.toInt() ?? 0,
      xp: (json['xp'] as num?)?.toInt() ?? 0,
      wins: (json['wins'] as num?)?.toInt() ?? 0,
      losses: (json['losses'] as num?)?.toInt() ?? 0,
      bestStreak: (json['bestStreak'] as num?)?.toInt() ?? 0,
      currentStreak: (json['currentStreak'] as num?)?.toInt() ?? 0,
      history: ((json['history'] as List?) ?? const [])
          .map((e) => (e as num).toInt())
          .toList(),
    );
  }
}
