import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

/// One side of the top HUD: name, coin colour, remaining count, active glow.
class PlayerPanel extends StatelessWidget {
  final String name;
  final bool isWhite;
  final int coinsRemaining;
  final bool active;
  final bool isComputer;

  const PlayerPanel({
    super.key,
    required this.name,
    required this.isWhite,
    required this.coinsRemaining,
    required this.active,
    this.isComputer = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surface,
                border: Border.all(
                  color: active ? AppColors.gold : AppColors.crimsonDark,
                  width: active ? 3 : 1.5,
                ),
              ),
              child: Icon(
                isComputer ? Icons.smart_toy : Icons.person,
                color: AppColors.textLight,
              ),
            ),
            Positioned(
              bottom: -4,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isWhite ? const Color(0xFFF5ECD7) : const Color(0xFF1A1210),
                  border: Border.all(color: AppColors.woodDark, width: 2),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(name,
            style: const TextStyle(
                color: AppColors.textLight,
                fontWeight: FontWeight.w700,
                fontSize: 13)),
        Text('${isWhite ? 'WHITE' : 'BLACK'} • $coinsRemaining',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
      ],
    );
  }
}
