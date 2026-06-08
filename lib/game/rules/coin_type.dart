enum CoinType { white, black, queen }

/// Returns the opposing player color. Only valid for white/black.
CoinType otherColor(CoinType color) {
  assert(color == CoinType.white || color == CoinType.black,
      'otherColor expects a player color, not the queen');
  return color == CoinType.white ? CoinType.black : CoinType.white;
}
