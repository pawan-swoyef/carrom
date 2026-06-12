import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../game/profile/profile_controller.dart';
import '../../game/profile/player_profile.dart';
import '../../game/profile/rank.dart';
import '../../theme/app_colors.dart';

/// "Your Records" screen: a big rank badge, XP progress, lifetime stat tiles,
/// a smooth career-trajectory line chart, and a reset action. Bound to
/// [ProfileController]. Returns BODY only (HomeShell provides the Scaffold).
class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ProfileController>();
    final p = c.profile;
    final rank = c.rank;

    final isMax = rank.xpForTier == 0;
    final nextTierName = rank.tierIndex + 1 < kRankTiers.length
        ? kRankTiers[rank.tierIndex + 1].name.toUpperCase()
        : null;

    final caption = isMax
        ? 'MAX TIER REACHED'
        : '${rank.xpToNext} XP TO ${nextTierName ?? ''}';

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Header row.
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'YOUR RECORDS',
                    style: TextStyle(
                      color: AppColors.gold,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                _CoinPill(coins: p.coins),
              ],
            ),
            const SizedBox(height: 20),

            // 2. Rank badge.
            const Center(
              child: Icon(
                Icons.workspace_premium,
                color: AppColors.gold,
                size: 80,
              ),
            ),
            const SizedBox(height: 8),

            // 3. Rank name.
            Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  rank.name.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.gold,
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // 4. Progress block.
            Row(
              children: [
                const Text(
                  'PROGRESS',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const Spacer(),
                Text(
                  isMax ? 'MAX' : '${rank.xpIntoTier} / ${rank.xpForTier} XP',
                  style: const TextStyle(
                    color: AppColors.gold,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: rank.progress.clamp(0.0, 1.0),
                minHeight: 10,
                backgroundColor: AppColors.woodDark,
                color: AppColors.crimson,
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                caption,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 22),

            // 5. Stat tiles (2x2).
            _StatGrid(profile: p),
            const SizedBox(height: 22),

            // 6. Career Trajectory.
            _TrajectoryPanel(history: p.history),
            const SizedBox(height: 24),

            // 7. Reset button.
            const _ResetButton(),
          ],
        ),
      ),
    );
  }
}

class _CoinPill extends StatelessWidget {
  const _CoinPill({required this.coins});

  final int coins;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, color: AppColors.gold, size: 16),
          const SizedBox(width: 6),
          Text(
            '$coins',
            style: const TextStyle(
              color: AppColors.gold,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
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
        label: 'WINS',
        value: '${profile.wins}',
        valueColor: AppColors.gold,
      ),
      _StatTile(
        label: 'LOSSES',
        value: '${profile.losses}',
        valueColor: AppColors.textLight,
      ),
      _StatTile(
        label: 'EFFICIENCY %',
        value: '${(profile.efficiency * 100).toStringAsFixed(1)}%',
        valueColor: AppColors.gold,
      ),
      _StatTile(
        label: 'BEST STREAK',
        value: '${profile.bestStreak} Wins',
        valueColor: AppColors.gold,
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
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.woodGrain),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                color: valueColor,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrajectoryPanel extends StatelessWidget {
  const _TrajectoryPanel({required this.history});

  final List<int> history;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.woodGrain),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(Icons.trending_up, color: AppColors.gold, size: 18),
              SizedBox(width: 8),
              Text(
                'CAREER TRAJECTORY',
                style: TextStyle(
                  color: AppColors.gold,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 150,
            child: history.isEmpty
                ? const Center(
                    child: Text(
                      'Play matches to see your trajectory',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                  )
                : CustomPaint(
                    size: Size.infinite,
                    painter: _TrajectoryPainter(values: history),
                  ),
          ),
          const SizedBox(height: 10),
          const Row(
            children: [
              Text(
                'MARCH 2023',
                style: TextStyle(color: AppColors.textMuted, fontSize: 11),
              ),
              Spacer(),
              Text(
                'TODAY',
                style: TextStyle(color: AppColors.textMuted, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Paints a smooth (cubic-bezier) gold line through [values] with a gold→
/// transparent gradient fill under the curve.
class _TrajectoryPainter extends CustomPainter {
  _TrajectoryPainter({required this.values});

  final List<int> values;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty || size.width <= 0 || size.height <= 0) return;

    const padTop = 8.0;
    const padBottom = 8.0;
    final chartHeight = size.height - padTop - padBottom;

    final minV = values.reduce((a, b) => a < b ? a : b).toDouble();
    final maxV = values.reduce((a, b) => a > b ? a : b).toDouble();
    final span = maxV - minV;

    // Map each value to a point. For <2 points or a flat series, draw a
    // gentle flat line through the middle of the chart.
    final points = <Offset>[];
    final n = values.length;
    for (var i = 0; i < n; i++) {
      final x = n == 1 ? size.width / 2 : size.width * i / (n - 1);
      final double y;
      if (span == 0 || n < 2) {
        y = padTop + chartHeight / 2;
      } else {
        final t = (values[i] - minV) / span; // 0..1
        y = padTop + chartHeight * (1 - t); // invert
      }
      points.add(Offset(x, y));
    }

    // Build the smooth line path using Catmull-Rom -> cubic bezier control
    // points (offset by ~1/6 of the neighbouring gap).
    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    if (points.length == 1) {
      linePath.lineTo(size.width, points.first.dy);
    } else {
      for (var i = 0; i < points.length - 1; i++) {
        final p0 = i > 0 ? points[i - 1] : points[i];
        final p1 = points[i];
        final p2 = points[i + 1];
        final p3 = i + 2 < points.length ? points[i + 2] : points[i + 1];

        final c1 = Offset(
          p1.dx + (p2.dx - p0.dx) / 6,
          p1.dy + (p2.dy - p0.dy) / 6,
        );
        final c2 = Offset(
          p2.dx - (p3.dx - p1.dx) / 6,
          p2.dy - (p3.dy - p1.dy) / 6,
        );
        linePath.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p2.dx, p2.dy);
      }
    }

    // Fill under the curve with a vertical gold gradient.
    final fillPath = Path.from(linePath)
      ..lineTo(points.last.dx, size.height)
      ..lineTo(points.first.dx, size.height)
      ..close();

    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.gold.withValues(alpha: 0.35),
          AppColors.gold.withValues(alpha: 0.0),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawPath(fillPath, fillPaint);

    // Stroke the curve.
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = AppColors.gold
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(linePath, linePaint);

    // Gold dots at the first and last data points.
    final dotPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = AppColors.gold;
    canvas.drawCircle(points.first, 3.5, dotPaint);
    if (points.length > 1) {
      canvas.drawCircle(points.last, 3.5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _TrajectoryPainter old) =>
      !_listEquals(old.values, values);

  static bool _listEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

class _ResetButton extends StatelessWidget {
  const _ResetButton();

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: () => _confirmReset(context),
      icon: const Icon(Icons.delete_outline),
      label: const Text(
        'Reset Records',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.crimson,
        foregroundColor: AppColors.textLight,
        padding: const EdgeInsets.symmetric(vertical: 14),
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
