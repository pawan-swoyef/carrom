import 'package:flutter/material.dart';
import '../game_launch_args.dart';
import '../../theme/app_colors.dart';

class GameScreen extends StatelessWidget {
  final GameLaunchArgs args;
  const GameScreen({super.key, required this.args});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Carrom — ${args.mode.name}')),
      body: const Center(
        child: Text('Board loads here (Task 7+)',
            style: TextStyle(color: AppColors.textMuted)),
      ),
    );
  }
}
