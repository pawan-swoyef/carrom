import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'main_menu_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _arc =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
        ..repeat();

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1900), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainMenuScreen()),
      );
    });
  }

  @override
  void dispose() {
    _arc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Wood-grain background.
          const CustomPaint(painter: _WoodGrainPainter()),
          // Warm vignette glow behind the emblem.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.05),
                radius: 0.55,
                colors: [Color(0x334A2A1A), Color(0x00000000)],
              ),
            ),
          ),
          SafeArea(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOut,
              builder: (_, t, child) => Opacity(opacity: t, child: child),
              child: Column(
                children: [
                  const Spacer(flex: 22),
                  _Title(),
                  const SizedBox(height: 12),
                  const Text(
                    'ELITE TOURNAMENT SERIES',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 4,
                    ),
                  ),
                  const Spacer(flex: 16),
                  const _Emblem(size: 150),
                  const Spacer(flex: 18),
                  SizedBox(
                    width: 46,
                    height: 46,
                    child: AnimatedBuilder(
                      animation: _arc,
                      builder: (_, _) => Transform.rotate(
                        angle: _arc.value * 2 * math.pi,
                        child: const CustomPaint(painter: _ArcPainter()),
                      ),
                    ),
                  ),
                  const Spacer(flex: 14),
                  const Text(
                    'V1.0.0',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Title extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (rect) => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [AppColors.goldBright, AppColors.gold, Color(0xFFB8923E)],
      ).createShader(rect),
      child: const Text(
        'CARROM PRO',
        style: TextStyle(
          color: Colors.white,
          fontSize: 46,
          fontStyle: FontStyle.italic,
          fontWeight: FontWeight.w600,
          letterSpacing: 2,
        ),
      ),
    );
  }
}

/// The crimson + gold striker emblem. Reusable as a brand mark / accent.
class _Emblem extends StatelessWidget {
  final double size;
  const _Emblem({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Color(0x66000000), blurRadius: 24, spreadRadius: 2),
        ],
      ),
      child: const CustomPaint(painter: _EmblemPainter()),
    );
  }
}

class _EmblemPainter extends CustomPainter {
  const _EmblemPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;

    // Gold rim base.
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.goldBright, Color(0xFFB8923E)],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );

    // Crimson disc.
    final rimWidth = r * 0.10;
    final discR = r - rimWidth;
    canvas.drawCircle(
      c,
      discR,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xFF9E2A40), Color(0xFF5C1626)],
        ).createShader(Rect.fromCircle(center: c, radius: discR)),
    );

    // Concentric gold rings.
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..color = AppColors.gold.withValues(alpha: 0.85)
      ..strokeWidth = r * 0.025;
    canvas.drawCircle(c, discR * 0.80, ring);
    canvas.drawCircle(c, discR * 0.52, ring);

    // Center target: gold ring + filled dot.
    canvas.drawCircle(
      c,
      discR * 0.22,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = AppColors.goldBright
        ..strokeWidth = r * 0.05,
    );
    canvas.drawCircle(c, discR * 0.09, Paint()..color = AppColors.goldBright);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ArcPainter extends CustomPainter {
  const _ArcPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3
      ..color = AppColors.gold;
    // A ~80° arc.
    canvas.drawArc(rect.deflate(3), -math.pi * 0.7, math.pi * 0.45, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _WoodGrainPainter extends CustomPainter {
  const _WoodGrainPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // Base vertical gradient (dark wood).
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1C1510), Color(0xFF0E0A07), Color(0xFF171109)],
          stops: [0.0, 0.55, 1.0],
        ).createShader(rect),
    );

    // Faint vertical grain lines (deterministic).
    final grain = Paint()..strokeWidth = 1;
    for (var i = 0; i < 60; i++) {
      final x = (i / 60) * size.width + (i % 3) * 2.0;
      final opacity = 0.04 + (i % 5) * 0.012;
      grain.color = Colors.black.withValues(alpha: opacity);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grain);
    }

    // A few brighter plank seams.
    final seam = Paint()
      ..strokeWidth = 1.5
      ..color = Colors.white.withValues(alpha: 0.025);
    for (var i = 1; i < 6; i++) {
      final x = size.width * (i / 6);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), seam);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
