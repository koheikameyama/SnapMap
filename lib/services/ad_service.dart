import 'dart:io';
import 'dart:developer' as developer;
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

  // インタースティシャル広告のユニットID（本番用）
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
          developer.log('バナー広告のロードに失敗', error: error, name: 'AdService');
          ad.dispose();
        },
      ),
    );
  }

  // インタースティシャル広告をロード
  Future<InterstitialAd?> loadInterstitialAd() async {
    InterstitialAd? interstitialAd;

    await InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          interstitialAd = ad;
        },
        onAdFailedToLoad: (error) {
          developer.log('インタースティシャル広告のロードに失敗', error: error, name: 'AdService');
        },
      ),
    );

    // 広告がロードされるまで少し待つ
    await Future.delayed(const Duration(seconds: 1));
    return interstitialAd;
  }

  // インタースティシャル広告を表示
  Future<void> showInterstitialAd(InterstitialAd? ad) async {
    if (ad == null) {
      return;
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        // 広告表示成功
      },
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        developer.log('インタースティシャル広告の表示に失敗', error: error, name: 'AdService');
        ad.dispose();
      },
    );

    await ad.show();
  }
}
