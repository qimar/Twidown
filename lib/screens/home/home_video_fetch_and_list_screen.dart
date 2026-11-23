import 'package:listen_sharing_intent/listen_sharing_intent.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'package:videodownloader/core/utils/helper.dart';
import 'package:videodownloader/providers/home_download_provider/home_download_provider.dart';
import 'package:videodownloader/screens/home/video_download_meta_bottom_sheet.dart';
import 'package:videodownloader/services/twitter_down_service/twitter_down_service.dart';

class HomeVideoFetchAndListScreen extends StatefulWidget {
  const HomeVideoFetchAndListScreen({super.key});

  @override
  State<HomeVideoFetchAndListScreen> createState() =>
      _HomeVideoFetchAndListScreenState();
}

class _HomeVideoFetchAndListScreenState
    extends State<HomeVideoFetchAndListScreen>
    with WidgetsBindingObserver {
  late HomeAndDownloadProvider _homeAndDownloadProvider;
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _homeAndDownloadProvider = Provider.of<HomeAndDownloadProvider>(
        context,
        listen: false,
      );

      // Initialize WebView for debugging
      final twitterService = TwitterDownService();
      await twitterService.initWebView();

      _checkClipboardForTwitterUrl();
      _initShareListener();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkClipboardForTwitterUrl();
    }
  }

  void _initShareListener() {
    ReceiveSharingIntent.instance.getMediaStream().listen((
      List<SharedMediaFile> sharedFiles,
    ) {
      if (sharedFiles.isNotEmpty) {
        for (var file in sharedFiles) {
          if (file.type == SharedMediaType.text && file.path.isNotEmpty) {
            _handleSharedUrl(file.path);
            break;
          }
        }
      }
    }, onError: (err) => debugPrint("Error in getMediaStream: $err"));

    ReceiveSharingIntent.instance
        .getInitialMedia()
        .then((List<SharedMediaFile> sharedFiles) {
          if (sharedFiles.isNotEmpty) {
            for (var file in sharedFiles) {
              if (file.type == SharedMediaType.text && file.path.isNotEmpty) {
                _handleSharedUrl(file.path);
                break;
              }
            }
          }
        })
        .catchError((Object err) { debugPrint("Error in getInitialMedia: $err"); return null; });
  }

  Future<void> _handleSharedUrl(String sharedText) async {
    final cleanUrl = SocialUrlUtilities.getTwitterUrl(sharedText);

    _controller.text = cleanUrl;
    _homeAndDownloadProvider.url = cleanUrl;

    _showLoadingDialog(context);

    try {
      final videoModel = await _homeAndDownloadProvider.fetchVideoMetaData(
        context: context,
        url: cleanUrl,
      );

      _dismissLoadingDialog();

      if (videoModel != null && videoModel.videoLinks.isNotEmpty) {
        bottomVideoMetaBottomSheet(
          context: context,
          // sheetHeight: 70.0.h,
          userUrl: cleanUrl,
        );
      } else {
        Fluttertoast.showToast(msg: 'No downloadable video found');
      }
    } catch (e) {
      _dismissLoadingDialog();
      Fluttertoast.showToast(msg: 'Error: $e');
    }
  }

  Future<void> _checkClipboardForTwitterUrl() async {
    try {
      final clipboardData = await Clipboard.getData('text/plain');
      final clipboardText = clipboardData?.text?.trim() ?? '';

      if (clipboardText.isEmpty) return;

      if (SocialUrlUtilities.isValidTwitterUrl(clipboardText)) {
        final twitterUrl = SocialUrlUtilities.getTwitterUrl(clipboardText);

        if (_controller.text.isEmpty) {
          _controller.text = twitterUrl;
          _homeAndDownloadProvider.url = twitterUrl;
          setState(() {});

          Fluttertoast.showToast(
            msg: 'Twitter link pasted automatically',
            toastLength: Toast.LENGTH_SHORT,
          );
        }
      }
    } catch (e) {
      debugPrint('Clipboard check failed: $e');
    }
  }

  void _onDynamicButtonPressed() async {
    final url = _controller.text.trim();

    if (url.isEmpty) {
      final clipboardData = await Clipboard.getData('text/plain');
      if (clipboardData?.text?.trim().isNotEmpty == true) {
        final pasted = clipboardData!.text!.trim();
        final cleanUrl = SocialUrlUtilities.getTwitterUrl(pasted);

        _controller.text = cleanUrl;
        _homeAndDownloadProvider.url = cleanUrl;
        setState(() {});
      } else {
        Fluttertoast.showToast(msg: 'No link found in clipboard');
      }
    } else {
      final cleanUrl = SocialUrlUtilities.getTwitterUrl(url);

      _showLoadingDialog(context);

      try {
        final videoModel = await _homeAndDownloadProvider.fetchVideoMetaData(
          context: context,
          url: cleanUrl,
        );

        _dismissLoadingDialog();

        if (videoModel != null && videoModel.videoLinks.isNotEmpty) {
          bottomVideoMetaBottomSheet(context: context, userUrl: cleanUrl);
        } else {
          Fluttertoast.showToast(msg: 'No downloadable video found');
        }
      } catch (e) {
        _dismissLoadingDialog();
        Fluttertoast.showToast(msg: 'Error fetching metadata: $e');
      }
    }
  }

  void _showLoadingDialog(
    BuildContext context, {
    String message = "Fetching Twitter video...\nPlease wait...",
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (_) => Center(
        child: Container(
          width: 60.w,
          padding: EdgeInsets.symmetric(vertical: 3.h, horizontal: 3.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                strokeWidth: 3,
                color: Color(0xFF3B82F6),
              ),
              SizedBox(height: 2.h),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _dismissLoadingDialog() {
    if (Navigator.canPop(context)) Navigator.pop(context);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool hasUrl = _controller.text.trim().isNotEmpty;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.h),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // URL Input Field
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _controller,
                      onChanged: (value) {
                        if (value.isNotEmpty) {
                          final normalized = SocialUrlUtilities.getTwitterUrl(
                            value,
                          );
                          _homeAndDownloadProvider.url = normalized;
                          _controller.text = normalized;
                        }
                        setState(() {});
                      },
                      cursorColor: Colors.black,
                      style: const TextStyle(fontSize: 15),
                      decoration: const InputDecoration(
                        hintText: 'Paste Twitter / X link',
                        hintStyle: TextStyle(color: Colors.black45),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.5.h),

            // Dynamic Button
            SizedBox(
              width: double.infinity,
              height: 6.h,
              child: GestureDetector(
                onTap: _onDynamicButtonPressed,
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: hasUrl
                        ? const Color(0xFF3B82F6)
                        : const Color(0xFFE9E7FC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    hasUrl ? 'Download' : 'Paste Link',
                    style: TextStyle(
                      color: hasUrl ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(height: 43.h),

            if (TwitterDownService.showWebView)
              Container(
                height: 45.h,
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(8),
                ),
                // child: TwitterDownService().debugWebView,
              ),

            SizedBox(height: 2.h),

            // How to Download Section
            const Divider(height: 12, endIndent: 50.0, indent: 50.0),
            const Text(
              "How to Download",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 1.h),

            _buildStep(1, "Open X and copy link of a video"),
            _buildStep(2, "Open TwiDown and Press Paste to Paste the link"),
            _buildStep(3, "Press Download and Choose the quality"),
            _buildStep(4, "The download will start automatically. Done!"),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(int number, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF3B82F6), width: 2),
            ),
            child: Text(
              number.toString(),
              style: const TextStyle(
                color: Color(0xFF3B82F6),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14.5,
                color: Colors.black87,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
