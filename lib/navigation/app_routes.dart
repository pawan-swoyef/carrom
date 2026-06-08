import 'package:flutter/material.dart';
import '../game/game_launch_args.dart';
import '../game/ui/game_screen.dart';

abstract class AppRoutes {
  static const game = '/game';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case game:
        final args = settings.arguments as GameLaunchArgs;
        return MaterialPageRoute(
          builder: (_) => GameScreen(args: args),
          settings: settings,
        );
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('Unknown route: ${settings.name}')),
          ),
        );
    }
  }

  static Future<void> pushGame(BuildContext context, GameLaunchArgs args) {
    return Navigator.of(context).pushNamed(game, arguments: args);
  }
}
