import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../game/game_launch_args.dart';
import '../../navigation/app_routes.dart';
import '../../game/ui/choose_difficulty_screen.dart';

class PlayTab extends StatelessWidget {
  const PlayTab({super.key});

  void _launch(BuildContext context, GameMode mode) {
    AppRoutes.pushGame(context, GameLaunchArgs(mode: mode));
  }

  void _chooseDifficulty(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ChooseDifficultyScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text('Select Mode',
                style: TextStyle(
                    color: AppColors.pinkHeading,
                    fontSize: 24,
                    fontWeight: FontWeight.w800)),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              children: [
                _ModeCard(
                  icon: Icons.smart_toy,
                  title: 'vs Computer',
                  desc: 'Challenge our advanced AI and sharpen your skills.',
                  onTap: () => _chooseDifficulty(context),
                ),
                const SizedBox(height: 16),
                _ModeCard(
                  icon: Icons.people_alt,
                  title: '2 Players',
                  desc: 'Classic local multiplayer. Pass and play with a friend.',
                  onTap: () => _launch(context, GameMode.twoPlayer),
                ),
                const SizedBox(height: 16),
                _ModeCard(
                  icon: Icons.adjust,
                  title: 'Practice',
                  desc: 'Unlimited shots to master your striker control.',
                  onTap: () => _launch(context, GameMode.practice),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;
  final VoidCallback onTap;

  const _ModeCard({
    required this.icon,
    required this.title,
    required this.desc,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.felt.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.crimson, width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.crimson,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(icon, color: AppColors.pinkHeading, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            color: AppColors.gold,
                            fontSize: 20,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    Text(desc,
                        style: const TextStyle(
                            color: AppColors.textLight, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
