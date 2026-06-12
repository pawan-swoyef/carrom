import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../settings/settings_controller.dart';
import '../settings/difficulty.dart';
import '../game/profile/profile_controller.dart';

/// App settings: audio/haptics toggles, default difficulty, reset stats, and
/// an about footer. Bound to [SettingsController] and [ProfileController].
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final s = settings.settings;

    return Scaffold(
      backgroundColor: AppColors.woodDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.pinkHeading),
        title: const Text(
          'Settings',
          style: TextStyle(
            color: AppColors.pinkHeading,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const _SectionLabel('AUDIO & HAPTICS'),
            const SizedBox(height: 8),
            _Card(
              child: Column(
                children: [
                  _SettingSwitch(
                    icon: Icons.volume_up,
                    title: 'Sound Effects',
                    value: s.soundEffects,
                    onChanged: (v) =>
                        context.read<SettingsController>().setSoundEffects(v),
                  ),
                  _SettingSwitch(
                    icon: Icons.music_note,
                    title: 'Music',
                    value: s.music,
                    onChanged: (v) =>
                        context.read<SettingsController>().setMusic(v),
                  ),
                  _SettingSwitch(
                    icon: Icons.vibration,
                    title: 'Vibration',
                    value: s.vibration,
                    onChanged: (v) =>
                        context.read<SettingsController>().setVibration(v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            const _SectionLabel('GAMEPLAY'),
            const SizedBox(height: 8),
            _Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Default Difficulty',
                      style: TextStyle(
                        color: AppColors.textLight,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _DifficultySelector(
                      value: s.defaultDifficulty,
                      onChanged: (d) => context
                          .read<SettingsController>()
                          .setDefaultDifficulty(d),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: () => _confirmReset(context),
              icon: const Icon(Icons.delete_outline),
              label: const Text(
                'Reset All Stats',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.crimson,
                foregroundColor: AppColors.textLight,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: GestureDetector(
                onTap: () {},
                child: const Text(
                  'Terms of Service & Privacy Policy',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    decoration: TextDecoration.underline,
                    decorationColor: AppColors.textMuted,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _Card(
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 18),
                child: Column(
                  children: [
                    Text(
                      'Carrom Pro v1.0.0',
                      style: TextStyle(
                        color: AppColors.gold,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'The Professional Circuit',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context) async {
    final controller = context.read<ProfileController>();
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Reset all stats?',
          style: TextStyle(color: AppColors.textLight),
        ),
        content: const Text(
          'Reset all stats? This cannot be undone.',
          style: TextStyle(color: AppColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
          TextButton(
            onPressed: () async {
              await controller.reset();
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            child: const Text(
              'Reset',
              style: TextStyle(color: AppColors.crimson),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textMuted,
        letterSpacing: 2,
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.crimsonDark),
      ),
      child: child,
    );
  }
}

class _SettingSwitch extends StatelessWidget {
  const _SettingSwitch({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      activeThumbColor: AppColors.gold,
      activeTrackColor: AppColors.gold,
      secondary: Icon(icon, color: AppColors.gold),
      title: Text(
        title,
        style: const TextStyle(color: AppColors.textLight),
      ),
    );
  }
}

class _DifficultySelector extends StatelessWidget {
  const _DifficultySelector({required this.value, required this.onChanged});

  final Difficulty value;
  final ValueChanged<Difficulty> onChanged;

  @override
  Widget build(BuildContext context) {
    const options = <(Difficulty, String)>[
      (Difficulty.easy, 'Easy'),
      (Difficulty.medium, 'Med'),
      (Difficulty.hard, 'Hard'),
    ];

    return Row(
      children: [
        for (var i = 0; i < options.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(
            child: _Chip(
              label: options[i].$2,
              selected: value == options[i].$1,
              onTap: () => onChanged(options[i].$1),
            ),
          ),
        ],
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.crimson : AppColors.woodDark,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? AppColors.crimson : AppColors.crimsonDark,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? AppColors.pinkHeading : AppColors.textMuted,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
