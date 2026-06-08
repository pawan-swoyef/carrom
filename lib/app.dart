import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'navigation/app_routes.dart';

class CarromProApp extends StatelessWidget {
  const CarromProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Carrom Pro',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      onGenerateRoute: AppRoutes.onGenerateRoute,
      home: const SplashScreen(),
    );
  }
}
