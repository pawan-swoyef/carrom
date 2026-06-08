import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class ShopTab extends StatelessWidget {
  const ShopTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Shop\n(coming in Phase 4)',
        textAlign: TextAlign.center,
        style: TextStyle(color: AppColors.textMuted, fontSize: 18),
      ),
    );
  }
}
