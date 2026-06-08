import '../rules/coin_type.dart';
import '../rules/strike_outcome.dart';

/// Mutable accumulator for the physical result of a single strike. The physics
/// layer appends to this as pockets capture pieces; [toOutcome] freezes it.
class StrikeResult {
  final List<CoinType> pocketed = [];
  bool strikerPocketed = false;

  void reset() {
    pocketed.clear();
    strikerPocketed = false;
  }

  StrikeOutcome toOutcome() => StrikeOutcome(
        pocketed: List.unmodifiable(pocketed),
        strikerPocketed: strikerPocketed,
      );
}
