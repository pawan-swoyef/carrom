class RankTier {
  final String name;
  final int minXp;
  const RankTier(this.name, this.minXp);
}

const List<RankTier> kRankTiers = [
  RankTier('Rookie', 0),
  RankTier('Amateur', 200),
  RankTier('Pro', 600),
  RankTier('Veteran', 1200),
  RankTier('Master', 2000),
  RankTier('Pro Master', 3000),
  RankTier('Legend', 5000),
];

class RankInfo {
  final String name;
  final int tierIndex;
  final int xpIntoTier;
  final int xpForTier;
  const RankInfo({
    required this.name,
    required this.tierIndex,
    required this.xpIntoTier,
    required this.xpForTier,
  });

  double get progress => xpForTier == 0 ? 1.0 : xpIntoTier / xpForTier;
  int get xpToNext => xpForTier == 0 ? 0 : xpForTier - xpIntoTier;
}

RankInfo rankForXp(int xp) {
  var index = 0;
  for (var i = 0; i < kRankTiers.length; i++) {
    if (xp >= kRankTiers[i].minXp) index = i;
  }
  final tier = kRankTiers[index];
  final isMax = index == kRankTiers.length - 1;
  final span = isMax ? 0 : kRankTiers[index + 1].minXp - tier.minXp;
  return RankInfo(
    name: tier.name,
    tierIndex: index,
    xpIntoTier: xp - tier.minXp,
    xpForTier: span,
  );
}
