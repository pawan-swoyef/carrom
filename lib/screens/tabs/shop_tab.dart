import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../game/profile/profile_controller.dart';
import '../../game/strikers/striker_controller.dart';
import '../../game/strikers/striker_skin.dart';
import '../../theme/app_colors.dart';

/// Shop screen: browse, buy and equip striker skins. Bound to
/// [StrikerController] (ownership/equip) and [ProfileController] (coins).
/// Returns the BODY only — HomeShell provides the Scaffold + bottom nav.
class ShopTab extends StatelessWidget {
  const ShopTab({super.key});

  @override
  Widget build(BuildContext context) {
    final strikers = context.watch<StrikerController>();
    final coins = context.watch<ProfileController>().profile.coins;
    final catalog =
        kStrikerCatalog.where((s) => s.id != kDefaultStrikerId).toList();

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _HeaderRow(coins: coins),
            const SizedBox(height: 16),
            const _FeaturedBanner(),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Flexible(
                  child: Text(
                    'ELITE STRIKERS',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.gold,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  'See All',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.72,
              children: [
                for (final skin in catalog)
                  _StrikerCard(skin: skin, strikers: strikers),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({required this.coins});

  final int coins;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'SHOP',
          style: TextStyle(
            color: AppColors.gold,
            fontSize: 26,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star, color: AppColors.gold, size: 18),
              const SizedBox(width: 6),
              Text(
                '$coins',
                style: const TextStyle(
                  color: AppColors.textLight,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FeaturedBanner extends StatelessWidget {
  const _FeaturedBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.crimsonDark, AppColors.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.gold,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'FEATURED',
              style: TextStyle(
                color: AppColors.woodDark,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Ivory Collection',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.textLight,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Premium Striker Pack · Limited Edition',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.crimson,
              foregroundColor: AppColors.textLight,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'View Pack',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class _StrikerCard extends StatelessWidget {
  const _StrikerCard({required this.skin, required this.strikers});

  final StrikerSkin skin;
  final StrikerController strikers;

  @override
  Widget build(BuildContext context) {
    final owned = strikers.isOwned(skin.id);
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
          Expanded(child: Center(child: _StrikerPreview(skin: skin))),
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
          if (owned)
            _OwnedFooter(skin: skin, strikers: strikers, equipped: equipped)
          else
            _BuyFooter(skin: skin, strikers: strikers),
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

class _OwnedFooter extends StatelessWidget {
  const _OwnedFooter({
    required this.skin,
    required this.strikers,
    required this.equipped,
  });

  final StrikerSkin skin;
  final StrikerController strikers;
  final bool equipped;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check, color: AppColors.gold, size: 14),
              SizedBox(width: 4),
              Text(
                'OWNED',
                style: TextStyle(
                  color: AppColors.gold,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
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
              foregroundColor: AppColors.gold,
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
    );
  }
}

class _BuyFooter extends StatelessWidget {
  const _BuyFooter({required this.skin, required this.strikers});

  final StrikerSkin skin;
  final StrikerController strikers;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star, color: AppColors.gold, size: 14),
              const SizedBox(width: 4),
              Text(
                '${skin.price}',
                style: const TextStyle(
                  color: AppColors.textLight,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        ElevatedButton(
          onPressed: () async {
            final ok = await strikers.buy(skin);
            if (!ok && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Not enough coins')),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.crimson,
            foregroundColor: AppColors.textLight,
            padding: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'BUY',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
