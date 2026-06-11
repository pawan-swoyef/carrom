import 'package:flame/game.dart';
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
          Positioned.fill(
            child: GameWidget(game: _game),
          ),

          // ── Top bar ──────────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  // Back button
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    color: AppColors.textLight,
                    tooltip: 'Back',
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Carrom — ${widget.args.mode.name}',
                    style: const TextStyle(
                      color: AppColors.gold,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const Spacer(),
                  // Reset button
                  TextButton.icon(
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Reset'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textMuted,
                    ),
                    onPressed: () {
                      _game.resetBoard();
                      setState(() {});
                    },
                  ),
                ],
              ),
            ),
          ),

          // ── Drag hint (bottom-centre, non-interactive) ────────────────
          const Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Text(
                'Drag the striker to aim',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
