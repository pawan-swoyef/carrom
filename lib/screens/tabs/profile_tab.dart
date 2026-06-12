import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../game/profile/profile_controller.dart';
import '../../game/profile/player_profile.dart';
import '../../game/profile/rank.dart';
import '../../theme/app_colors.dart';

/// "Your Records" screen: rank, XP progress, lifetime stats, a career
/// trajectory bar chart, and a reset action. Bound to [ProfileController].
class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ProfileController>();
    final p = c.profile;
    final rank = c.rank;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Your Records',
              style: TextStyle(
                color: AppColors.pinkHeading,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _RankCard(rank: rank),
            const SizedBox(height: 16),
            _StatGrid(profile: p),
            const SizedBox(height: 20),
            const Text(
              'Career Trajectory',
              style: TextStyle(
                color: AppColors.gold,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _TrajectoryChart(history: p.history),
            const SizedBox(height: 24),
            _ResetButton(),
          ],
        ),
      ),
    );
  }
}

class _RankCard extends StatelessWidget {
  const _RankCard({required this.rank});

  final RankInfo rank;

  @override
  Widget build(BuildContext context) {
    final caption = rank.xpForTier == 0
        ? 'Max tier'
        : '${rank.xpIntoTier} / ${rank.xpForTier} XP to next tier';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.crimsonDark.withValues(alpha: 0.45),
                  border: Border.all(color: AppColors.gold, width: 2),
                ),
                child: const Icon(
                  Icons.military_tech,
                  color: AppColors.crimson,
                  size: 30,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Rank: ${rank.name}',
                  style: const TextStyle(
                    color: AppColors.gold,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: rank.progress.clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor: AppColors.woodDark,
              valueColor: const AlwaysStoppedAnimation(AppColors.gold),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            caption,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.profile});

  final PlayerProfile profile;

  @override
  Widget build(BuildContext context) {
    final tiles = <Widget>[
      _StatTile(
        label: 'Wins',
        value: '${profile.wins}',
        icon: Icons.emoji_events,
      ),
      _StatTile(
        label: 'Losses',
        value: '${profile.losses}',
        icon: Icons.close,
      ),
      _StatTile(
        label: 'Performance Efficiency',
        value: '${(profile.efficiency * 100).round()}%',
        icon: Icons.speed,
      ),
      _StatTile(
        label: 'Best Streak',
        value: '${profile.bestStreak} Games',
        icon: Icons.local_fire_department,
      ),
    ];

    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: tiles[0]),
              const SizedBox(width: 12),
              Expanded(child: tiles[1]),
            ],
          ),
        ),
        const SizedBox(height: 12),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: tiles[2]),
              const SizedBox(width: 12),
              Expanded(child: tiles[3]),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.woodGrain),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.gold, size: 22),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.textLight,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _TrajectoryChart extends StatelessWidget {
  const _TrajectoryChart({required this.history});

  final List<int> history;

  @override
  Widget build(BuildContext context) {
    const chartHeight = 120.0;
    final maxValue = history.isEmpty
        ? 0
        : history.reduce((a, b) => a > b ? a : b);

    if (history.isEmpty || maxValue <= 0) {
      return Container(
        height: chartHeight,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.woodGrain),
        ),
        child: const Text(
          'Play a match to see your trajectory',
          style: TextStyle(color: AppColors.textMuted, fontSize: 13),
        ),
      );
    }

    // Highlight the most recent few bars in gold, older ones muted.
    const recentCount = 4;
    final firstRecent = history.length - recentCount;

    return Container(
      height: chartHeight,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.woodGrain),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < history.length; i++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: FractionallySizedBox(
                  alignment: Alignment.bottomCenter,
                  heightFactor: (history[i] / maxValue).clamp(0.04, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: i >= firstRecent
                          ? AppColors.gold
                          : AppColors.textMuted.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ResetButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => _confirmReset(context),
      icon: const Icon(Icons.restart_alt, color: AppColors.crimson),
      label: const Text(
        'Reset Records',
        style: TextStyle(
          color: AppColors.crimson,
          fontWeight: FontWeight.bold,
        ),
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        side: const BorderSide(color: AppColors.crimson),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context) async {
    final controller = context.read<ProfileController>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Reset all records?',
          style: TextStyle(color: AppColors.textLight),
        ),
        content: const Text(
          'This clears your coins, XP, wins, losses and streaks. '
          'This cannot be undone.',
          style: TextStyle(color: AppColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Reset',
              style: TextStyle(color: AppColors.crimson),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await controller.reset();
    }
  }
}
