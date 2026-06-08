import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class StrikersTab extends StatelessWidget {
  const StrikersTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Strikers\n(coming in Phase 4)',
        textAlign: TextAlign.center,
        style: TextStyle(color: AppColors.textMuted, fontSize: 18),
      ),
    );
  }
}
