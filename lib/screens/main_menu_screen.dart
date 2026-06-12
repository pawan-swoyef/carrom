import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../settings/settings_controller.dart';
import '../game/profile/profile_controller.dart';
import '../navigation/home_shell.dart';
import 'settings_screen.dart';
import 'how_to_play_screen.dart';
import 'tabs/profile_tab.dart';

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  void _openPlay(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const HomeShell(initialIndex: 0)),
    );
  }

  void _openHowToPlay(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const HowToPlayScreen()),
    );
  }

  void _openSettings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
  }

  void _openStats(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Stats')),
          backgroundColor: AppColors.woodDark,
          body: const ProfileTab(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final profile = context.watch<ProfileController>().profile;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _MenuBackground(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Spacer(),
                      _SoundButton(
                        on: settings.settings.soundEffects,
                        onTap: () => settings
                            .setSoundEffects(!settings.settings.soundEffects),
                      ),
                    ],
                  ),
                  const _Title(),
                  const SizedBox(height: 8),
                  const Text(
                    'THE PROFESSIONAL CIRCUIT',
                    style: TextStyle(
                      color: AppColors.pinkHeading,
                      letterSpacing: 4,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(flex: 3),
                  _PlayButton(onTap: () => _openPlay(context)),
                  const Spacer(flex: 2),
                  Row(
                    children: [
                      Expanded(
                        child: _MenuPill(
                          icon: Icons.menu_book,
                          label: 'How to Play',
                          onTap: () => _openHowToPlay(context),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _MenuPill(
                          icon: Icons.bar_chart,
                          label: 'Stats',
                          onTap: () => _openStats(context),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _MenuPill(
                          icon: Icons.settings,
                          label: 'Settings',
                          onTap: () => _openSettings(context),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(flex: 2),
                  _StatsBar(coins: profile.coins, level: profile.level),
                  const SizedBox(height: 12),
                  const _SponsoredBanner(),
                  const SizedBox(height: 12),
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
  const _Title();

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
          fontSize: 40,
          fontWeight: FontWeight.w800,
          letterSpacing: 2,
        ),
      ),
    );
  }
}

class _SoundButton extends StatelessWidget {
  final bool on;
  final VoidCallback onTap;
  const _SoundButton({required this.on, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 28,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.6),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.crimsonDark),
        ),
        child: Icon(on ? Icons.volume_up : Icons.volume_off,
            color: AppColors.gold, size: 24),
      ),
    );
  }
}

class _PlayButton extends StatelessWidget {
  final VoidCallback onTap;
  const _PlayButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 300,
        height: 300,
        child: CustomPaint(
          painter: _RingsPainter(),
          child: Center(
            child: Container(
              width: 210,
              height: 210,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  center: Alignment(-0.2, -0.3),
                  radius: 0.9,
                  colors: [Color(0xFFB83A52), Color(0xFF8A2138)],
                ),
                border: Border.all(color: AppColors.goldBright, width: 3),
                boxShadow: const [
                  BoxShadow(
                      color: Color(0x66000000), blurRadius: 24, spreadRadius: 2),
                ],
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.play_arrow_rounded, size: 72, color: Colors.white),
                  Text(
                    'PLAY',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RingsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final radii = [150.0, 138.0, 124.0];
    final alphas = [0.10, 0.16, 0.24];
    for (var i = 0; i < radii.length; i++) {
      paint.color = AppColors.gold.withValues(alpha: alphas[i]);
      canvas.drawCircle(c, radii[i], paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MenuPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _MenuPill(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.crimsonDark),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: AppColors.gold, size: 18),
                const SizedBox(width: 6),
                Text(label,
                    style: const TextStyle(
                        color: AppColors.textLight,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatsBar extends StatelessWidget {
  final int coins;
  final int level;
  const _StatsBar({required this.coins, required this.level});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.crimsonDark),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, color: AppColors.gold, size: 18),
          const SizedBox(width: 8),
          Text('$coins COINS',
              style: const TextStyle(
                  color: AppColors.textLight,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1)),
          Container(
            width: 1,
            height: 18,
            margin: const EdgeInsets.symmetric(horizontal: 18),
            color: AppColors.crimsonDark,
          ),
          const Icon(Icons.military_tech, color: AppColors.gold, size: 18),
          const SizedBox(width: 8),
          Text('LVL $level',
              style: const TextStyle(
                  color: AppColors.textLight,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1)),
        ],
      ),
    );
  }
}

class _SponsoredBanner extends StatelessWidget {
  const _SponsoredBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: const Column(
        children: [
          Text('SPONSORED CIRCUIT',
              style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w600)),
          SizedBox(height: 4),
          Text('WATCH TO UNLOCK EXCLUSIVE STRIKERS',
              style: TextStyle(
                  color: AppColors.textMuted, fontSize: 12, letterSpacing: 1)),
        ],
      ),
    );
  }
}

class _MenuBackground extends StatelessWidget {
  const _MenuBackground();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.8),
          radius: 1.1,
          colors: [Color(0xFF2A1518), Color(0xFF120D0A), Color(0xFF0D0908)],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
    );
  }
}
