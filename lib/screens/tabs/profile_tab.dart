import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Profile\n(coming in Phase 3)',
        textAlign: TextAlign.center,
        style: TextStyle(color: AppColors.textMuted, fontSize: 18),
      ),
    );
  }
}
