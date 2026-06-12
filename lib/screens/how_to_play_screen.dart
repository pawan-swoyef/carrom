import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Static rules / tutorial screen: numbered sections explaining the goal, the
/// Queen, and the controls, plus a "Start Match" button that pops back.
class HowToPlayScreen extends StatelessWidget {
  const HowToPlayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.woodDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.pinkHeading),
        title: const Text(
          'How to Play',
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
            const _Section(
              number: 1,
              title: 'The Goal',
              child: _BodyText(
                'Be the first to pocket all of your assigned coins (Black or '
                'White) into the four corner pockets.',
              ),
            ),
            const SizedBox(height: 18),
            const _Section(
              number: 2,
              title: 'The Queen',
              child: _BodyText(
                'The red Queen is worth bonus points. After pocketing the Queen '
                'you MUST cover it by pocketing one of your own coins on the '
                'same or the very next strike — otherwise it returns to the '
                'board.',
              ),
            ),
            const SizedBox(height: 18),
            const _Section(
              number: 3,
              title: 'Controls',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ControlLine(
                    label: 'Aim',
                    text: 'Drag the striker to aim; a guide line shows the '
                        'shot direction.',
                  ),
                  SizedBox(height: 12),
                  _ControlLine(
                    label: 'Power',
                    text: 'Pull back; the further you pull, the stronger the '
                        'strike.',
                  ),
                  SizedBox(height: 12),
                  _ControlLine(
                    label: 'Release',
                    text: 'Lift your finger to launch.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: () => Navigator.of(context).maybePop(),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.crimson,
                foregroundColor: AppColors.textLight,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Start Match',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.number,
    required this.title,
    required this.child,
  });

  final int number;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.gold,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$number',
                style: const TextStyle(
                  color: AppColors.woodDark,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.gold,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.crimsonDark),
          ),
          child: child,
        ),
      ],
    );
  }
}

class _BodyText extends StatelessWidget {
  const _BodyText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textLight,
        fontSize: 14,
        height: 1.4,
      ),
    );
  }
}

class _ControlLine extends StatelessWidget {
  const _ControlLine({required this.label, required this.text});

  final String label;
  final String text;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: '$label — ',
            style: const TextStyle(
              color: AppColors.gold,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          TextSpan(
            text: text,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
