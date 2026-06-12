import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../settings/difficulty.dart';
import '../profile/profile_controller.dart';
import '../../theme/app_colors.dart';
import '../ai/ai_player.dart';
import '../engine/carrom_game.dart';
import '../game_launch_args.dart';
import '../match/ai_turn.dart';
import '../match/match_session.dart';
import '../rules/coin_type.dart';
import '../rules/player.dart';
import '../rules/strike_outcome.dart';
import 'hud/player_panel.dart';
import 'hud/queen_status_pill.dart';
import 'hud/turn_banner.dart';
import 'result_dialog.dart';

class GameScreen extends StatefulWidget {
  final GameLaunchArgs args;
  const GameScreen({super.key, required this.args});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final CarromGame _game;

  /// The computer opponent (used only in vsComputer mode).
  late final AiPlayer _ai;

  /// Live match state for vsComputer / twoPlayer. Null in practice mode.
  MatchSession? _session;

  /// Transient turn-banner text; null when no banner is showing.
  String? _banner;

  /// Guards against awarding coins/XP more than once per match.
  bool _awarded = false;

  @override
  void initState() {
    super.initState();
    _game = CarromGame();
    _ai = AiPlayer(widget.args.difficulty ?? Difficulty.medium);
    if (widget.args.mode != GameMode.practice) {
      _session = MatchSession(mode: widget.args.mode);
      _game.onStrikeComplete = _handleStrikeComplete;
    }
    if (_session != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _maybeRunAi());
    }
  }

  /// Evaluates whose turn it is. On the AI's turn, locks human input and, after
  /// a short "thinking" delay, fires the computer's planned shot. On a human
  /// turn (or when no session exists), simply unlocks input.
  void _maybeRunAi() {
    final session = _session;
    if (session == null || session.isOver) return;
    if (!session.turnIsAI) {
      _game.interactive = true; // human's turn — allow input
      return;
    }
    _game.interactive = false; // lock the human out during the AI turn
    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      final s = _session;
      if (s == null || s.isOver || !s.turnIsAI) {
        _game.interactive = true;
        return;
      }
      // Flip interactive true only to allow the programmatic AI shot through
      // the engine's guards, then re-lock until the strike resolves.
      _game.interactive = true;
      final fired = runAiTurn(_game, _ai, s.colorOf(s.currentPlayer));
      _game.interactive = false;
      if (!fired) {
        // No shot found → resolve as an empty strike (pass turn).
        _game.interactive = true;
        _handleStrikeComplete(const StrikeOutcome());
      }
    });
  }

  @override
  void dispose() {
    _game.pauseEngine();
    super.dispose();
  }

  /// Advances the match by one resolved strike and refreshes the HUD.
  void _handleStrikeComplete(StrikeOutcome outcome) {
    final session = _session;
    if (session == null) return;
    final before = session.currentPlayer;
    session.applyStrike(outcome);
    if (session.isOver) {
      _awardIfNeeded(session);
      setState(() {}); // surfaces the result dialog
      return;
    }
    // Re-centre the striker on the baseline for the next strike.
    _game.setStrikerX(0);
    if (session.currentPlayer != before) {
      _showTurnBanner(session.currentPlayer);
    }
    setState(() {});
    // Hand control on: run the AI for its turn, or unlock the human for theirs.
    // Covers both continue-turn and pass-turn cases.
    if (session.turnIsAI) {
      _maybeRunAi();
    } else {
      _game.interactive = true;
    }
  }

  /// Awards coins/XP for a finished vs-Computer match exactly once.
  void _awardIfNeeded(MatchSession session) {
    if (_awarded) return;
    if (widget.args.mode != GameMode.vsComputer) return;
    _awarded = true;
    final won = session.winner == Player.one;
    final pocketed = (9 - session.coinsRemainingFor(Player.one)).clamp(0, 9);
    context.read<ProfileController>().recordMatch(won: won, coinsPocketed: pocketed);
  }

  void _showTurnBanner(Player p) {
    final isComputer =
        widget.args.mode == GameMode.vsComputer && p == Player.two;
    _banner = isComputer
        ? "Computer's Turn"
        : "Player ${p == Player.one ? 1 : 2}'s Turn";
    setState(() {});
    Future.delayed(const Duration(milliseconds: 1100), () {
      if (mounted) setState(() => _banner = null);
    });
  }

  void _restartMatch() async {
    await _game.resetBoard();
    if (!mounted) return;
    setState(() {
      _session = MatchSession(mode: widget.args.mode);
      _game.onStrikeComplete = _handleStrikeComplete;
      _banner = null;
      _awarded = false;
      _game.interactive = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeRunAi());
  }

  @override
  Widget build(BuildContext context) {
    final session = _session;
    return Scaffold(
      backgroundColor: AppColors.woodDark,
      body: Stack(
        children: [
          // ── Game canvas (fills screen; drag input lives inside Flame) ──
          Positioned.fill(child: GameWidget(game: _game)),

          // ── Top bar: coin balance / match HUD + reset/pause ──────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Column(
                children: [
                  Row(
                    children: [
                      if (session == null)
                        _CoinPill(
                            coins: context.watch<ProfileController>().profile.coins),
                      const Spacer(),
                      _RoundIconButton(
                        icon: Icons.refresh_rounded,
                        tooltip: 'Reset',
                        onPressed: () => _game.resetBoard(),
                      ),
                      const SizedBox(width: 10),
                      _RoundIconButton(
                        icon: Icons.pause_rounded,
                        tooltip: 'Pause',
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                    ],
                  ),
                  if (session != null) ...[
                    const SizedBox(height: 8),
                    _MatchHud(mode: widget.args.mode, session: session),
                  ],
                ],
              ),
            ),
          ),

          // ── STRIKE POWER meter (right edge, vertically centred) ───────
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 10),
              child: _StrikePowerMeter(power: _game.strikePower),
            ),
          ),

          // ── Controls legend (bottom) ──────────────────────────────────
          const Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.only(bottom: 18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _LegendItem(icon: Icons.back_hand_outlined, label: 'PULL BACK'),
                  SizedBox(width: 36),
                  _LegendItem(
                      icon: Icons.ads_click_rounded, label: 'RELEASE'),
                  SizedBox(width: 36),
                  _LegendItem(
                      icon: Icons.touch_app_outlined, label: 'AIM DRAG'),
                ],
              ),
            ),
          ),

          // ── Transient turn banner ─────────────────────────────────────
          if (_banner != null) TurnBanner(text: _banner!),

          // ── Result dialog (match over) ────────────────────────────────
          if (session != null && session.isOver) ...[
            Positioned.fill(
              child: Container(color: Colors.black.withValues(alpha: 0.65)),
            ),
            ResultDialog(
              won: _resultWon(session),
              title: _resultTitle(session),
              onPlayAgain: _restartMatch,
              onMainMenu: () => Navigator.of(context).maybePop(),
            ),
          ],
        ],
      ),
    );
  }

  bool _resultWon(MatchSession session) {
    // twoPlayer: there is always a winner, so the result is a win to show.
    // vsComputer: the human (Player.one) must be the winner.
    if (widget.args.mode == GameMode.vsComputer) {
      return session.winner == Player.one;
    }
    return true;
  }

  String _resultTitle(MatchSession session) {
    if (widget.args.mode == GameMode.vsComputer) {
      return session.winner == Player.one ? 'VICTORY!' : 'DEFEAT';
    }
    return 'PLAYER ${session.winner == Player.one ? 1 : 2} WINS';
  }
}

/// Top-of-screen match HUD: two player panels flanking the queen-status pill.
class _MatchHud extends StatelessWidget {
  final GameMode mode;
  final MatchSession session;
  const _MatchHud({required this.mode, required this.session});

  @override
  Widget build(BuildContext context) {
    final rightIsComputer = mode == GameMode.vsComputer;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PlayerPanel(
          name: 'Player 1',
          isWhite: session.colorOf(Player.one) == CoinType.white,
          coinsRemaining: session.coinsRemainingFor(Player.one),
          active: session.currentPlayer == Player.one,
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: QueenStatusPill(status: session.queenStatus),
              ),
            ),
          ),
        ),
        PlayerPanel(
          name: rightIsComputer ? 'Computer' : 'Player 2',
          isComputer: rightIsComputer,
          isWhite: session.colorOf(Player.two) == CoinType.white,
          coinsRemaining: session.coinsRemainingFor(Player.two),
          active: session.currentPlayer == Player.two,
        ),
      ],
    );
  }
}

class _CoinPill extends StatelessWidget {
  final int coins;
  const _CoinPill({required this.coins});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.crimsonDark),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, color: AppColors.gold, size: 18),
          const SizedBox(width: 6),
          Text('$coins',
              style: const TextStyle(
                  color: AppColors.gold,
                  fontWeight: FontWeight.w800,
                  fontSize: 15)),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  const _RoundIconButton(
      {required this.icon, required this.tooltip, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkResponse(
        onTap: onPressed,
        radius: 26,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.55),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.crimsonDark),
          ),
          child: Icon(icon, color: AppColors.gold, size: 20),
        ),
      ),
    );
  }
}

/// Vertical strike-power meter that fills from the bottom (crimson → pink) as
/// the player pulls back. Reads the live power 0..1 from the game.
class _StrikePowerMeter extends StatelessWidget {
  final ValueListenable<double> power;
  const _StrikePowerMeter({required this.power});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        RotatedBox(
          quarterTurns: 3,
          child: Text(
            'STRIKE POWER',
            style: TextStyle(
              color: AppColors.textMuted.withValues(alpha: 0.7),
              fontSize: 11,
              letterSpacing: 2,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Container(
          width: 22,
          height: 220,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.crimsonDark),
          ),
          child: ValueListenableBuilder<double>(
            valueListenable: power,
            builder: (_, p, _) => Align(
              alignment: Alignment.bottomCenter,
              child: FractionallySizedBox(
                heightFactor: p.clamp(0.0, 1.0),
                widthFactor: 1,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(9),
                    gradient: const LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [AppColors.crimsonDark, AppColors.crimson, AppColors.pinkHeading],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final IconData icon;
  final String label;
  const _LegendItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.textMuted, size: 22),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(
                color: AppColors.textMuted, fontSize: 11, letterSpacing: 1)),
      ],
    );
  }
}
