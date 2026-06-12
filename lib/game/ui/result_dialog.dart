import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Victory / defeat overlay shown when a match ends.
class ResultDialog extends StatelessWidget {
  final bool won;
  final String title;
  final VoidCallback onPlayAgain;
  final VoidCallback onMainMenu;

  const ResultDialog({
    super.key,
    required this.won,
    required this.title,
    required this.onPlayAgain,
    required this.onMainMenu,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 32),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: AppColors.woodGrain,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.gold, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(won ? Icons.emoji_events : Icons.flag,
                color: AppColors.gold, size: 56),
            const SizedBox(height: 12),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.gold,
                    fontSize: 28,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(backgroundColor: AppColors.crimson),
                onPressed: onPlayAgain,
                child: const Text('PLAY AGAIN'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onMainMenu,
                child: const Text('MAIN MENU'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
