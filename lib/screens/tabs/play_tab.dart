import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../game/game_launch_args.dart';
import '../../navigation/app_routes.dart';

class PlayTab extends StatelessWidget {
  const PlayTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Select Mode\n(full screen in Phase 2C)',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted, fontSize: 16),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => AppRoutes.pushGame(
              context,
              const GameLaunchArgs(mode: GameMode.practice),
            ),
            child: const Text('Practice'),
          ),
        ],
      ),
    );
  }
}
