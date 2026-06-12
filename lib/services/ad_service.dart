import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'ad_ids.dart';

/// Global, crash-safe ads facade. All methods no-op until [init] succeeds, so it
/// is safe to call from anywhere (incl. tests, where it is never initialised).
class AdService {
  AdService._();
  static final AdService instance = AdService._();

  bool _ready = false;
  InterstitialAd? _interstitial;
  int _matchesSinceAd = 0;

  Future<void> init() async {
    try {
      await MobileAds.instance.initialize();
      _ready = true;
      _loadInterstitial();
    } catch (_) {
      _ready = false;
    }
  }

  void _loadInterstitial() {
    if (!_ready) return;
    try {
      InterstitialAd.load(
        adUnitId: AdIds.interstitial,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) => _interstitial = ad,
          onAdFailedToLoad: (_) => _interstitial = null,
        ),
      );
    } catch (_) {}
  }

  /// Shows an interstitial roughly every other finished match, if one is ready.
  void maybeShowInterstitial() {
    _matchesSinceAd++;
    final ad = _interstitial;
    if (ad == null || _matchesSinceAd < 2) return;
    _matchesSinceAd = 0;
    _interstitial = null;
    try {
      ad.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (a) {
          a.dispose();
          _loadInterstitial();
        },
        onAdFailedToShowFullScreenContent: (a, _) {
          a.dispose();
          _loadInterstitial();
        },
      );
      ad.show();
    } catch (_) {
      _loadInterstitial();
    }
  }
}
