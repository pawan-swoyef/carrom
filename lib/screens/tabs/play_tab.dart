import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class PlayTab extends StatelessWidget {
  const PlayTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Select Mode\n(coming in Phase 2)',
        textAlign: TextAlign.center,
        style: TextStyle(color: AppColors.textMuted, fontSize: 18),
      ),
    );
  }
}
