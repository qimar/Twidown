class AppConstants {
  // show test or production ads
  static const bool showTestAds = false;
  

  static const String supportEmail = String.fromEnvironment(
    'SUPPORT_EMAIL',
    defaultValue: 'support@twidown.app',
  );

  static const String feedbackMessageString =
      "mailto:$supportEmail?subject=Feedback&body=Write your feedback here";

  // // app share text
  static const String appShareText =
      "I am using this TwiDown app. Download it from here: ";

  // // google play store url
  static const String googlePlayStoreUrl =
      "https://play.google.com/store/apps/details?id=com.example.twidown";

  // // apple itunes store url
  static const String appleItunesStoreUrl =
      "https://apps.apple.com/us/app/twidown/id1581234567";

  // // app share with app icon image and text
  // static const String appShareSubject = "Sleeply App";

  // interstitial ad showing intervale delay in seconds
  static const int interstitialAdShowingInterval = 108;
}
