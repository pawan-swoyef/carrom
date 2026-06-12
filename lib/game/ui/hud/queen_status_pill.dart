import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../match/match_session.dart';

/// Centre HUD pill showing the queen's state.
class QueenStatusPill extends StatelessWidget {
  final QueenStatus status;
  const QueenStatusPill({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final label = switch (status) {
      QueenStatus.onBoard => 'ON BOARD',
      QueenStatus.pendingCover => 'COVER IT!',
      QueenStatus.covered => 'COVERED',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.crimsonDark.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.crimson),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.circle, color: AppColors.crimson, size: 12),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(
                  color: AppColors.pinkHeading,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  letterSpacing: 1)),
        ],
      ),
    );
  }
}
