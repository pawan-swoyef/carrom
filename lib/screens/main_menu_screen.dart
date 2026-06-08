import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../settings/settings_controller.dart';
import '../navigation/home_shell.dart';

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  void _openPlay(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const HomeShell(initialIndex: 0)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  iconSize: 30,
                  color: AppColors.gold,
                  icon: Icon(settings.settings.soundEffects
                      ? Icons.volume_up
                      : Icons.volume_off),
                  onPressed: () => settings
                      .setSoundEffects(!settings.settings.soundEffects),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Carrom Pro',
                style: TextStyle(
                  fontSize: 44,
                  fontWeight: FontWeight.bold,
                  color: AppColors.gold,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'THE PROFESSIONAL CIRCUIT',
                style: TextStyle(
                  color: AppColors.textMuted,
                  letterSpacing: 3,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => _openPlay(context),
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    color: AppColors.crimson,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.gold, width: 4),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.play_arrow,
                          size: 64, color: AppColors.pinkHeading),
                      Text(
                        'PLAY',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.pinkHeading,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  _MenuChip(icon: Icons.menu_book, label: 'How to Play'),
                  _MenuChip(icon: Icons.bar_chart, label: 'Stats'),
                  _MenuChip(icon: Icons.settings, label: 'Settings'),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MenuChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 84,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.crimsonDark),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.gold),
          const SizedBox(height: 8),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppColors.textLight, fontSize: 12)),
        ],
      ),
    );
  }
}
