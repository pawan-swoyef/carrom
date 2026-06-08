import 'coin_type.dart';

/// The physical result of one strike, produced by the physics layer (or a
/// test): which coins fell into pockets, and whether the striker itself fell.
class StrikeOutcome {
  final List<CoinType> pocketed;
  final bool strikerPocketed;

  const StrikeOutcome({
    this.pocketed = const [],
    this.strikerPocketed = false,
  });
}
