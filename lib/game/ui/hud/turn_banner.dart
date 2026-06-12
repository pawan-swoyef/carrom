import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

/// A transient centered banner (e.g. "Player 2's Turn"). The parent controls
/// visibility; this just renders the styled banner.
class TurnBanner extends StatelessWidget {
  final String text;
  const TurnBanner({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.gold),
        ),
        child: Text(text,
            style: const TextStyle(
                color: AppColors.gold,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: 1)),
      ),
    );
  }
}
