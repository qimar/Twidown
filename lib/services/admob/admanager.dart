import 'package:videodownloader/core/utils/app_constants.dart';

class AdManager {
  // Official Google Sample AdMob Test IDs
  static const String testAppId = 'ca-app-pub-3940256099942544~3347511713';
  static const String testBannerId = 'ca-app-pub-3940256099942544/6300978111';
  static const String testInterstitialId = 'ca-app-pub-3940256099942544/1033173712';
  static const String testRewardId = 'ca-app-pub-3940256099942544/5224354917';
  static const String testNativeId = 'ca-app-pub-3940256099942544/2247696110';

  static String get appId => AppConstants.showTestAds
      ? testAppId
      : const String.fromEnvironment('ADMOB_APP_ID', defaultValue: testAppId);

  static String get bannerIdAndroid => AppConstants.showTestAds
      ? testBannerId
      : const String.fromEnvironment('ADMOB_BANNER_ID', defaultValue: testBannerId);

  static String get interstitialIdAndroid => AppConstants.showTestAds
      ? testInterstitialId
      : const String.fromEnvironment('ADMOB_INTERSTITIAL_ID', defaultValue: testInterstitialId);

  static String get rewardIdAndroid => AppConstants.showTestAds
      ? testRewardId
      : const String.fromEnvironment('ADMOB_REWARD_ID', defaultValue: testRewardId);

  static String get nativeIdAndroid => AppConstants.showTestAds
      ? testNativeId
      : const String.fromEnvironment('ADMOB_NATIVE_ID', defaultValue: testNativeId);

  // Test IDs for iOS
  static String bannerIdiOS = testBannerId;
  static String interstitialIdiOS = testInterstitialId;
  static String interstitialRewardedIdiOS = 'ca-app-pub-3940256099942544/6978759866';
  static String rewardIdiOS = testRewardId;
  static String nativeIdiOS = testNativeId;
}
