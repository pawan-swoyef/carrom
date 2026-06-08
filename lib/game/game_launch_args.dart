import '../settings/difficulty.dart';

enum GameMode { vsComputer, twoPlayer, practice }

class GameLaunchArgs {
  final GameMode mode;
  final Difficulty? difficulty; // only for vsComputer

  const GameLaunchArgs({required this.mode, this.difficulty});
}
