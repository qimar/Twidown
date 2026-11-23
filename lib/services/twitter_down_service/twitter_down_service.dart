// lib/services/twitter_down_service/twitter_down_service.dart
import 'dart:convert';
import 'dart:io' show Directory, File;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

import 'package:videodownloader/models/video_meta_model/video_model.dart';
import 'package:videodownloader/models/video_downloaded_model/video_downloaded_model.dart';
import 'package:videodownloader/services/object_box/object_box_service.dart';
import 'package:videodownloader/service_locator.dart';

class TwitterDownService {
  WebViewController? _controller;

  static const bool showWebView = false;

  /// Initialize WebView
  Future initWebView() async {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(
          'Mozilla/5.0 (Linux; Android 14; Pixel 9 Pro) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Mobile Safari/537.36')
      ..setBackgroundColor(const Color(0x00000000))
      ..enableZoom(true)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) => debugPrint('Twitter WebView START → $url'),
          onPageFinished: (url) => debugPrint('Twitter WebView FINISH → $url'),
          onWebResourceError: (error) {
            debugPrint('WebView ERROR: ${error.description} | URL: ${error.url} | Code: ${error.errorCode}');
          },
        ),
      );


    try {
      await _controller?.loadRequest(Uri.parse('https://twittervideodownloader.com/en/'));
    } catch (e) {
      debugPrint('Failed to load initial WebView page: $e');
    }
  }

  Future<void> goHome() async {
    try {
      if (_controller == null) await initWebView();
      await _controller!.loadRequest(Uri.parse('https://twittervideodownloader.com/en/'));
    } catch (e) {
      debugPrint('TwitterDownService.goHome ERROR → $e');
    }
  }

  // Future<VideoMetaDataModel?> fetchVideoMetaData(
  //     String userUrl, BuildContext context) async {
  //   if (userUrl.isEmpty) return null;

  //   try {
  //     await _waitForForm();
  //     await _fillAndSubmit(userUrl);

  //     VideoMetaDataModel? meta;
  //     const attempts = 10;
  //     const delayMs = 800;

  //     for (int i = 0; i < attempts; i++) {
  //       meta = await _scrapeDownloadPage();
  //       if (meta != null && meta.videoLinks.isNotEmpty) break;
  //       await Future.delayed(Duration(milliseconds: delayMs));
  //     }

  //     if (meta == null || meta.videoLinks.isEmpty) {
  //       Fluttertoast.showToast(msg: 'No downloadable video found.');
  //       return null;
  //     }

  //       //     debugPrint('✅ [TwitterDownService] Metadata Successfully Fetched!');
  //     debugPrint('📌 Title: ${meta.title}');
  //     debugPrint('📌 Thumbnail: ${meta.thumbnail}');
  //     debugPrint('📌 Duration: ${meta.duration}');
  //     debugPrint('📌 Total Download Links Found: ${meta.videoLinks.length}');

  //     for (int i = 0; i < meta.videoLinks.length; i++) {
  //       final link = meta.videoLinks[i];
  //       debugPrint('   🔗 Link ${i+1}: ${link.quality} → ${link.link}');
  //     }
  //     
  //     debugPrint('[TwitterDownService] ✅ Metadata fetched successfully');

  //     // Reset to home
  //     WidgetsBinding.instance.addPostFrameCallback((_) async {
  //       await goHome();
  //     });

  //     return meta;
  //   } catch (e, st) {
  //     debugPrint('TwitterDownService error: $e');
  //     Fluttertoast.showToast(msg: 'Failed to process URL');
  //     return null;
  //   }
  // }

Future<VideoMetaDataModel?> fetchVideoMetaData(
    String userUrl, BuildContext context) async {
  if (userUrl.isEmpty) return null;

  // Try up to 2 times — second attempt gets a fresh CSRF token
  for (int attempt = 1; attempt <= 2; attempt++) {
    try {
      debugPrint('🔄 Fetch attempt $attempt...');
      
      if (attempt == 2) {
        // Fresh page load to get a new CSRF token
        debugPrint('♻️ Reloading home page for fresh CSRF token...');
        await goHome();
        await Future.delayed(const Duration(seconds: 2));
      }

      await _waitForForm();
      await _fillAndSubmit(userUrl);
      await _waitForResultsPage();

      VideoMetaDataModel? meta;
      const attempts = 15;
      const delayMs = 1000;

      for (int i = 0; i < attempts; i++) {
        meta = await _scrapeDownloadPage();
        if (meta != null && meta.videoLinks.isNotEmpty) break;
        debugPrint('⏳ Attempt ${i + 1}/$attempts — no links yet, waiting...');
        await Future.delayed(Duration(milliseconds: delayMs));
      }

      if (meta == null || meta.videoLinks.isEmpty) {
        if (attempt < 2) continue; // retry
        Fluttertoast.showToast(msg: 'No downloadable video found.');
        return null;
      }

      debugPrint('✅ Metadata fetched on attempt $attempt');
      debugPrint('📌 Total links: ${meta.videoLinks.length}');

      WidgetsBinding.instance.addPostFrameCallback((_) async {
        try {
          await _controller?.loadRequest(Uri.parse('about:blank'));
          debugPrint('[TwitterDownService] WebView cleared (loaded about:blank) to free memory.');
        } catch (e, st) {
          debugPrint('[TwitterDownService] Failed to clear WebView: $e\n$st');
        }
      });

      return meta;

    } catch (e) {
      debugPrint('❌ Attempt $attempt error: $e');
      if (attempt >= 2) {
        Fluttertoast.showToast(msg: 'Failed to process URL');
        return null;
      }
      // Continue to retry
    }
  }

  return null;
}
/// Waits until the WebView has navigated away from the home/submit page
/// and landed on a results page (URL contains /download or /en/ with results)
Future<void> _waitForResultsPage({int maxAttempts = 30}) async {
  debugPrint('⏳ Waiting for results page...');
  for (int i = 0; i < maxAttempts; i++) {
    await _controller!.currentUrl(); // poll to keep loop alive

    // Check if page has mp4 links OR has navigated away from home
    final hasMp4 = await _controller!.runJavaScriptReturningResult('''
      (function(){
        const hasMp4Links = document.body?.innerHTML?.includes('.mp4') || false;
        const has403 = document.title?.includes('403') || false;
        const hasResults = !!document.querySelector('.card-header');
        return JSON.stringify({hasMp4: hasMp4Links, has403: has403, hasResults: hasResults});
      })();
    ''');

    String checkStr = hasMp4.toString();
    if (checkStr.startsWith('"') && checkStr.endsWith('"')) {
      checkStr = checkStr.substring(1, checkStr.length - 1);
    }
    checkStr = checkStr.replaceAll(r'\"', '"');
    debugPrint('🔎 Page check $i: $checkStr');

    if (checkStr.contains('"hasMp4":true')) {
      debugPrint('✅ MP4 links found on page');
      return;
    }

    if (checkStr.contains('"has403":true')) {
      debugPrint('❌ Got 403 — CSRF issue detected, retrying...');
      // Try reloading the home page and resubmitting
      throw Exception('CSRF_ERROR');
    }

    await Future.delayed(const Duration(milliseconds: 500));
  }
  debugPrint('⚠️ Timed out waiting for results');
}

  Future<void> _waitForForm({int maxAttempts = 25}) async {
    for (int i = 0; i < maxAttempts; i++) {
      final ok = await _controller!.runJavaScriptReturningResult('''
        (function(){
          return !!document.querySelector('input[name="tweet"]') || 
                 !!document.querySelector('input[placeholder*="Tweet"]');
        })();
      ''');
      if (ok == true) return;
      await Future.delayed(const Duration(milliseconds: 400));
    }
    throw Exception('Twitter form not found');
  }

 Future<void> _fillAndSubmit(String url) async {
  final js = '''
    (function(){
      // Get CSRF token from the form hidden input
      const csrfInput = document.querySelector('input[name="csrfmiddlewaretoken"]');
      const csrfToken = csrfInput ? csrfInput.value : '';

      const input = document.querySelector('input[name="tweet"]') || 
                   document.querySelector('input[placeholder*="Tweet"]');
      
      if (!input) return JSON.stringify({ok: false, reason: 'no input'});
      if (!csrfToken) return JSON.stringify({ok: false, reason: 'no csrf'});

      // Set the value properly (triggers React/Vue reactivity if needed)
      const nativeInputValueSetter = Object.getOwnPropertyDescriptor(
        window.HTMLInputElement.prototype, 'value'
      ).set;
      nativeInputValueSetter.call(input, "${url.replaceAll('"', '\\"')}");
      input.dispatchEvent(new Event('input', { bubbles: true }));
      input.dispatchEvent(new Event('change', { bubbles: true }));

      // Submit via fetch with CSRF token instead of clicking the button
      // This is more reliable than button.click()
      const formData = new FormData();
      formData.append('csrfmiddlewaretoken', csrfToken);
      formData.append('tweet', "${url.replaceAll('"', '\\"')}");

      fetch('/download', {
        method: 'POST',
        headers: {
          'X-CSRFToken': csrfToken,
          'Referer': window.location.href,
        },
        body: formData,
        credentials: 'include',
      }).then(response => response.text()).then(html => {
        // Write the response HTML directly into the current page
        document.open();
        document.write(html);
        document.close();
      });

      return JSON.stringify({ok: true, csrf: csrfToken.substring(0, 8) + '...'});
    })();
  ''';

  final result = await _controller!.runJavaScriptReturningResult(js);
  debugPrint('📤 Submit result: $result');

  // Parse result to check for errors
  String resultStr = result.toString();
  if (resultStr.startsWith('"') && resultStr.endsWith('"')) {
    resultStr = resultStr.substring(1, resultStr.length - 1);
  }
  resultStr = resultStr.replaceAll(r'\"', '"');
  
  if (resultStr.contains('"ok":false')) {
    debugPrint('❌ Submit failed: $resultStr');
    throw Exception('Submit failed: $resultStr');
  }
  
  debugPrint('✅ Form submitted with CSRF token');
}

  // Future<VideoMetaDataModel?> _scrapeDownloadPage() async {
  //   try {
  //     final raw = await _controller!.runJavaScriptReturningResult('''
  //       (function(){
  //         let title = document.querySelector('.card-header')?.innerText.trim() || 'Twitter Video';
  //         let thumb = document.querySelector('img')?.src || '';

  //         const links = [];
  //         const anchors = document.querySelectorAll('a');

  //         for (let a of anchors) {
  //           const href = a.href || '';
  //           if (!href.includes('.mp4')) continue;

  //           let quality = a.getAttribute('data-filename') || a.textContent || 'Unknown';
            
  //           // Clean quality name - remove ": mp4"
  //           quality = quality.replace(': mp4', '').replace('.mp4', '').trim();

  //           links.push({
  //             href: href,
  //             quality: quality
  //           });
  //         }

  //         return JSON.stringify({
  //           title: title,
  //           thumb: thumb,
  //           duration: '',
  //           links: links
  //         });
  //       })();
  //     ''');

  //     String jsonString = raw.toString();
  //     if (jsonString.startsWith('"') && jsonString.endsWith('"')) {
  //       jsonString = jsonString.substring(1, jsonString.length - 1);
  //     }
  //     jsonString = jsonString.replaceAll(r'\"', '"');

  //     final Map<String, dynamic> data = jsonDecode(jsonString);
  //     final List<dynamic> linkList = data['links'] ?? [];

  //     List<VideoLinkModel> videoLinks = linkList
  //         .map((e) => VideoLinkModel(
  //               link: (e['href'] ?? '') as String,
  //               quality: (e['quality'] ?? 'Unknown') as String,
  //               type: 'mp4',
  //             ))
  //         .where((link) => link.link.isNotEmpty)
  //         .toList();

  //     // === SORT BY HIGHEST RESOLUTION FIRST ===
  //     videoLinks.sort((a, b) {
  //       int resA = _extractMaxResolution(a.quality);
  //       int resB = _extractMaxResolution(b.quality);
  //       return resB.compareTo(resA); // Descending order
  //     });

  //     // Debug prints
  //     debugPrint('✅ Scraped Title: ${data['title']}');
  //     debugPrint('✅ Found ${videoLinks.length} qualities (sorted highest first)');

  //     for (var link in videoLinks) {
  //       debugPrint('   🔗 ${link.quality} → ${link.link}');
  //     }

  //     return VideoMetaDataModel(
  //       title: data['title'] ?? 'Twitter Video',
  //       description: '',
  //       duration: data['duration'] ?? '',
  //       thumbnail: data['thumb'] ?? '',
  //       videoLinks: videoLinks,
  //       hasScrappingError: videoLinks.isEmpty,
  //     );
  //   } catch (e, st) {
  //     debugPrint('❌ Twitter scraping error: $e');
  //     return null;
  //   }
  // }

  Future<VideoMetaDataModel?> _scrapeDownloadPage() async {
  try {
    // TEMPORARY: dump full page HTML to see what's actually there
    final pageHtml = await _controller!.runJavaScriptReturningResult('''
      (function(){
        return JSON.stringify({
          url: window.location.href,
          title: document.title,
          bodyText: document.body?.innerText?.substring(0, 500) || 'NO BODY',
          allLinks: Array.from(document.querySelectorAll('a')).map(a => a.href).filter(h => h).slice(0, 20),
          allImages: Array.from(document.querySelectorAll('img')).map(i => i.src).slice(0, 5),
          hasMp4: document.body?.innerHTML?.includes('.mp4') || false,
          hasVideo: document.body?.innerHTML?.includes('video') || false,
          cardHeader: document.querySelector('.card-header')?.innerText || 'NOT FOUND',
          inputExists: !!document.querySelector('input[name="tweet"]'),
        });
      })();
    ''');

    String cleaned = pageHtml.toString();
    if (cleaned.startsWith('"') && cleaned.endsWith('"')) {
      cleaned = cleaned.substring(1, cleaned.length - 1);
    }
    cleaned = cleaned.replaceAll(r'\"', '"');
    
    debugPrint('🔍 PAGE DUMP: $cleaned');

    // Keep your original scraping logic below unchanged
    final raw = await _controller!.runJavaScriptReturningResult('''
      (function(){
        let title = document.querySelector('.card-header')?.innerText.trim() || 'Twitter Video';
        let thumb = document.querySelector('img')?.src || '';
        const links = [];
        const anchors = document.querySelectorAll('a');
        for (let a of anchors) {
          const href = a.href || '';
          if (!href.includes('.mp4')) continue;
          let quality = a.getAttribute('data-filename') || a.textContent || 'Unknown';
          quality = quality.replace(': mp4', '').replace('.mp4', '').trim();
          links.push({ href: href, quality: quality });
        }
        return JSON.stringify({ title: title, thumb: thumb, duration: '', links: links });
      })();
    ''');

    String jsonString = raw.toString();
    if (jsonString.startsWith('"') && jsonString.endsWith('"')) {
      jsonString = jsonString.substring(1, jsonString.length - 1);
    }
    jsonString = jsonString.replaceAll(r'\"', '"');

    final Map<String, dynamic> data = jsonDecode(jsonString);
    final List<dynamic> linkList = data['links'] ?? [];

    List<VideoLinkModel> videoLinks = linkList
        .map((e) => VideoLinkModel(
              link: (e['href'] ?? '') as String,
              quality: (e['quality'] ?? 'Unknown') as String,
              type: 'mp4',
            ))
        .where((link) => link.link.isNotEmpty)
        .toList();

    videoLinks.sort((a, b) {
      int resA = _extractMaxResolution(a.quality);
      int resB = _extractMaxResolution(b.quality);
      return resB.compareTo(resA);
    });

    debugPrint('✅ Scraped Title: ${data['title']}');
    debugPrint('✅ Found ${videoLinks.length} qualities (sorted highest first)');

    return VideoMetaDataModel(
      title: data['title'] ?? 'Twitter Video',
      description: '',
      duration: data['duration'] ?? '',
      thumbnail: data['thumb'] ?? '',
      videoLinks: videoLinks,
      hasScrappingError: videoLinks.isEmpty,
    );
  } catch (e) {
    debugPrint('❌ Twitter scraping error: $e');
    return null;
  }
}

  int _extractMaxResolution(String quality) {
    final numbers = RegExp(r'\d+').allMatches(quality).map((m) => int.parse(m.group(0)!)).toList();
    return numbers.isNotEmpty ? numbers.reduce((a, b) => a > b ? a : b) : 0;
  }

Future<void> downloadVideo({
  required VideoMetaDataModel meta,
  required int selectedLinkIndex,
  required String userUrl,
  required Function(double) onProgress,
  required Function(String) onComplete,
  required Function(String) onError,
}) async {
  final dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(minutes: 30),
    sendTimeout: const Duration(seconds: 30),
    followRedirects: true,
    maxRedirects: 10,
    persistentConnection: true,
    receiveDataWhenStatusError: true,
  ));

  try {
    final link = meta.videoLinks[selectedLinkIndex];
    final safeTitle = (meta.title ?? "Video")
        .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')
        .trim();
    final fileName = '${safeTitle}_${DateTime.now().millisecondsSinceEpoch}.mp4';

    // Permission handling (unchanged)
    int? androidSdkVersion;
    if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        final deviceInfo = DeviceInfoPlugin();
        final androidInfo = await deviceInfo.androidInfo;
        androidSdkVersion = androidInfo.version.sdkInt;
      } catch (e) {
        androidSdkVersion = 0;
      }
    }

    const android13SdkVersion = 33;
    
    if (androidSdkVersion != null && androidSdkVersion >= android13SdkVersion) {
      // Android 13+ - request VIDEO permission
      if (await Permission.videos.isDenied) {
        final status = await Permission.videos.request();
        if (!status.isGranted) {
          Fluttertoast.showToast(
            msg: "Video permission required",
            backgroundColor: Colors.red.shade700,
          );
          onError("Permission denied");
          return;
        }
      }
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      // Android <13 or non-Android platform - request STORAGE permission
      if (await Permission.storage.isDenied) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          Fluttertoast.showToast(
            msg: "Storage permission required",
            backgroundColor: Colors.red.shade700,
          );
          onError("Permission denied");
          return;
        }
      }
    }

    final dir = Directory('/storage/emulated/0/Download/TwiDown');
    if (!await dir.exists()) await dir.create(recursive: true);

    final filePath = '${dir.path}/$fileName';

    debugPrint("Downloading to: $filePath");
    debugPrint("Download URL: ${link.link}");

    DateTime? lastUpdateTime;
    double lastReportedProgress = 0.0;

    await dio.download(
      link.link,
      filePath,
      onReceiveProgress: (received, total) {
        if (total <= 0) return;
        final double progress = received / total;
        final DateTime now = DateTime.now();

        final bool progressChangedEnough = (progress - lastReportedProgress).abs() >= 0.01;
        final bool timePassed = lastUpdateTime == null || now.difference(lastUpdateTime!).inMilliseconds >= 500;

        if (progressChangedEnough || timePassed) {
          onProgress(progress);
          lastReportedProgress = progress;
          lastUpdateTime = now;
        }
      },
      options: Options(
        headers: {
          'User-Agent': 'Mozilla/5.0 (Linux; Android 14; Pixel 9 Pro) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Mobile Safari/537.36',
          'Referer': 'https://twitter.com/',
          'Origin': 'https://twitter.com',
          'Accept': 'video/mp4,video/*,*/*',
          'Accept-Language': 'en-US,en;q=0.9',
          'Sec-Fetch-Site': 'cross-site',
          'Sec-Fetch-Mode': 'no-cors',
          'Sec-Fetch-Dest': 'video',
          'Connection': 'keep-alive',
        },
      ),
    );

    final file = File(filePath);
    if (!await file.exists()) {
      onError("File not saved");
      return;
    }

    final sizeMB = (await file.length()) / (1024 * 1024);

    getIt<ObjectBox>().store.box<VideoDownloadedModel>().put(VideoDownloadedModel(
      title: meta.title ?? "Untitled Video",
      thumbnail: meta.thumbnail ?? "",
      videoSocialUrl: link.link,
      videoPath: filePath,
      videoType: "mp4",
      videoQuality: link.quality,
      videoFileSize: "${sizeMB.toStringAsFixed(2)} MB",
      videoDuration: meta.duration ?? "Unknown",
      videoDownloadedDate: DateTime.now(),
      originalUrl: userUrl,
    ));

    // Fluttertoast.showToast(
    //   msg: "✅ Saved to Downloads",
    //   toastLength: Toast.LENGTH_LONG,
    //   gravity: ToastGravity.BOTTOM,
    //   backgroundColor: Colors.green.shade600,
    //   textColor: Colors.white,
    // );

    onComplete(filePath);

  } catch (e, st) {
    debugPrint("Download error: $e\n$st");
    Fluttertoast.showToast(msg: "Download failed");
    onError(e.toString());
  }
}
}