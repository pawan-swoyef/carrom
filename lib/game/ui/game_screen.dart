import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../engine/carrom_game.dart';
import '../game_launch_args.dart';

class GameScreen extends StatefulWidget {
  final GameLaunchArgs args;
  const GameScreen({super.key, required this.args});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final CarromGame _game;

  @override
  void initState() {
    super.initState();
    _game = CarromGame();
  }

  @override
  void dispose() {
    _game.pauseEngine();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.woodDark,
      body: Stack(
        children: [
          // ── Game canvas (fills screen; drag input lives inside Flame) ──
          Positioned.fill(child: GameWidget(game: _game)),

          // ── Top bar: coin balance + reset/pause ──────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  // TODO(Phase 3): bind to real coin balance.
                  const _CoinPill(coins: 0),
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
        ],
      ),
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
