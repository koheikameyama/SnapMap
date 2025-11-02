import 'dart:io';
import 'dart:async';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  // シングルトンパターン
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  // AdMobを初期化
  static Future<void> initialize() async {
    await MobileAds.instance.initialize();
  }

  // バナー広告のユニットID（本番用）
  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-7558679080857597/5128439299'; // 本番用バナー広告ID
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  // インタースティシャル広告のユニットID
  static String get interstitialAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-7558679080857597/2031502660'; // 本番用インタースティシャル広告ID
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  // バナー広告を作成
  BannerAd createBannerAd() {
    return BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          // 広告ロード成功
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      ),
    );
  }

  // インタースティシャル広告をロード
  Future<InterstitialAd?> loadInterstitialAd() async {
    final Completer<InterstitialAd?> completer = Completer<InterstitialAd?>();

    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          if (!completer.isCompleted) {
            completer.complete(ad);
          }
        },
        onAdFailedToLoad: (error) {
          if (!completer.isCompleted) {
            completer.complete(null);
          }
        },
      ),
    );

    // コールバックが呼ばれるまで待つ（最大10秒）
    final interstitialAd = await completer.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        return null;
      },
    );

    return interstitialAd;
  }

  // インタースティシャル広告を表示
  Future<void> showInterstitialAd(InterstitialAd? ad) async {
    if (ad == null) {
      return;
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        // 広告が表示された
      },
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
      },
    );

    await ad.show();
  }
}
