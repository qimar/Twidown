import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get_it/get_it.dart';
import 'package:videodownloader/models/video_meta_model/video_model.dart';
import 'package:videodownloader/providers/ad_provider/ads_provider.dart';
import 'package:videodownloader/providers/downloaded_video_list_provider/downloaded_video_list_provider.dart';
import 'package:videodownloader/services/twitter_down_service/twitter_down_service.dart';

// Fetching metadata states
enum FetchingState { idle, fetching, fetched, errorFetching }

// Downloadingt states
enum DownloadingState { idle, downloading, completed, errorDownloading }

enum DownloadStatus { idle, downloading, success, error }

class HomeAndDownloadProvider extends ChangeNotifier {
  TwitterDownService get _downloadService => GetIt.I<TwitterDownService>();
  final DownloadedVideoListProvider _downloadsProvider;
   final AdProvider _adProvider;
  String _url = '';
  VideoMetaDataModel? videoMetaDataModel;
  HomeAndDownloadProvider(this._downloadsProvider, this._adProvider);
  FetchingState fetchingState = FetchingState.idle;
  DownloadStatus downloadStatus = DownloadStatus.idle;
  double downloadProgress = 0.0;
  String? errorMessage;
  bool _isDownloading = false;
  bool get isDownloading => _isDownloading;

  void startDownload() {
    _isDownloading = true;
    downloadProgress = 0.0;
    downloadStatus = DownloadStatus.downloading;
    errorMessage = null;
    notifyListeners();
  }

  void finishDownload() {
    _isDownloading = false;
    downloadProgress = 1.0;
    downloadStatus = DownloadStatus.success;
    notifyListeners();
  }

  void failDownload(String error) {
    _isDownloading = false;
    downloadProgress = 0.0;
    downloadStatus = DownloadStatus.error;
    errorMessage = error;
    notifyListeners();
  }

  String get url => _url;
  set url(String value) {
    _url = value;
    notifyListeners();
  }

  int _selectedLinkIndex = 0;
  int get selectedLinkIndex => _selectedLinkIndex;
  set selectedLinkIndex(int value) {
    _selectedLinkIndex = value;
    notifyListeners();
  }

  /// Fetch metadata for a provided URL.
  Future<VideoMetaDataModel?> fetchVideoMetaData({
    required BuildContext context,
    required String url,
  }) async {
    fetchingState = FetchingState.fetching;
    errorMessage = null;
    videoMetaDataModel = null; // ← ADD THIS: clear stale data immediately
    notifyListeners();
    try {
      // Ensure the webview is on home page
      // _downloadService.ensureWebViewOnHomePage(context);
      // Call the TwitterDownService and pass the real context.
      final meta = await _downloadService.fetchVideoMetaData(url, context);

      if (meta != null) {
        videoMetaDataModel = meta;
        fetchingState = FetchingState.fetched;
      } else {
        fetchingState = FetchingState.errorFetching;
        errorMessage = 'Failed to fetch video metadata';
      }
    } catch (e) {
      fetchingState = FetchingState.errorFetching;
      errorMessage = 'Error: $e';
      Fluttertoast.showToast(msg: errorMessage!);
    }

    notifyListeners();
    return videoMetaDataModel;
  }

  // Future<void> downloadVideo({
  //   required String userUrl,
  //   required int selectedLinkIndex,
  //   required BuildContext context, // ← ADD CONTEXT HERE
  // }) async {
  //   if (videoMetaDataModel == null) return;

  //   await _downloadService.downloadVideo(
  //     meta: videoMetaDataModel!,
  //     selectedLinkIndex: selectedLinkIndex,
  //     userUrl: userUrl,
  //     onProgress: (progress) {
  //       downloadProgress = progress;
  //       notifyListeners();
  //     },
  //     onComplete: (filePath) async {
  //       downloadProgress = 1.0;
  //       notifyListeners();

  //       // SUCCESS → SHOW INTERSTITIAL AFTER EVERY 3RD DOWNLOAD
  //       final prefs = await SharedPreferences.getInstance();
  //       int totalDownloads = (prefs.getInt('total_downloads') ?? 0) + 1;
  //       await prefs.setInt('total_downloads', totalDownloads);

  //       if (totalDownloads % 3 == 0) {
  //         final adProvider = Provider.of<AdProvider>(context, listen: false);
  //         adProvider.showInterstitialAd(
  //           onAdShowedFullScreen: (ad) {},
  //           onAdDismissedFullScreen: (ad) {},
  //           onAdFailedToShowFullScreen: (ad, error) {},
  //         );
  //       }
  //     },
  //     onError: (error) {
  //       errorMessage = error;
  //       Fluttertoast.showToast(msg: 'Download failed: $error');
  //       notifyListeners();
  //     },
  //   );
  // }

  Future<void> downloadVideo({
    required String userUrl,
    required int selectedLinkIndex,
    required BuildContext context,
  }) async {
    if (videoMetaDataModel == null || isDownloading) return;

    startDownload();

    await _downloadService.downloadVideo(
      meta: videoMetaDataModel!,
      selectedLinkIndex: selectedLinkIndex,
      userUrl: userUrl,
      onProgress: (progress) {
        downloadProgress = progress;
        notifyListeners();
      },
      onComplete: (filePath) async {
  finishDownload();

  // Placement 3: every 2 successful downloads
  if (_adProvider.shouldShowAdOnSuccessfulDownload()) {
    _adProvider.tryShowAd(
      onDismissed: () {
        Fluttertoast.showToast(
          msg: "Download completed!",
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
      },
    );
  } else {
    // No ad this time — show toast immediately
    Fluttertoast.showToast(
      msg: "Download completed!",
      backgroundColor: Colors.green,
      textColor: Colors.white,
    );
  }

  _downloadsProvider.onNewVideoDownloaded();
},
      onError: (error) {
        failDownload(error);
      },
    );
  }


  // GUARANTEED INTERSTITIAL AD AFTER EVERY DOWNLOAD
  // final adProvider = Provider.of<AdProvider>(context, listen: false);
  // if (adProvider.isInterstitialAvailable && adProvider.loadedInterstitialAd) {
  //   adProvider.showInterstitialAd(
  //     onAdShowedFullScreen: (_) {},
  //     onAdDismissedFullScreen: (_) {},
  //     onAdFailedToShowFullScreen: (_, error) {
  //       debugPrint('Interstitial failed to show: $error');
  //     },
  //   );
  // } else {
  //   debugPrint('Interstitial not available — skipping');
  // }

  void reset() {
    _url = '';
    videoMetaDataModel = null;
    fetchingState = FetchingState.idle;
    downloadProgress = 0.0;
    downloadStatus = DownloadStatus.idle;
    errorMessage = null;
    notifyListeners();
  }
}
