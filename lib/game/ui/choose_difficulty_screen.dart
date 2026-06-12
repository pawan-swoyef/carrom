import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../settings/difficulty.dart';
import '../../settings/settings_controller.dart';
import '../game_launch_args.dart';
import '../../navigation/app_routes.dart';

class ChooseDifficultyScreen extends StatefulWidget {
  const ChooseDifficultyScreen({super.key});

  @override
  State<ChooseDifficultyScreen> createState() => _ChooseDifficultyScreenState();
}

class _ChooseDifficultyScreenState extends State<ChooseDifficultyScreen> {
  late Difficulty _selected;

  @override
  void initState() {
    super.initState();
    _selected = context.read<SettingsController>().settings.defaultDifficulty;
  }

  void _start() {
    AppRoutes.pushGame(
      context,
      GameLaunchArgs(mode: GameMode.vsComputer, difficulty: _selected),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.woodDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.pinkHeading),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('Choose Difficulty',
            style: TextStyle(
                color: AppColors.pinkHeading, fontWeight: FontWeight.w800)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _DifficultyCard(
                icon: Icons.sentiment_satisfied_alt,
                accent: AppColors.felt,
                title: 'Easy',
                desc: 'Relaxed play for beginners.',
                selected: _selected == Difficulty.easy,
                onTap: () => setState(() => _selected = Difficulty.easy),
              ),
              const SizedBox(height: 14),
              _DifficultyCard(
                icon: Icons.balance,
                accent: AppColors.gold,
                title: 'Medium',
                desc: 'A balanced challenge.',
                selected: _selected == Difficulty.medium,
                onTap: () => setState(() => _selected = Difficulty.medium),
              ),
              const SizedBox(height: 14),
              _DifficultyCard(
                icon: Icons.military_tech,
                accent: AppColors.crimson,
                title: 'Hard',
                desc: 'The Pro Circuit. Rarely misses.',
                selected: _selected == Difficulty.hard,
                onTap: () => setState(() => _selected = Difficulty.hard),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.crimson,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28)),
                  ),
                  onPressed: _start,
                  child: const Text('Start Game  ▷',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.pinkHeading)),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _DifficultyCard extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final String title;
  final String desc;
  final bool selected;
  final VoidCallback onTap;

  const _DifficultyCard({
    required this.icon,
    required this.accent,
    required this.title,
    required this.desc,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppColors.gold : AppColors.crimsonDark,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                  border: Border.all(color: accent),
                ),
                child: Icon(icon, color: accent),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            color: AppColors.pinkHeading,
                            fontSize: 20,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(desc,
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 13)),
                  ],
                ),
              ),
              if (selected)
                const Icon(Icons.check_circle, color: AppColors.gold),
            ],
          ),
        ),
      ),
    );
  }
}
