import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../game/strikers/striker_controller.dart';
import '../../game/strikers/striker_skin.dart';
import '../../theme/app_colors.dart';

/// Strikers screen: gallery of OWNED striker skins where the player equips one.
/// Returns the BODY only — HomeShell provides the Scaffold + bottom nav.
class StrikersTab extends StatelessWidget {
  const StrikersTab({super.key});

  @override
  Widget build(BuildContext context) {
    final strikers = context.watch<StrikerController>();
    final owned = kStrikerCatalog.where((s) => strikers.isOwned(s.id)).toList();

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'MY STRIKERS',
              style: TextStyle(
                color: AppColors.gold,
                fontSize: 26,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            if (owned.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Text(
                    'No strikers owned yet.',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 15),
                  ),
                ),
              )
            else
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.85,
                children: [
                  for (final skin in owned)
                    _OwnedStrikerCard(skin: skin, strikers: strikers),
                ],
              ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.storefront_outlined,
                    color: AppColors.textMuted, size: 16),
                SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Get more strikers in the Shop',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OwnedStrikerCard extends StatelessWidget {
  const _OwnedStrikerCard({required this.skin, required this.strikers});

  final StrikerSkin skin;
  final StrikerController strikers;

  @override
  Widget build(BuildContext context) {
    final equipped = strikers.isEquipped(skin.id);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: equipped ? AppColors.gold : AppColors.woodGrain,
          width: equipped ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Center(child: _StrikerPreview(skin: skin)),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              skin.name,
              maxLines: 1,
              style: const TextStyle(
                color: AppColors.textLight,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (equipped)
            ElevatedButton(
              onPressed: null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                disabledBackgroundColor: AppColors.gold,
                disabledForegroundColor: AppColors.woodDark,
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'EQUIPPED',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            )
          else
            OutlinedButton(
              onPressed: () => strikers.equip(skin.id),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.crimson,
                side: const BorderSide(color: AppColors.gold),
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'EQUIP',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StrikerPreview extends StatelessWidget {
  const _StrikerPreview({required this.skin});

  final StrikerSkin skin;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Color(skin.fill),
        border: Border.all(color: Color(skin.ring), width: 4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Color(skin.accent),
          ),
        ),
      ),
    );
  }
}
